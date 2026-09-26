# Lithe Jenkinsfile Syntax Highlighting Extension Design

## Summary

Create an independently maintained GitHub repository that adds syntax highlighting for Jenkins Pipeline files to Lithe on Windows. The first release targets Lithe 0.5.4, provides syntax highlighting only, and integrates into a user-owned Lithe source checkout through a reversible PowerShell script.

The project does not distribute a modified Lithe executable, does not use the Lithe or Jenkins logos, and does not claim endorsement by Lithe, Jenkins, CloudBees, or their maintainers.

## Goals

- Recognize exact files named `Jenkinsfile`, files matching `*.Jenkinsfile`, and Groovy-related extensions used for pipeline code.
- Highlight Groovy syntax and common Declarative and Scripted Pipeline constructs.
- Produce a lightweight extension with no language server or runtime service.
- Provide deterministic build, install, uninstall, test, and release workflows.
- Keep all third-party licenses and provenance visible in source and release artifacts.
- Publish the project as an independent GitHub repository.

## Non-goals

- Code completion, diagnostics, hover information, formatting, or Jenkins server integration.
- Installation through Lithe's official extension marketplace or CDN.
- Binary patching of an installed `lithe-windows.exe`.
- Distribution of a modified Lithe build.
- Support for Lithe versions other than 0.5.4 in the first release.

## Confirmed Lithe Constraints

Lithe 0.5.4 has a Windows extension registry and a Tree-sitter WASM language-extension pipeline. Its manifest model supports exact filenames, filename patterns, extensions, grammar paths, and highlight queries.

Lithe 0.5.4 does not scan arbitrary third-party directories below its installed `extensions` directory. Language manifests are registered at build time or fetched from Lithe's official extension CDN. Copying a standalone extension folder into `D:\softwares\Lithe\extensions` is therefore insufficient.

The supported manual installation method for this project will integrate the extension into a Lithe 0.5.4 source checkout and then invoke Lithe's official Windows build process. It will not patch the installed executable.

## Repository Layout

```text
lithe-jenkinsfile/
├── extension/
│   ├── extension.json
│   ├── parser.wasm
│   ├── highlights.scm
│   └── language-configuration.json
├── examples/
│   ├── Jenkinsfile
│   └── scripted.Jenkinsfile
├── scripts/
│   ├── build-grammar.ps1
│   ├── install.ps1
│   └── uninstall.ps1
├── patches/
│   └── lithe-0.5.4.patch
├── tests/
├── docs/superpowers/specs/
├── LICENSE
├── THIRD_PARTY_NOTICES.md
└── README.md
```

## Extension Architecture

### Language registration

The manifest will define one language ID, `jenkinsfile`, with:

- exact filename `Jenkinsfile`;
- filename pattern `*.Jenkinsfile`;
- extensions `.groovy` and `.gradle`;
- aliases `Jenkinsfile`, `Jenkins Pipeline`, and `Groovy`;
- a Tree-sitter WASM grammar and highlight-query contribution;
- no LSP, formatter, or linter configuration.

The extension will use a distinct `jenkinsfile` language ID rather than claiming Lithe-wide ownership of Groovy. This keeps a future full Groovy extension able to coexist, while the shared parser still provides Groovy syntax coverage.

### Parser

The parser will be compiled to WebAssembly from a pinned commit of `murtaza64/tree-sitter-groovy`. The pinned revision will be recorded in the build script, README, and third-party notices. The generated `parser.wasm` will be committed so users installing a release do not need the grammar toolchain.

`scripts/build-grammar.ps1` will reproduce the artifact from the pinned source. It will fail if prerequisites are missing and will print the exact commands needed to install them. It will not silently download or execute an unpinned revision.

### Highlight query

`highlights.scm` will cover standard Groovy syntax and add original Jenkins Pipeline-specific captures for common DSL calls, including `pipeline`, `agent`, `stages`, `stage`, `steps`, `post`, `environment`, `options`, `parameters`, `triggers`, `tools`, `when`, `input`, `parallel`, `script`, and `matrix`.

The query will distinguish language keywords, method/DSL calls, strings, interpolation, numbers, comments, annotations, types, properties, and punctuation. Jenkins-specific captures will use highlight names that Lithe already maps into its theme token roles.

### Language configuration

The language configuration will define:

- `//` line comments and `/* ... */` block comments;
- bracket and quote pairs;
- surrounding pairs;
- conservative auto-closing behavior suitable for Groovy strings and closures.

## Installation Design

`scripts/install.ps1` will require `-LitheSource <absolute-path>` and accept an optional build switch. It will:

1. Resolve and validate the supplied path.
2. Confirm that it is a Lithe 0.5.4 source checkout by checking expected manifest and build files.
3. Check the Git worktree and refuse to overwrite conflicting changes.
4. Copy the extension assets into a dedicated Windows bundled-language directory.
5. Apply `patches/lithe-0.5.4.patch`, which adds only the manifest import and registry entry needed for this extension.
6. Verify that the copied assets and registration entry agree.
7. Optionally invoke Lithe's existing Windows build script.

The installer will be idempotent. Running it when the same version is already integrated will report success without duplicating registrations. A structurally different Lithe version, partial prior installation, or conflicting target content will cause a fail-closed error with recovery guidance.

`scripts/uninstall.ps1` will validate the same source checkout, reverse the exact versioned patch, and remove only the extension-owned directory. It will leave build outputs and unrelated user changes untouched.

## Error Handling and Safety

- All filesystem targets must resolve within the explicit Lithe source directory.
- Scripts must use literal paths and must not recursively delete computed or unverified paths.
- No script modifies `D:\softwares\Lithe\lithe-windows.exe`.
- No script changes system DNS, proxy, certificate, or hosts-file settings.
- Patch application will run in check mode before making changes.
- Failed installation will either make no changes or report exactly which copied extension directory can be removed.
- Build failures remain Lithe source-build failures; the installer will preserve logs and will not attempt destructive cleanup.

## Testing Strategy

### Parser fixtures

Fixtures will cover Declarative and Scripted Pipeline syntax, nested stages, parallel branches, matrix configuration, environment values, shared-library calls, string interpolation, comments, conditions, and error-tolerant incomplete edits.

### Query validation

Automated checks will compile the highlight query against the pinned grammar and assert representative capture categories. Tests will verify Jenkins DSL calls, Groovy keywords, strings, interpolation, numbers, comments, variables, and types.

### Manifest validation

Tests will validate required metadata, exact filename registration, filename patterns, supported extensions, relative asset paths, Lithe engine compatibility, and absence of LSP/formatter/linter capabilities.

### Installer validation

Installer tests will use a temporary fixture shaped like the relevant Lithe 0.5.4 source paths. They will verify:

- successful first installation;
- idempotent repeated installation;
- rejection of unsupported layouts;
- refusal on conflicting modifications;
- complete, scoped uninstall;
- preservation of unrelated files and changes.

### End-to-end verification

A real Lithe 0.5.4 Windows source build will open both example pipeline files. Acceptance requires correct language detection, visible syntax coloring, comment toggling, bracket behavior, and no background language-server process. A representative screenshot will be included in the README.

## Release Design

GitHub Actions will rebuild the parser from the pinned grammar revision, run all tests, compare the generated WASM artifact with the committed artifact, and package releases.

Each version tag will produce a ZIP containing:

- extension assets;
- install and uninstall scripts;
- the Lithe 0.5.4 integration patch;
- README and installation instructions;
- project license and third-party notices;
- SHA-256 checksums.

The release will not contain Lithe source or binaries. Compatibility will be stated as Lithe 0.5.4 on Windows. Support for later Lithe versions will use separately reviewed versioned patches rather than weakening installer checks.

## Licensing and Trademark Risk Controls

The project will use Apache License 2.0. This aligns with Lithe but is a project choice; the plugin does not need to adopt Lithe's license merely to interoperate with it.

The Tree-sitter Groovy parser is MIT-licensed. Its copyright and license text will be preserved in `THIRD_PARTY_NOTICES.md` and included in release archives. The pinned upstream revision and any project-specific modifications will be documented.

The project will not copy Lithe source except for the minimal patch context needed to identify integration points. The patch and documentation will state that they modify a user-owned Lithe checkout. If any Apache-licensed Lithe code is later incorporated, the repository will retain the required notices and mark modifications.

The project will not use Jenkins, CloudBees, or Lithe logos. Repository naming and documentation may use `Jenkinsfile` and `Lithe` descriptively to state compatibility, while prominently saying that the project is unofficial and is not affiliated with or endorsed by Jenkins, CloudBees, Lithe, or their maintainers.

This is an engineering compliance assessment, not legal advice.

## Success Criteria

- A fresh checkout can reproduce `parser.wasm` from a pinned upstream revision.
- Tests pass for representative Declarative and Scripted Pipeline files.
- The installer safely integrates the extension into a clean Lithe 0.5.4 source checkout and is idempotent.
- The uninstaller removes only extension-owned changes.
- A rebuilt Windows Lithe recognizes and highlights `Jenkinsfile` and `*.Jenkinsfile`.
- The repository and release archive contain all required licenses, notices, provenance, checksums, and non-affiliation statements.
- The repository can be published independently without distributing a modified Lithe executable.
