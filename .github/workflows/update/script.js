const { createWriteStream } = require("fs");
const { mkdir, readFile } = require("fs/promises");
const { dirname } = require("path");
const { Readable } = require("stream");
const { pipeline } = require("stream/promises");

module.exports = async ({ github, context, core, glob, io, exec, require }) => {
  async function handleRepo(owner, repo, ref, path) {
    const { data } = await github.rest.repos.getContent({
      owner,
      repo,
      path,
      ref,
    });

    if (Array.isArray(data)) {
      throw new Error("Path is a directory, not a file.");
    }

    const { content, encoding, sha } = data;

    if (content && encoding === "base64") {
      return Buffer.from(content, "base64");
    }

    const blob = await github.rest.git.getBlob({ owner, repo, file_sha: sha });
    return Buffer.from(blob.data.content, blob.data.encoding);
  }

  async function handleRelease(owner, repo, assetName) {
    const {
      data: { assets },
    } = await github.rest.repos.getLatestRelease({
      owner,
      repo,
    });

    const asset = assets.find((asset) => asset.name === assetName);

    if (!asset) {
      throw new Error(`Asset "${assetName}" not found in latest release`);
    }

    const response = await fetch(asset.url, {
      headers: {
        Accept: "application/octet-stream",
        "User-Agent": "octokit-rest",
      },
    });

    if (!response.ok) {
      throw new Error(
        `Failed to download asset "${assetName}": ${response.status} ${response.statusText}`
      );
    }

    return Buffer.from(await response.arrayBuffer());
  }

  async function handleGist(owner, gistId, fileName) {
    const res = await github.rest.gists.get({ gist_id: gistId });

    const files = res.data.files;
    const file = files[fileName];

    if (!file) {
      throw new Error(`File "${fileName}" not found in gist ${gistId}`);
    }

    return Buffer.from(file.content, "utf-8");

    // const response = await fetch(
    //   `https://gist.githubusercontent.com/${owner}/${gist_id}/raw/${fileName}`
    // );
    // return response.body;
  }

  async function* dirIter(owner, repo, ref, source, destination) {
    const content = await github.rest.repos.getContent({
      owner,
      repo,
      path: source.replace(/^\/+|\/+$/g, ""),
      ref,
    });
    for (const { type, name } of content.data) {
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
          `${destination}${name}/`
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
          await io.rmRF(destination);
          for await (const { newSource, newDestination } of dirIter(
            owner,
            repo,
            ref,
            source,
            destination
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
    "portable_config/sources.json"
  )) {
    let buffer = null;
    if (ref === "gists") {
      buffer = await handleGist(owner, repo, source);
    } else if (ref === "releases") {
      buffer = await handleRelease(owner, repo, source);
    } else {
      buffer = await handleRepo(owner, repo, ref, source);
    }
    await mkdir(dirname(destination), { recursive: true });
    await pipeline(Readable.from(buffer), createWriteStream(destination));
  }
};
