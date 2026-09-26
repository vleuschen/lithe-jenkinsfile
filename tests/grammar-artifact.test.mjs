import test from "node:test";
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { Language, Parser } from "web-tree-sitter";

const source = JSON.parse(
  await readFile(new URL("../grammar-source.json", import.meta.url), "utf8"),
);
const wasm = await readFile(new URL("../extension/parser.wasm", import.meta.url));
const checksumText = await readFile(new URL("../extension/parser.wasm.sha256", import.meta.url), "utf8");

test("parser artifact is pinned, valid WASM, and loadable", async () => {
  assert.equal(source.repository, "https://github.com/murtaza64/tree-sitter-groovy.git");
  assert.equal(source.revision, "781d9cd1b482a70a6b27091e5c9e14bbcab3b768");
  assert.equal(source.treeSitterCli, "0.27.0");
  assert.deepEqual([...wasm.subarray(0, 4)], [0, 97, 115, 109]);

  const expected = createHash("sha256").update(wasm).digest("hex");
  assert.equal(checksumText.trim().split(/\s+/)[0].toLowerCase(), expected);

  await Parser.init();
  const language = await Language.load(new URL("../extension/parser.wasm", import.meta.url));
  assert.ok(language);
});
