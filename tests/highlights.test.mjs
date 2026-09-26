import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { Language, Parser, Query } from "web-tree-sitter";

await Parser.init();
const language = await Language.load(new URL("../extension/parser.wasm", import.meta.url));
const querySource = await readFile(new URL("../extension/highlights.scm", import.meta.url), "utf8");
const query = new Query(language, querySource);

async function captureFixture(relativePath) {
  const source = await readFile(new URL(`../${relativePath}`, import.meta.url), "utf8");
  const parser = new Parser();
  parser.setLanguage(language);
  const tree = parser.parse(source);
  return query.captures(tree.rootNode).map(({ name, node }) => ({
    name,
    text: source.slice(node.startIndex, node.endIndex),
  }));
}

test("Declarative Pipeline captures Jenkins DSL and Groovy syntax", async () => {
  const captures = await captureFixture("examples/Jenkinsfile");
  const texts = new Set(captures.map(({ text }) => text));
  assert.ok(texts.has("pipeline"));
  assert.ok(texts.has("agent"));
  assert.ok(texts.has("stages"));
  assert.ok(texts.has("stage"));
  assert.ok(captures.some(({ name, text }) => name === "string" && text.includes("npm test")));
  assert.ok(captures.some(({ name }) => name === "comment"));
});

test("Scripted Pipeline captures calls, variables, and interpolation", async () => {
  const captures = await captureFixture("examples/scripted.Jenkinsfile");
  const texts = new Set(captures.map(({ text }) => text));
  assert.ok(texts.has("node"));
  assert.ok(texts.has("stage"));
  assert.ok(texts.has("target"));
  assert.ok(captures.some(({ name, text }) => name === "string" && text.includes("gradlew")));
});

test("incomplete Jenkinsfile remains highlightable", async () => {
  const captures = await captureFixture("examples/incomplete.Jenkinsfile");
  assert.ok(captures.length > 0);
  assert.ok(captures.some(({ text }) => text === "pipeline"));
});
