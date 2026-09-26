# Third-party notices

## tree-sitter-groovy

This project uses the parser grammar from [murtaza64/tree-sitter-groovy](https://github.com/murtaza64/tree-sitter-groovy), pinned to commit `781d9cd1b482a70a6b27091e5c9e14bbcab3b768`.

The upstream parser is distributed under the MIT License. The generated `extension/parser.wasm` is built from that pinned source. The Jenkins Pipeline additions in `extension/highlights.scm` are original project code and are not copied from an upstream editor plugin.

The MIT License text for the pinned parser source is reproduced below:

```text
MIT License

Copyright (c) 2024 Murtaza Javaid

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Lithe integration context

The optional `patches/lithe-0.5.4.patch` targets the Apache-2.0 licensed Lithe source project at [1lck/Lithe-IDEA](https://github.com/1lck/Lithe-IDEA), tag `v0.5.4`. This repository does not redistribute Lithe source or binaries. The patch is supplied only to modify a user-owned source checkout during a local build.

## Trademarks and affiliation

This is an unofficial compatibility project. It is not affiliated with, sponsored by, or endorsed by Jenkins, CloudBees, Lithe, or the Lithe maintainers. Jenkins and Lithe are referenced only to describe compatibility. No project logos or protected brand artwork are distributed.
