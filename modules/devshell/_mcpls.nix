# mcpls: an MCP-to-LSP bridge. It gives an agent a language server's findings,
# fixes and navigation as MCP tools (.mcp.json, config: .claude/mcpls.toml).
# https://github.com/bug-ops/mcpls
#
# nixpkgs has no mcpls, so this installs the upstream release binary. Remove it
# once nixpkgs packages mcpls. Called from flake.nix (devShells.default); the
# leading `_` keeps import-tree from loading it as a module.
#
# Refresh the hash, then compare it with the release's published digest
# (`mcpls-aarch64-apple-darwin.tar.gz.sha256` beside the asset):
#   nix store prefetch-file --json \
#     "https://github.com/bug-ops/mcpls/releases/download/v${version}/mcpls-aarch64-apple-darwin.tar.gz"
{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mcpls";
  version = "0.7.0";

  src = fetchurl {
    url = "https://github.com/bug-ops/mcpls/releases/download/v${finalAttrs.version}/mcpls-aarch64-apple-darwin.tar.gz";
    hash = "sha256-FnYcdLQUjA4vf8+ruNU1dteup+S53UrlRD30QI5dMEs=";
  };

  # The tarball holds the binary at its top level, with no directory around it.
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 mcpls $out/bin/mcpls
    runHook postInstall
  '';

  meta = {
    description = "MCP to LSP bridge: language-server diagnostics, code actions and navigation as MCP tools";
    homepage = "https://github.com/bug-ops/mcpls";
    changelog = "https://github.com/bug-ops/mcpls/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    platforms = ["aarch64-darwin"];
    mainProgram = "mcpls";
  };
})
