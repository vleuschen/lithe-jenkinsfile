# Lithe Jenkinsfile Syntax Highlighting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build, validate, package, and publish an independently maintained Jenkinsfile syntax-highlighting extension that integrates safely into a Lithe 0.5.4 Windows source checkout.

**Architecture:** A declarative Lithe extension contributes a pinned Tree-sitter Groovy WASM parser, an original Jenkins-aware highlight query, and filename associations. Versioned PowerShell tooling copies the extension into a user-owned Lithe checkout and applies one auditable registry patch; Node tests and Pester tests validate language assets and reversible integration before GitHub release packaging.

**Tech Stack:** Node.js 24, npm, `tree-sitter-cli` 0.27.0, `web-tree-sitter` 0.27.0, PowerShell 7, Pester 5, GitHub Actions, JSON, Scheme Tree-sitter queries

**Spec:** `docs/superpowers/specs/2026-09-26-lithe-jenkinsfile-design.md`

## Global Constraints

- Target Windows and Lithe `v0.5.4`, whose peeled tag commit is `9674a4457916285fc232504d07b6b1c08c0c7d64`.
- Pin `murtaza64/tree-sitter-groovy` to commit `deb0dcf8c4544f07564060f6e9b9f6e4b0bfc27d`.
- Pin `tree-sitter-cli` and `web-tree-sitter` to `0.27.0`; commit `package-lock.json`.
- Register language ID `jenkinsfile` for exact filename `Jenkinsfile`, glob `*.Jenkinsfile`, and extensions `.groovy` and `.gradle`.
- Do not add an LSP, formatter, linter, Jenkins server connection, or background process.
- Do not modify or distribute `lithe-windows.exe` or any other Lithe binary.
- Installer writes must resolve inside the explicit `-LitheSource` directory and fail closed on unsupported or conflicting content.
- Use Apache-2.0 for this repository and preserve the upstream Tree-sitter Groovy MIT notice in every release.
- Use no Jenkins, CloudBees, or Lithe logos; label the project unofficial and unendorsed.

## Review Focus

- Exact-name detection must recognize `Jenkinsfile` and `release.Jenkinsfile` without claiming unrelated extensionless files; pin this in Task 1 manifest tests.
- Incomplete or syntactically invalid Jenkinsfiles must still parse and highlight without throwing; pin this in Task 3 query tests.
- Install, reinstall, partial install, and uninstall must never duplicate registrations or remove unrelated files; pin this in Task 5 Pester tests.
- Source paths containing spaces and non-ASCII characters must work without shell re-parsing; pin this in Task 5 Pester tests.
- Wrong Lithe version, missing Git metadata, and a modified registry file must fail before any write; pin this in Task 5 Pester tests.

---

## File Structure

- `package.json`, `package-lock.json`: pinned JavaScript tooling and test commands.
- `.gitignore`: caches and generated temporary directories only; committed WASM remains tracked.
- `extension/extension.json`: Lithe language manifest and compatibility metadata.
- `extension/parser.wasm`, `extension/parser.wasm.sha256`: committed runtime parser and checksum.
- `extension/highlights.scm`: Groovy plus Jenkins Pipeline highlight captures.
- `extension/language-configuration.json`: comments, brackets, and auto-closing pairs.
- `grammar-source.json`: immutable parser repository, revision, and build-tool metadata.
- `examples/Jenkinsfile`, `examples/scripted.Jenkinsfile`, `examples/incomplete.Jenkinsfile`: acceptance fixtures.
- `scripts/build-grammar.ps1`: reproducible parser build.
- `scripts/lib/LitheIntegration.psm1`: validated install/uninstall operations.
- `scripts/install.ps1`, `scripts/uninstall.ps1`: user-facing wrappers.
- `scripts/package-release.ps1`: deterministic release ZIP and checksums.
- `patches/lithe-0.5.4.patch`: minimal Lithe registry integration.
- `tests/*.test.mjs`: manifest, parser, highlighting, and release contract tests.
- `tests/install.Tests.ps1`: integration-script safety tests.
- `tests/fixtures/lithe-0.5.4/`: minimal upstream-shaped source fixture.
- `.github/workflows/ci.yml`, `.github/workflows/release.yml`: verification and tagged releases.
- `LICENSE`, `THIRD_PARTY_NOTICES.md`, `README.md`: license, provenance, compatibility, usage, and non-affiliation documentation.

### Task 1: Manifest Contract and Repository Metadata

**Files:**
- Create: `package.json`
- Create: `package-lock.json`
- Create: `.gitignore`
- Create: `extension/extension.json`
- Create: `extension/language-configuration.json`
- Create: `tests/manifest.test.mjs`
- Create: `LICENSE`
- Create: `THIRD_PARTY_NOTICES.md`

**Interfaces:**
- Consumes: Lithe 0.5.4 manifest fields documented in the approved spec.
- Produces: `extension/extension.json` with extension ID `community.lithe-jenkinsfile`, language ID `jenkinsfile`, and relative grammar asset paths used by every later task.

- [ ] **Step 1: Write the failing manifest contract test**

Use `node:test` in `tests/manifest.test.mjs`. Assert the exact ID, version `0.1.0`, publisher `Lithe Jenkinsfile Contributors`, Apache-2.0 license, `engines.lithe` value `=0.5.4`, filename/extension associations, `./parser.wasm`, `./highlights.scm`, and the absence of `lsp`, `formatter`, and `linter`. Also assert that `README.md` is not required by this unit test.

- [ ] **Step 2: Run the manifest test and verify the missing manifest fails**

Run: `npm test -- --test-name-pattern="manifest"`

Expected: FAIL because `extension/extension.json` does not exist.

- [ ] **Step 3: Create pinned package metadata and the minimal manifest**

Define npm scripts `test`, `test:node`, `test:pester`, `build:grammar`, and `package`. Pin exact dev dependencies `tree-sitter-cli@0.27.0` and `web-tree-sitter@0.27.0`. Configure the manifest with both `languages` and `contributes.languages` carrying the same single language contribution, plus top-level `grammar` containing `wasmPath`, `highlightQueryPath`, `scopeName: "source.jenkinsfile"`, and `languageId: "jenkinsfile"`.

- [ ] **Step 4: Add language configuration and license records**

Define `//` and `/* */` comments, `()`, `[]`, `{}` brackets, quote surrounding pairs, and conservative quote/bracket auto-closing. Add the full Apache-2.0 text and a third-party notice naming the pinned Tree-sitter Groovy repository, commit, MIT license, and the generated WASM/query relationship.

- [ ] **Step 5: Install dependencies and run the manifest test**

Run: `npm install`

Run: `npm test -- --test-name-pattern="manifest"`

Expected: PASS with no unhandled warnings.

- [ ] **Step 6: Commit the manifest contract**

```powershell
git add package.json package-lock.json .gitignore extension tests/manifest.test.mjs LICENSE THIRD_PARTY_NOTICES.md
git commit -m "feat: define Jenkinsfile extension manifest"
```

### Task 2: Reproducible Groovy WASM Parser

**Files:**
- Create: `grammar-source.json`
- Create: `scripts/build-grammar.ps1`
- Create: `extension/parser.wasm`
- Create: `extension/parser.wasm.sha256`
- Create: `tests/grammar-artifact.test.mjs`

**Interfaces:**
- Consumes: `tree-sitter-cli@0.27.0` and grammar commit `deb0dcf8c4544f07564060f6e9b9f6e4b0bfc27d`.
- Produces: `Build-GroovyGrammar([string] $OutputPath, [switch] $Offline)`, a loadable `extension/parser.wasm`, and a lowercase SHA-256 sidecar.

- [ ] **Step 1: Write the failing parser provenance test**

In `tests/grammar-artifact.test.mjs`, assert that `grammar-source.json` has the exact HTTPS repository, commit, and CLI version; that the parser starts with WASM magic bytes `00 61 73 6d`; that the sidecar matches `sha256(parser.wasm)`; and that `web-tree-sitter` can load the language.

- [ ] **Step 2: Run the parser test and verify it fails on missing artifacts**

Run: `node --test tests/grammar-artifact.test.mjs`

Expected: FAIL because `grammar-source.json` or `extension/parser.wasm` is missing.

- [ ] **Step 3: Implement `Build-GroovyGrammar` in `scripts/build-grammar.ps1`**

Clone the upstream parser into a generated cache directory, detach at the exact commit, verify `HEAD`, resolve `$resolvedOutput` and `$grammarDirectory` as literal absolute paths, and run `npx tree-sitter build --wasm --output $resolvedOutput $grammarDirectory`. `-Offline` must reuse an already verified cache or fail with an actionable message. Write the SHA-256 sidecar only after the WASM build succeeds.

- [ ] **Step 4: Build and validate the committed parser**

Run: `pwsh -NoProfile -File scripts/build-grammar.ps1 -OutputPath extension/parser.wasm`

Run: `node --test tests/grammar-artifact.test.mjs`

Expected: parser build exits 0 and all provenance/artifact assertions PASS.

- [ ] **Step 5: Verify a second offline build is byte-identical**

Run the build into a temporary output with `-Offline`, compare its SHA-256 to `extension/parser.wasm.sha256`, and remove only that explicit temporary output.

Expected: hashes are identical.

- [ ] **Step 6: Commit the reproducible parser**

```powershell
git add grammar-source.json scripts/build-grammar.ps1 extension/parser.wasm extension/parser.wasm.sha256 tests/grammar-artifact.test.mjs
git commit -m "build: add reproducible Groovy WASM parser"
```

### Task 3: Jenkins-Aware Highlighting and Fixtures

**Files:**
- Create: `extension/highlights.scm`
- Create: `examples/Jenkinsfile`
- Create: `examples/scripted.Jenkinsfile`
- Create: `examples/incomplete.Jenkinsfile`
- Create: `tests/highlights.test.mjs`

**Interfaces:**
- Consumes: loadable `extension/parser.wasm` from Task 2.
- Produces: `captureFixture(relativePath: string): Promise<Array<{name: string, text: string}>>` in the test helper and a query using Lithe-supported capture names.

- [ ] **Step 1: Add representative pipeline fixtures**

The Declarative fixture must include `pipeline`, `agent`, `environment`, `parameters`, `stages`, `stage`, `when`, `steps`, `parallel`, `post`, interpolation, and comments. The Scripted fixture must include `node`, `stage`, `script`, variables, closures, and shared-library-style calls. The incomplete fixture must end inside an unfinished stage or call.

- [ ] **Step 2: Write the failing highlight-query tests**

Load the WASM with `web-tree-sitter`, compile `highlights.scm`, and assert captures for Groovy keywords, comments, strings, numbers, identifiers, types, and the Jenkins DSL names above. Assert all three fixtures return captures without throwing and that the incomplete fixture still yields at least one keyword and one function/DSL capture.

- [ ] **Step 3: Run the highlight tests and verify the missing query fails**

Run: `node --test tests/highlights.test.mjs`

Expected: FAIL because `extension/highlights.scm` does not exist.

- [ ] **Step 4: Implement the minimal compatible highlight query**

Use capture names already understood by Lithe: `keyword`, `function`, `function.builtin`, `type`, `property`, `variable`, `string`, `number`, `comment`, `operator`, and `punctuation`. Write Jenkins-specific patterns directly against the pinned grammar's node shapes; do not copy unlicensed editor queries.

- [ ] **Step 5: Run all Node tests**

Run: `npm run test:node`

Expected: manifest, parser, and highlight tests PASS.

- [ ] **Step 6: Commit highlighting behavior**

```powershell
git add extension/highlights.scm examples tests/highlights.test.mjs
git commit -m "feat: highlight Jenkins Pipeline syntax"
```

### Task 4: Versioned Lithe 0.5.4 Integration Patch

**Files:**
- Create: `patches/lithe-0.5.4.patch`
- Create: `tests/fixtures/lithe-0.5.4/windows/tauri/src/extensions/bundled/bundled-extension-manifests.ts`
- Create: `tests/patch-contract.test.mjs`

**Interfaces:**
- Consumes: upstream Lithe tag `v0.5.4` at peeled commit `9674a4457916285fc232504d07b6b1c08c0c7d64`.
- Produces: a patch that adds `jenkinsfileManifest` and exactly one `relativePath: "languages/jenkinsfile"` registry entry.

- [ ] **Step 1: Write the failing patch contract test**

Assert that the patch changes only `windows/tauri/src/extensions/bundled/bundled-extension-manifests.ts`, contains the exact import and relative path, and applies cleanly to a copy of the fixture with `git apply --check`.

- [ ] **Step 2: Run the patch test and verify it fails**

Run: `node --test tests/patch-contract.test.mjs`

Expected: FAIL because the patch and fixture are missing.

- [ ] **Step 3: Capture the exact upstream registry file and author the minimal patch**

Copy only the unmodified Lithe 0.5.4 registry file into the test fixture, record its Apache-2.0 origin in `THIRD_PARTY_NOTICES.md`, and create a patch with one JSON import and one manifest entry. Do not include extension assets in the patch.

- [ ] **Step 4: Verify forward and reverse patch checks**

Run: `node --test tests/patch-contract.test.mjs`

Expected: forward `git apply --check` passes; after applying, reverse `git apply --reverse --check` passes; no second file is changed.

- [ ] **Step 5: Commit the integration patch**

```powershell
git add patches tests/fixtures tests/patch-contract.test.mjs THIRD_PARTY_NOTICES.md
git commit -m "feat: add Lithe 0.5.4 integration patch"
```

### Task 5: Safe Install and Uninstall Scripts

**Files:**
- Create: `scripts/lib/LitheIntegration.psm1`
- Create: `scripts/install.ps1`
- Create: `scripts/uninstall.ps1`
- Create: `tests/install.Tests.ps1`

**Interfaces:**
- Consumes: extension assets from Tasks 1-3 and the patch from Task 4.
- Produces: `Test-LitheSource([string] $LitheSource): LitheSourceValidation`, `Install-LitheJenkinsfile([string] $LitheSource, [switch] $Build): void`, and `Uninstall-LitheJenkinsfile([string] $LitheSource): void`.

- [ ] **Step 1: Write failing Pester tests for validation and installation**

Test a clean fixture, repeat install, a partial copied directory, a registry conflict, the wrong version marker, missing `.git`, unrelated dirty files, a dirty registry file, and a copied fixture under a path containing both spaces and `测试`. Assert no write occurs for every rejected precondition.

- [ ] **Step 2: Write failing Pester tests for uninstall and build delegation**

Assert uninstall reverses only the registry patch and removes only `languages/jenkinsfile`; preserves unrelated files; is idempotent when fully absent; rejects partial state; and invokes the upstream Windows build script only when `-Build` is supplied.

- [ ] **Step 3: Run Pester and verify the module is missing**

Run: `pwsh -NoProfile -Command "Invoke-Pester -Path tests/install.Tests.ps1 -Output Detailed"`

Expected: FAIL because `scripts/lib/LitheIntegration.psm1` does not exist.

- [ ] **Step 4: Implement source validation and scoped path resolution**

`Test-LitheSource` must resolve an absolute path, require Git metadata, verify the expected Lithe registry and build-script paths, verify tag commit compatibility, and report registry dirtiness separately from unrelated worktree changes. Every derived destination must pass a case-insensitive Windows containment check under the resolved source root.

- [ ] **Step 5: Implement transactional installation**

Preflight copy conflicts and `git apply --check` before writing. Copy assets to `windows/tauri/src/extensions/bundled/languages/jenkinsfile`, apply the patch, verify the final manifest entry, and roll back the copied extension directory if patch application fails. Reinstallation with identical bytes and an already applied patch returns success without changes.

- [ ] **Step 6: Implement scoped uninstallation**

Require either complete installed state or complete absent state. Check reverse patch applicability before changing files, reverse the patch, then remove the verified exact plugin directory without recursive operations against any unresolved or broader path.

- [ ] **Step 7: Add user-facing wrappers and optional build invocation**

`install.ps1` and `uninstall.ps1` import the module, expose mandatory `-LitheSource`, and return nonzero on validation failures. `install.ps1 -Build` invokes the upstream build script with its documented Release configuration after integration succeeds.

- [ ] **Step 8: Run script and full repository tests**

Run: `npm test`

Expected: Node and Pester suites PASS, including idempotency, Unicode path, conflict, and preservation cases.

- [ ] **Step 9: Commit installation tooling**

```powershell
git add scripts tests/install.Tests.ps1 package.json package-lock.json
git commit -m "feat: add safe Lithe source installer"
```

### Task 6: Release Packaging, CI, and Documentation

**Files:**
- Create: `scripts/package-release.ps1`
- Create: `tests/release-contract.test.mjs`
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/release.yml`
- Create: `README.md`
- Modify: `THIRD_PARTY_NOTICES.md`

**Interfaces:**
- Consumes: all tested runtime assets and scripts from Tasks 1-5.
- Produces: `New-LitheJenkinsfileRelease([string] $Version, [string] $OutputDirectory): ReleaseResult` with ZIP and SHA-256 paths, plus CI artifacts ready for a GitHub Release.

- [ ] **Step 1: Write the failing release contract test**

Assert the packaged ZIP contains extension assets, scripts, patch, README, LICENSE, and third-party notices; excludes `.git`, caches, tests, Lithe binaries, and source fixtures; and has a matching lowercase SHA-256 sidecar.

- [ ] **Step 2: Run the release test and verify the packager is missing**

Run: `node --test tests/release-contract.test.mjs`

Expected: FAIL because `scripts/package-release.ps1` is missing.

- [ ] **Step 3: Implement deterministic release packaging**

Stage an explicit allowlist into a new temporary directory, name the top-level folder `lithe-jenkinsfile-$Version`, create the ZIP, calculate SHA-256, and return both absolute paths. Reject a version not matching `^[0-9]+\.[0-9]+\.[0-9]+$`.

- [ ] **Step 4: Write the README and final notices**

Document prerequisites, source installation, build, uninstall, supported filenames, limitations, troubleshooting, verification, license provenance, and the explicit non-affiliation statement. State that installation modifies a user-owned Lithe source checkout and never the installed executable. Reserve a screenshot section for the verified image produced in Task 7 without using a placeholder token.

- [ ] **Step 5: Add CI and tagged release workflows**

CI on Windows checks out full Git history, installs Node 24 dependencies, installs Pester 5 in current-user scope, rebuilds the parser, compares its hash, and runs `npm test`. Tag workflow for `v*` repeats verification, packages the version, and uploads the ZIP and checksum to a GitHub Release.

- [ ] **Step 6: Run packaging and all tests locally**

Run: `pwsh -NoProfile -File scripts/package-release.ps1 -Version 0.1.0 -OutputDirectory dist`

Run: `npm test`

Expected: release contract and all prior tests PASS; `dist` contains one ZIP and one matching checksum file.

- [ ] **Step 7: Commit release automation and docs**

```powershell
git add scripts/package-release.ps1 tests/release-contract.test.mjs .github README.md THIRD_PARTY_NOTICES.md package.json package-lock.json
git commit -m "docs: add CI and release workflow"
```

### Task 7: Lithe 0.5.4 End-to-End Acceptance and GitHub Publication

**Files:**
- Create: `docs/images/jenkinsfile-highlighting.png`
- Modify: `README.md`

**Interfaces:**
- Consumes: the completed plugin, installer, and a clean Lithe 0.5.4 source checkout.
- Produces: evidence of a passing Windows build and editor behavior, then a public GitHub repository named `lithe-jenkinsfile` with tag and release `v0.1.0`.

- [ ] **Step 1: Prepare and verify the exact upstream checkout**

Create an absolute `$litheCheckout` path, clone Lithe tag `v0.5.4` there, verify `HEAD` resolves to `9674a4457916285fc232504d07b6b1c08c0c7d64`, and confirm the worktree is clean before installation.

- [ ] **Step 2: Install and build through the supported path**

Run `scripts/install.ps1 -LitheSource $litheCheckout -Build` and preserve the build log.

Expected: installation and the upstream Release build exit 0; the original installed `D:\softwares\Lithe\lithe-windows.exe` remains untouched.

- [ ] **Step 3: Perform interactive editor acceptance**

Launch the newly built executable, open all three example files, and verify exact-name/pattern recognition, visible syntax coloring, comment toggling, bracket behavior, resilience on the incomplete fixture, and absence of a Groovy/Jenkins language-server child process.

- [ ] **Step 4: Capture evidence and update the README**

Save a screenshot with no secrets or unrelated project data to `docs/images/jenkinsfile-highlighting.png`, link it in the existing README screenshot section, and record the tested Lithe commit and Windows environment.

- [ ] **Step 5: Verify uninstall against the source checkout**

Run `scripts/uninstall.ps1 -LitheSource $litheCheckout`.

Expected: plugin directory and registry patch are absent; unrelated build outputs are left untouched; `git diff` shows no plugin integration changes.

- [ ] **Step 6: Run final verification and commit acceptance evidence**

Run: `npm test`

Run: `git status --short`

Expected: all tests PASS; only the intended screenshot and README edit are uncommitted.

```powershell
git add docs/images/jenkinsfile-highlighting.png README.md
git commit -m "docs: add Lithe acceptance evidence"
```

- [ ] **Step 7: Create and publish the GitHub repository**

Rename the local branch to `main`. Create a public repository named `lithe-jenkinsfile` in the authenticated GitHub account, add it as `origin`, push `main`, and verify the repository description and Apache-2.0 license display correctly. Do not overwrite an existing repository with that name.

- [ ] **Step 8: Publish version 0.1.0**

Create annotated tag `v0.1.0`, push it, wait for the release workflow, and verify the GitHub Release contains the ZIP and checksum produced from the tagged commit.

- [ ] **Step 9: Final repository review**

Verify the default branch is clean, CI and release checks pass, public installation instructions match the released archive, all external links work, and no Lithe executable, cache, build checkout, credential, or unrelated local file is present.
