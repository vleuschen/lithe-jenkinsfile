import test from "node:test";
import assert from "node:assert/strict";
import { cp, mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

const exec = promisify(execFile);
const root = new URL("..", import.meta.url);

test("Lithe 0.5.4 patch is scoped and reversible", async () => {
  const patch = await readFile(new URL("../patches/lithe-0.5.4.patch", import.meta.url), "utf8");
  const monacoPatch = await readFile(new URL("../patches/lithe-0.5.4-monaco.patch", import.meta.url), "utf8");
  assert.match(patch, /bundled-extension-manifests\.ts/);
  assert.match(patch, /languages\/jenkinsfile/);
  assert.doesNotMatch(patch, /diff --git a\/(?!windows\/tauri\/src\/extensions\/bundled\/bundled-extension-manifests\.ts)/);
  assert.match(monacoPatch, /language-contributions\.ts/);
  assert.match(monacoPatch, /jenkinsfileMonarchLanguage/);

  const work = await mkdtemp(join(tmpdir(), "lithe-patch-test-"));
  try {
    await cp(new URL("./fixtures/lithe-0.5.4/", import.meta.url), work, { recursive: true });
    await exec("git", ["init", "-q"], { cwd: work });
    await exec("git", ["add", "."], { cwd: work });
    await exec("git", ["-c", "user.email=test@example.com", "-c", "user.name=test", "commit", "-qm", "fixture"], { cwd: work });
    const patchPath = fileURLToPath(new URL("../patches/lithe-0.5.4.patch", import.meta.url));
    await exec("git", ["apply", "--check", patchPath], { cwd: work });
    await exec("git", ["apply", patchPath], { cwd: work });
    await exec("git", ["apply", "--reverse", "--check", patchPath], { cwd: work });
  } finally {
    await rm(work, { recursive: true, force: true });
  }
});
