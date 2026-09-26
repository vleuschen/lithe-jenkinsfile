# Lithe Jenkinsfile Syntax Highlighting

An unofficial, highlighting-only extension for [Lithe](https://github.com/1lck/Lithe-IDEA) 0.5.4. It recognizes `Jenkinsfile`, `*.Jenkinsfile`, `.groovy`, and `.gradle` files and highlights Groovy plus common Jenkins Pipeline DSL calls.

This project does not provide completion, diagnostics, formatting, an LSP, or a Jenkins server connection. It never modifies `D:\softwares\Lithe\lithe-windows.exe`; installation targets a user-owned Lithe source checkout so the result can be rebuilt and audited.

## Requirements

- Windows, Git, Node.js 24+, npm, and PowerShell 7 for development/building.
- A clean Lithe `v0.5.4` source checkout for installation.

## Manual installation

From this repository, run:

```powershell
pwsh -NoProfile -File .\scripts\install.ps1 -LitheSourcePath 'D:\src\Lithe-IDEA'
```

Then build the Lithe checkout using its normal Windows release instructions and launch the newly built executable. To remove the integration:

```powershell
pwsh -NoProfile -File .\scripts\uninstall.ps1 -LitheSourcePath 'D:\src\Lithe-IDEA'
```

The scripts validate Git metadata, apply one versioned registry patch, copy only the extension assets, and support paths containing spaces or non-ASCII characters. They fail closed on conflicts.

## Development and verification

```powershell
npm install
npm test
npm run package
```

The parser is pinned in `grammar-source.json`; `extension/parser.wasm` is committed with a SHA-256 sidecar. The release ZIP contains the extension, patch, scripts, licenses, and notices, but no Lithe binary or source checkout.

## License and provenance

This repository is Apache-2.0. The bundled Groovy parser comes from `murtaza64/tree-sitter-groovy` under MIT; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Jenkins, CloudBees, Lithe, and their marks are referenced only for compatibility. This is an independent project and is not affiliated with, sponsored by, or endorsed by those organizations.

## Limitations

The first release is syntax highlighting only. Jenkins Pipeline semantics are intentionally not validated, and arbitrary Groovy constructs may receive generic Groovy coloring. The integration patch is specifically for Lithe 0.5.4.
