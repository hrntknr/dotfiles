---
name: ask-codex
description: Ask a question to Codex CLI non-interactively via `codex exec`. Use when the user wants a second opinion, wants to delegate a question, or wants to leverage Codex's tools.
---

# Ask Codex

Delegate a question or task to Codex CLI using `codex exec`.

## Workflow

1. Build the prompt from the user's request.
   - If the user provided a specific question or instruction, use it as-is.
   - If the user referenced files or context, include relevant details in the prompt.
2. Choose flags.
   - Always use `--full-auto` and `--ephemeral`.
   - Use `-o <tmpfile>` to capture the response cleanly.
   - Add `--skip-git-repo-check` if running outside a git repo.
   - Add `-i <file>` if the user attached images.
3. Run `codex exec`.
   ```
   codex exec --full-auto --ephemeral -o /tmp/codex-ask-out.txt "<prompt>"
   ```
4. Read the output file and return the result to the user.
   - Present the response as Codex's answer, clearly attributed.

## Notes

- The prompt is a positional argument, not a named flag.
- For long prompts, pipe via stdin: `echo "<prompt>" | codex exec --full-auto --ephemeral -o /tmp/codex-ask-out.txt -`.
- Codex has access to the current repository and can run shell commands, so it can answer questions about the codebase.
- Set a reasonable timeout (e.g., 120s) to avoid hanging on complex tasks.
