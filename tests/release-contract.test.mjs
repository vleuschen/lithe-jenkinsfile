import test from "node:test";
import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { createHash } from "node:crypto";
import { readFile, rm, readdir } from "node:fs/promises";
import { join } from "node:path";

const exec = promisify(execFile);

test("release package contains only installable assets", async () => {
  const out = join(process.cwd(), "dist-test");
  await rm(out, { recursive: true, force: true });
  await exec("pwsh", ["-NoProfile", "-File", "scripts/package-release.ps1", "-Version", "0.1.0", "-OutputDirectory", out]);
  const files = await readdir(out);
  assert.deepEqual(files.sort(), ["lithe-jenkinsfile-0.1.0.zip", "lithe-jenkinsfile-0.1.0.zip.sha256"]);
  const zip = await readFile(join(out, files.find((name) => name.endsWith(".zip"))));
  const sidecar = await readFile(join(out, "lithe-jenkinsfile-0.1.0.zip.sha256"), "utf8");
  assert.equal(sidecar.trim().split(/\s+/)[0], createHash("sha256").update(zip).digest("hex"));
  assert.ok(zip.length > 10_000);
  await rm(out, { recursive: true, force: true });
});
