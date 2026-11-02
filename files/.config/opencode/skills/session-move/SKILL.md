---
name: session-move
description: Move an OpenCode session to a different directory and continue working there. Use when a user asks to change a session's registered directory/location, move a session to another project or a git worktree, or switch the working folder while keeping the conversation context.
compatibility: opencode
---

# Session Move

## Overview

Move a session to another directory. The session is re-registered under the new directory, the working directory follows, and the conversation context is preserved.

## How to move

Preferred: use the `session_move` tool (in Code Mode, `tools.opencode.session_move`).

- Omit `sessionID` to move the current session.
- `directory` accepts an absolute path, a path relative to the session's directory, or `~`.

```js
await tools.opencode.session_move({ directory: "/path/to/target" });
```

Alternative: call the HTTP API from the shell.

```sh
opencode api post /api/session/<sessionID>/move --data '{"directory": "/path/to/target"}'
```

## Notes

- The `opencode session` CLI has no move subcommand (only list, delete, export, import).
- Verify the target directory exists before moving. Locate it by name if needed, e.g. `find /home "$HOME" -maxdepth 6 -type d -name '<name>*'`.
- Typical use: create a git worktree, then move the session to the worktree path to continue there.
