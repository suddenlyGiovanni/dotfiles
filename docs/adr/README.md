# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) documenting significant decisions made
in this dotfiles configuration.

## What is an ADR?

An ADR is a document that captures an important architectural decision made along with its context
and consequences. They help future-you (and others) understand:

- **Why** a decision was made
- **What** alternatives were considered
- **When** the decision was made
- **What** the consequences are

## ADRs

| ID                                               | Title                                | Status   | Date    |
| ------------------------------------------------ | ------------------------------------ | -------- | ------- |
| [001](./001-multi-machine-nix-configuration.md)  | Multi-Machine Nix Configuration      | Accepted | 2025-01 |
| [002](./002-xdg-compliance-session-variables.md) | XDG Compliance and Session Variables | Accepted | 2025-01 |
| [003](./003-nix-lsp-maintainability-tradeoff.md) | Nix LSP Maintainability Trade-off    | Accepted | 2025-01 |
| [004](./004-developer-directory-structure.md)    | Developer Directory Structure        | Accepted | 2025-01 |
| [005](./005-home-manager-module-structure.md)    | Home-Manager Module Structure        | Accepted | 2026-01 |

## Creating a New ADR

1. Copy the template below
2. Create a new file: `NNN-title-with-dashes.md`
3. Fill in the sections
4. Add an entry to the table above

## Template

```markdown
# ADR-NNN: Title

## Status

Proposed | Accepted | Deprecated | Superseded by [ADR-XXX](./XXX-title.md)

## Date

YYYY-MM-DD

## Context

What is the issue that we're seeing that is motivating this decision or change?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive

- ...

### Negative

- ...

### Neutral

- ...

## Alternatives Considered

What other options were considered and why were they not chosen?

## References

- Links to relevant resources, discussions, or documentation
```
