import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { dirname } from "node:path";
import { Octokit } from "@octokit/rest";

const token = process.env.GITHUB_TOKEN;

const octokit = new Octokit({
  ...(token ? { auth: token } : {}),
  userAgent: "mpv-config-updater",
});

async function main() {
  async function handleRepo(owner, repo, ref, path) {
    const { data } = await octokit.rest.repos.getContent({
      owner,
      repo,
      path: path.replace(/^\/+|\/+$/g, ""),
      ...(ref ? { ref } : {}),
    });

    if (Array.isArray(data)) {
      throw new Error("Path is a directory, not a file.");
    }

    const { content, encoding, sha } = data;

    if (content && encoding === "base64") {
      return Buffer.from(content, "base64");
    }

    const { data: blob } = await octokit.rest.git.getBlob({
      owner,
      repo,
      file_sha: sha,
    });
    return Buffer.from(blob.content, blob.encoding);
  }

  async function handleRelease(owner, repo, assetName) {
    const {
      data: { assets },
    } = await octokit.rest.repos.getLatestRelease({ owner, repo });

    const asset = assets.find((candidate) => candidate.name === assetName);

    if (!asset) {
      throw new Error(`Asset "${assetName}" not found in latest release`);
    }

    const response = await fetch(asset.browser_download_url, {
      headers: {
        Accept: "application/octet-stream",
        "User-Agent": "mpv-config-updater",
      },
    });

    if (!response.ok) {
      throw new Error(
        `Failed to download asset "${assetName}": ${response.status} ${response.statusText}`,
      );
    }

    return Buffer.from(await response.arrayBuffer());
  }

  async function handleGist(owner, gistId, fileName) {
    const url = new URL(
      `${encodeURIComponent(owner)}/${encodeURIComponent(gistId)}/raw/` +
        encodeURIComponent(fileName),
      "https://gist.githubusercontent.com/",
    );
    const response = await fetch(url, {
      headers: {
        Accept: "application/octet-stream",
        "User-Agent": "mpv-config-updater",
      },
      signal: AbortSignal.timeout(30_000),
    });

    if (!response.ok) {
      throw new Error(
        `Failed to download Gist file "${fileName}": ${response.status} ${response.statusText}`,
      );
    }

    return Buffer.from(await response.arrayBuffer());
  }

  async function* dirIter(owner, repo, ref, source, destination) {
    const { data: content } = await octokit.rest.repos.getContent({
      owner,
      repo,
      path: source.replace(/^\/+|\/+$/g, ""),
      ...(ref ? { ref } : {}),
    });

    if (!Array.isArray(content)) {
      throw new Error(`Path "${source}" is not a directory.`);
    }

    for (const { type, name } of content) {
      if (type === "file") {
        yield {
          newSource: `${source}${name}`,
          newDestination: `${destination}${name}`,
        };
      } else if (type === "dir") {
        for await (const { newSource, newDestination } of dirIter(
          owner,
          repo,
          ref,
          `${source}${name}/`,
          `${destination}${name}/`,
        )) {
          yield { newSource, newDestination };
        }
      }
    }
  }

  async function* updateIter(json = "sources.json") {
    const text = await readFile(json, "utf-8");
    const data = JSON.parse(text);

    for (const { owner, repo, ref, paths } of data) {
      for (const { source, destination } of paths) {
        if (source.endsWith("/") && destination.endsWith("/")) {
          await rm(destination, { recursive: true, force: true });
          for await (const { newSource, newDestination } of dirIter(
            owner,
            repo,
            ref,
            source,
            destination,
          )) {
            yield {
              owner,
              repo,
              ref,
              source: newSource,
              destination: newDestination,
            };
          }
        } else {
          yield {
            owner,
            repo,
            ref,
            source,
            destination,
          };
        }
      }
    }
  }

  for await (const { owner, repo, ref, source, destination } of updateIter(
    "portable_config/sources.json",
  )) {
    let buffer;

    if (ref === "gists") {
      buffer = await handleGist(owner, repo, source);
    } else if (ref === "releases") {
      buffer = await handleRelease(owner, repo, source);
    } else {
      buffer = await handleRepo(owner, repo, ref, source);
    }

    await mkdir(dirname(destination), { recursive: true });
    await writeFile(destination, buffer);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
