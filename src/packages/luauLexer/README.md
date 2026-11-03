# Luau lexer

Vendored from [boatbomber/Highlighter](https://github.com/boatbomber/Highlighter),
commit [`e054723c1c11ad8c6ca7f6e4f4f912779463edae`](https://github.com/boatbomber/Highlighter/tree/e054723c1c11ad8c6ca7f6e4f4f912779463edae/src/lexer).

These are the four files from `src/lexer`, with repository formatting applied.
The MIT license is preserved in [LICENSE](LICENSE). No runtime downloads are needed.

The code and diff cards use `scanEach` through `src/utils/luauHighlight.luau`.
Syntax colors and symbol scopes are ported from VS Code; see
[`assets/vendor/catppuccin/README.md`](../../../assets/vendor/catppuccin/README.md).
Code is scanned as a complete source
before tokens are split into display lines; diffs scan the old and current
sources separately so removed lines cannot change the current source's syntax.
