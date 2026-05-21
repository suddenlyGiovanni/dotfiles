# yq - Portable command-line YAML processor
# https://github.com/mikefarah/yq
# https://mikefarah.gitbook.io/yq/
#
# ══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ══════════════════════════════════════════════════════════════════════════════
#
# yq is the YAML equivalent of jq. It's the Go implementation by Mike Farah,
# selected over the Python `yq` (which wraps jq) because it's:
#   - Single-binary, no Python runtime dependency
#   - YAML-native (round-trips comments, anchors, ordering)
#   - The de-facto standard in the kubernetes / helm / GitHub Actions
#     ecosystems, which means agent ecosystem tooling expects this binary
#
# Why this matters for AI coding agents:
#   - This machine has lots of YAML: GitHub Actions workflows, kubernetes
#     manifests, helm charts, docker-compose files, MkDocs configs
#   - Until now an agent shelling into a YAML pipeline had to fall back to
#     awk / sed / regex hacks, which corrupt comments and ordering
#   - yq lets the agent query and patch YAML structurally:
#       yq '.jobs.build.runs-on'           workflow.yml
#       yq -i '.spec.replicas = 3'         deployment.yml
#       yq 'explode(.)'                    chart-with-anchors.yml
#
# ══════════════════════════════════════════════════════════════════════════════
# USAGE
# ══════════════════════════════════════════════════════════════════════════════
#
#   yq '.path.to.value' file.yml         Read a path
#   yq -i '.path = "new"' file.yml       Write a path in place
#   yq -o json '.' file.yml              Convert YAML → JSON
#   yq -p json -o yaml '.' file.json     Convert JSON → YAML
#   yq -p toml -o yaml '.' Cargo.toml    TOML → YAML (read-only)
#   yq 'explode(.)' file.yml             Resolve YAML anchors / aliases
#   yq '... comments=""' file.yml        Strip all comments
#   yq -n '{"a": 1}'                     Build YAML from scratch
#
# ── Examples ─────────────────────────────────────────────────────────────────
#
#   # Bump every container image tag in a kustomization to a new sha
#   yq -i '.images[].newTag = "abc123"' kustomization.yml
#
#   # List all jobs in a GitHub Actions workflow
#   yq '.jobs | keys' .github/workflows/ci.yml
#
#   # Convert a docker-compose service to JSON for jq processing
#   yq -o json '.services.api' docker-compose.yml
#
#   # Merge override on top of base values
#   yq '. *= load("override.yml")' values.yml
#
# ══════════════════════════════════════════════════════════════════════════════
# WHEN TO USE YQ vs JQ vs SED
# ══════════════════════════════════════════════════════════════════════════════
#
# Use yq when the file is YAML / TOML / JSON-in-YAML and you need to:
#   - Read a nested path
#   - Patch a value while preserving comments, anchors, and key order
#   - Convert between YAML and JSON
#
# Use jq when the file is JSON-only — jq is faster and has the larger
# query-language surface.
#
# Use sed / awk only when the structural tools can't handle the file
# (legacy / corrupt / non-conforming YAML).
#
# ══════════════════════════════════════════════════════════════════════════════
# INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════
#
# Related tools in this configuration:
#   - jq (in home-core.nix): JSON processor; pipe `yq -o json` into it for
#     YAML → jq pipelines.
#
_: {
  flake.modules.homeManager.yq = {pkgs, ...}: {
    home.packages = [pkgs.yq-go];
  };
}
