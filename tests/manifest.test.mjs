import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const manifest = JSON.parse(
  await readFile(new URL("../extension/extension.json", import.meta.url), "utf8"),
);

test("manifest registers Jenkinsfile and Groovy pipeline files", () => {
  assert.equal(manifest.id, "community.lithe-jenkinsfile");
  assert.equal(manifest.version, "0.1.0");
  assert.equal(manifest.license, "Apache-2.0");
  assert.equal(manifest.engines.lithe, "=0.5.4");
  assert.deepEqual(manifest.languages, manifest.contributes.languages);

  const language = manifest.languages.find(({ id }) => id === "jenkinsfile");
  assert.ok(language);
  assert.deepEqual(language.extensions, [".groovy", ".gradle"]);
  assert.deepEqual(language.filenames, ["Jenkinsfile"]);
  assert.deepEqual(language.filenamePatterns, ["*.Jenkinsfile"]);
  assert.deepEqual(manifest.grammar, {
    wasmPath: "./parser.wasm",
    highlightQueryPath: "./highlights.scm",
    scopeName: "source.jenkinsfile",
    languageId: "jenkinsfile",
  });

  assert.equal("lsp" in manifest, false);
  assert.equal("formatter" in manifest, false);
  assert.equal("linter" in manifest, false);
});
