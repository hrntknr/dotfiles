---
name: review-codex
description: Review code changes by invoking Codex CLI's review command. Use for non-trivial scopes or final review of implementation work via Codex.
---

# Review (Codex)

Review code changes by delegating to `codex review`.

## Workflow

1. Determine the review target.
   - If reviewing uncommitted changes: use `--uncommitted`.
   - If reviewing against a base branch: use `--base <branch>`.
   - If reviewing a specific commit: use `--commit <sha>`.
2. Run `codex review` with the appropriate flags.
   - Pass custom review instructions as the prompt argument when additional context is needed.
3. Return the review output to the user.
   - Surface `🔴 Normal` findings as blocking.
   - Include `🟡 Nit` findings when worth fixing but not blocking.
   - Mention `🟣 Pre-existing` findings separately.

## Notes

- Default to `--uncommitted` when the user does not specify a target.
- Keep the review prompt concise; Codex uses its own reviewer instructions from `.codex/`.
