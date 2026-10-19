---
paths:
  - 'CLAUDE.md'
  - '.mcp.json'
  - '.agents/**'
  - '.claude/**'
  - '.claude-plugin/**'
  - '.opencode/**'
---

# Agent tooling

- **Shared or harness-specific**. A file that every harness can read goes in `.agents/`. A file in
  the format of one harness goes in that harness's folder (`.claude/`, `.opencode/`), and links to
  `.agents/` for the rest. [.agents/README.md](../README.md) maps each piece. Update the map when
  you add a piece.
- **Edit the target, not the link**. `CLAUDE.md` links to `AGENTS.md`, and `.claude/rules` and
  `.claude/agents` link into `.agents/`. The Edit and Write tools do not write through a symlink.
  Edit the file that the link points to.
- **One server list, in four places**. The devshell (`flake.nix`), the Claude Code plugin
  (`.claude/plugins/dotfiles-lsp/.lsp.json`), the OpenCode `lsp` key and `.agents/mcpls.toml` each
  name the language servers. When you add or remove a server, change all four. (`.agents/mcpls.toml`
  leaves Lua out on purpose; its comment says why.)
- **Release the plugin**. Claude Code caches a plugin by its version, and installs it from the
  committed HEAD. Bump `version` in `plugin.json` when you change the plugin. The change takes
  effect after the commit, in a new session.
- **Hooks are nu, and speak Claude Code's protocol**. Each hook reads its JSON payload on stdin
  (`nu --stdin`).
  - To deny a PreToolUse call, print `hookSpecificOutput.permissionDecision: "deny"` with
    `permissionDecisionReason`, and exit 0.
  - To send a Stop back, print `{"decision": "block", "reason": …}`. Always honour
    `stop_hook_active`.
  - `CLAUDE_ENV_FILE` is shared between hooks, so append to it. Claude Code clears it on every
    CwdChanged event.
- **Test a hook before you rely on it**. Pipe a sample payload into it:
  `{tool_name: Bash, tool_input: {command: 'just build'}} | to json | nu --stdin .claude/hooks/pre-tool-use.nu`.
  Check both an allowed case and a denied case.
