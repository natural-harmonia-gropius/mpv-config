import { Octokit } from "@octokit/rest";
import { Buffer } from "node:buffer";
import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { dirname, resolve as resolvePath } from "node:path";

// ═══════════════════════════════════════════════════════════════════════════════
// Types — atomic building blocks composed via intersection
// ═══════════════════════════════════════════════════════════════════════════════

/** A single source → destination file mapping. */
type PathMapping = {
  source: string;
  destination: string;
};

/**
 * Identifies a GitHub repository and an optional git ref.
 * `ref` doubles as a source-type discriminator:
 *   `"releases"` — latest GitHub Release asset
 *   `"gists"`   — GitHub Gist (then `repo` holds the gist ID)
 *   `undefined` — repository default branch
 */
type RepoRef = {
  owner: string;
  repo: string;
  ref?: string;
};

/** One entry in sources.json: a repo plus the paths to pull from it. */
type SourceEntry = RepoRef & {
  paths: PathMapping[];
};

/** A single file resolution ready for download. */
type UpdateItem = RepoRef & PathMapping;

// ═══════════════════════════════════════════════════════════════════════════════
// Constants
// ═══════════════════════════════════════════════════════════════════════════════

const DIRECTORY_MARKER = "/";
const GIST_TIMEOUT_MS = 30_000;
const REPO_ROOT = resolvePath(import.meta.dirname, "../..");
const SOURCES_PATH = resolvePath(REPO_ROOT, "portable_config/sources.json");

// ═══════════════════════════════════════════════════════════════════════════════
// Runtime validation
// ═══════════════════════════════════════════════════════════════════════════════

function assertString(value: unknown, path: string): asserts value is string {
  if (typeof value !== "string") {
    throw new TypeError(`${path}: expected string, got ${typeof value}`);
  }
}

function assertPlainObject(
  value: unknown,
  path: string,
): asserts value is Record<string, unknown> {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    throw new TypeError(`${path}: expected plain object`);
  }
}

/** Parse and validate sources.json with clear error messages. */
function parseSourcesJson(json: string): SourceEntry[] {
  let raw: unknown;
  try {
    raw = JSON.parse(json);
  } catch (cause) {
    throw new Error("sources.json: invalid JSON", { cause });
  }

  assertPlainObject(raw, "(root)");

  if (!Array.isArray(raw.sources)) {
    throw new TypeError(
      'sources.json: expected "sources" array at the top level',
    );
  }

  return raw.sources.map(validateEntry);
}

function validateEntry(entry: unknown, index: number): SourceEntry {
  assertPlainObject(entry, `[${index}]`);
  assertString(entry.owner, `[${index}].owner`);
  assertString(entry.repo, `[${index}].repo`);

  let ref: string | undefined;
  if ("ref" in entry && entry.ref != null) {
    assertString(entry.ref, `[${index}].ref`);
    if (entry.ref.length > 0) ref = entry.ref;
  }

  if (!Array.isArray(entry.paths)) {
    throw new TypeError(`[${index}].paths: expected array`);
  }

  const paths = entry.paths.map((p, pi) => validatePathMapping(p, index, pi));

  // exactOptionalPropertyTypes: only attach ref when it's a non-empty string
  const result: SourceEntry = { owner: entry.owner, repo: entry.repo, paths };
  if (ref !== undefined) result.ref = ref;
  return result;
}

function validatePathMapping(
  path: unknown,
  entryIndex: number,
  pathIndex: number,
): PathMapping {
  assertPlainObject(path, `[${entryIndex}].paths[${pathIndex}]`);
  assertString(path.source, `[${entryIndex}].paths[${pathIndex}].source`);
  assertString(
    path.destination,
    `[${entryIndex}].paths[${pathIndex}].destination`,
  );
  return { source: path.source, destination: path.destination };
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helpers
// ═══════════════════════════════════════════════════════════════════════════════

function normalizePath(path: string): string {
  return path.replace(/^\/+|\/+$/g, "");
}

/**
 * Build an UpdateItem without ever setting `ref: undefined`,
 * which `exactOptionalPropertyTypes` forbids in object literals.
 */
function toUpdateItem(repo: RepoRef, mapping: PathMapping): UpdateItem {
  const item: UpdateItem = {
    owner: repo.owner,
    repo: repo.repo,
    source: mapping.source,
    destination: mapping.destination,
  };
  if (repo.ref !== undefined) item.ref = repo.ref;
  return item;
}

function isDirectoryMapping(source: string, destination: string): boolean {
  return (
    source.endsWith(DIRECTORY_MARKER) && destination.endsWith(DIRECTORY_MARKER)
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// GitHub API
// ═══════════════════════════════════════════════════════════════════════════════

function createOctokit(): Octokit {
  const token = process.env.GITHUB_TOKEN;
  return new Octokit(token ? { auth: token } : {});
}

/**
 * Fetch a single file from a GitHub repository via the Contents API.
 * Falls back to the Git Blobs API when the file is larger than 1 MB
 * (GitHub omits `content` for those files).
 */
async function fetchRepoFile(
  octokit: Octokit,
  owner: string,
  repo: string,
  ref: string | undefined,
  path: string,
): Promise<Buffer> {
  const { data } = await octokit.rest.repos.getContent({
    owner,
    repo,
    path: normalizePath(path),
    ...(ref ? { ref } : {}),
  });

  if (Array.isArray(data)) {
    throw new Error(`"${path}" is a directory, expected a file`);
  }

  // GitHub returns base64-encoded content for files ≤ 1 MB.
  // For larger files, `content` is absent and we must use the Blobs API.
  if (data.type === "file" && data.content && data.encoding === "base64") {
    return Buffer.from(data.content, "base64");
  }

  const { data: blob } = await octokit.rest.git.getBlob({
    owner,
    repo,
    file_sha: data.sha,
  });

  return Buffer.from(blob.content, blob.encoding as BufferEncoding);
}

/** Download a named asset from the latest GitHub Release. */
async function fetchReleaseAsset(
  octokit: Octokit,
  owner: string,
  repo: string,
  assetName: string,
): Promise<Buffer> {
  const {
    data: { assets },
  } = await octokit.rest.repos.getLatestRelease({ owner, repo });

  const asset = assets.find((candidate) => candidate.name === assetName);

  if (!asset) {
    throw new Error(
      `Asset "${assetName}" not found in latest release of ${owner}/${repo}`,
    );
  }

  const response = await fetch(asset.browser_download_url, {
    headers: {
      Accept: "application/octet-stream",
    },
  });

  if (!response.ok) {
    throw new Error(
      `Failed to download "${assetName}" from ${owner}/${repo}: ` +
        `${response.status} ${response.statusText}`,
    );
  }

  return Buffer.from(await response.arrayBuffer());
}

/** Download a file from a GitHub Gist. */
async function fetchGistFile(
  owner: string,
  gistId: string,
  fileName: string,
): Promise<Buffer> {
  const url = new URL(
    `${encodeURIComponent(owner)}/${encodeURIComponent(gistId)}/raw/${encodeURIComponent(fileName)}`,
    "https://gist.githubusercontent.com/",
  );

  const response = await fetch(url, {
    headers: {
      Accept: "application/octet-stream",
    },
    signal: AbortSignal.timeout(GIST_TIMEOUT_MS),
  });

  if (!response.ok) {
    throw new Error(
      `Failed to download Gist "${fileName}" from ${owner}/${gistId}: ` +
        `${response.status} ${response.statusText}`,
    );
  }

  return Buffer.from(await response.arrayBuffer());
}

// ═══════════════════════════════════════════════════════════════════════════════
// Directory recursion
// ═══════════════════════════════════════════════════════════════════════════════

/** Recursively list every file under a remote repository directory. */
async function* iterateDirectory(
  octokit: Octokit,
  owner: string,
  repo: string,
  ref: string | undefined,
  source: string,
  destination: string,
): AsyncGenerator<PathMapping> {
  const { data: content } = await octokit.rest.repos.getContent({
    owner,
    repo,
    path: normalizePath(source),
    ...(ref ? { ref } : {}),
  });

  if (!Array.isArray(content)) {
    throw new Error(`"${source}" is not a directory`);
  }

  for (const item of content) {
    const itemSource = `${source}${item.name}`;
    const itemDest = `${destination}${item.name}`;

    if (item.type === "file") {
      yield { source: itemSource, destination: itemDest };
    } else if (item.type === "dir") {
      yield* iterateDirectory(
        octokit,
        owner,
        repo,
        ref,
        `${itemSource}${DIRECTORY_MARKER}`,
        `${itemDest}${DIRECTORY_MARKER}`,
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Core orchestration
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * Yield every (source → destination) file pair defined in sources.json.
 * Directory mappings (trailing `/`) are expanded recursively.
 */
async function* iterateUpdates(
  octokit: Octokit,
  sourcesPath: string,
): AsyncGenerator<UpdateItem> {
  const text = await readFile(sourcesPath, "utf-8");
  const entries = parseSourcesJson(text);

  for (const entry of entries) {
    for (const mapping of entry.paths) {
      if (isDirectoryMapping(mapping.source, mapping.destination)) {
        // Remove stale files before re-populating the directory
        await rm(mapping.destination, { recursive: true, force: true });

        for await (const item of iterateDirectory(
          octokit,
          entry.owner,
          entry.repo,
          entry.ref,
          mapping.source,
          mapping.destination,
        )) {
          yield toUpdateItem(entry, item);
        }
      } else {
        yield toUpdateItem(entry, mapping);
      }
    }
  }
}

/** Dispatch to the correct fetch strategy based on the ref discriminator. */
async function fetchFile(octokit: Octokit, item: UpdateItem): Promise<Buffer> {
  switch (item.ref) {
    case "gists":
      return fetchGistFile(item.owner, item.repo, item.source);
    case "releases":
      return fetchReleaseAsset(octokit, item.owner, item.repo, item.source);
    default:
      return fetchRepoFile(
        octokit,
        item.owner,
        item.repo,
        item.ref,
        item.source,
      );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Entry point
// ═══════════════════════════════════════════════════════════════════════════════

async function main(): Promise<void> {
  const octokit = createOctokit();

  for await (const item of iterateUpdates(octokit, SOURCES_PATH)) {
    const buffer = await fetchFile(octokit, item);
    await mkdir(dirname(item.destination), { recursive: true });
    await writeFile(item.destination, buffer);
  }
}

main().catch((error): void => {
  console.error("Update failed:", error);
  process.exitCode = 1;
});
