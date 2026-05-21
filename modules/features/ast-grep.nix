# ast-grep (sg) - Structural code search and rewriting
# https://github.com/ast-grep/ast-grep
# https://ast-grep.github.io/
#
# ══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ══════════════════════════════════════════════════════════════════════════════
#
# ast-grep is a polyglot, fast, and easy-to-use tool for code structural search,
# lint, and rewriting at large scale. It uses Tree-sitter parsers under the hood
# to operate on the AST (abstract syntax tree) rather than raw text, which
# eliminates a whole class of false positives that text-based tools like grep
# and ripgrep produce.
#
# Why this matters for AI coding agents:
#   - "find all callers of fn X" with rg returns matches in strings, comments,
#     similarly-named functions, and unrelated tokens
#   - ast-grep returns only true syntactic matches: actual call sites, actual
#     definitions, actual class declarations
#   - For refactor work this is the difference between "right answer" and
#     "needle in a haystack of false positives"
#
# Key features:
#   - Pattern matches use real source syntax (looks like the code you're
#     searching for), not regex. Variables like `$VAR` capture sub-trees.
#   - 20+ languages supported via Tree-sitter (TypeScript, Python, Rust, Go,
#     Java, C, C++, C#, Ruby, Swift, Kotlin, etc.)
#   - Fast: parallel parsing, comparable in throughput to ripgrep on big trees
#   - Available as a binary (`ast-grep` / shortcut `sg`), an editor LSP, a
#     CI linter, and a Node/Python library
#
# ══════════════════════════════════════════════════════════════════════════════
# USAGE
# ══════════════════════════════════════════════════════════════════════════════
#
#   sg -p '<pattern>' -l <lang> [path]   Search for pattern
#   sg -p '<pattern>' -r '<rewrite>'      Rewrite matches in place
#   sg scan                               Lint with config (sgconfig.yml)
#   sg test                               Run rule tests
#
# ── Examples (TypeScript) ────────────────────────────────────────────────────
#
#   # Find every call to console.log
#   sg -p 'console.log($$$ARGS)' -l ts
#
#   # Find every async function with no await body
#   sg -p 'async function $NAME($$$) { $$$ }' -l ts
#
#   # Rename a function and its call sites
#   sg -p 'oldName($$$ARGS)' -r 'newName($$$ARGS)' -l ts -U
#
#   # Find all React class components (extends Component or PureComponent)
#   sg -p 'class $NAME extends $BASE { $$$ }' -l tsx
#
# ── Examples (Python) ────────────────────────────────────────────────────────
#
#   # Find all uses of pickle.load (security concern)
#   sg -p 'pickle.load($$$)' -l py
#
#   # Find every function whose name starts with "test_"
#   sg -p 'def test_$NAME($$$): $$$' -l py
#
# ── Examples (Nix) ───────────────────────────────────────────────────────────
#
#   # Find every home.packages list to audit additions
#   sg -p 'home.packages = $$$' -l nix
#
# ══════════════════════════════════════════════════════════════════════════════
# WHEN TO USE AST-GREP vs RIPGREP
# ══════════════════════════════════════════════════════════════════════════════
#
# Use ast-grep when the question is structural:
#   - "find all callers of fn X"
#   - "find all classes implementing interface Y"
#   - "find every place this hook is called without dependencies"
#   - "rename method M across the codebase"
#   - "find every async fn that doesn't await its main expression"
#
# Use ripgrep when the question is textual:
#   - "find this exact string / comment / error message"
#   - "find this URL"
#   - "find usages of an env var name"
#   - any time the target isn't a syntactic construct
#
# ══════════════════════════════════════════════════════════════════════════════
# INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════
#
# Related tools in this configuration:
#   - ripgrep.nix: text-level search (use for non-structural queries)
#   - fd.nix: file finding (no syntactic awareness)
#
_: {
  flake.modules.homeManager.ast-grep = {pkgs, ...}: {
    home.packages = [pkgs.ast-grep];
  };
}
