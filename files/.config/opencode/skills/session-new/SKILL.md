---
name: session-new
description: Create a new OpenCode session and give it an initial instruction, without carrying over the current conversation context. Use when a user asks to start a fresh session, fork into a clean context, hand a task to a separate session, or instruct a new session from scratch.
compatibility: opencode
---

# Session New

## Overview

Create a brand-new session and send it an instruction. Like a fork, but with no shared history: the new session starts empty and receives only the instruction text. The calling session is not blocked; the new session's agent loop runs on its own.

## How to create and instruct

1. Create the session with an explicit working directory (and optionally a title):

```sh
opencode api post /api/session --data '{"location":{"directory":"/path/to/workdir"},"title":"...","model":{"providerID":"...","id":"..."}}'
```

The response contains the new session ID: `{"data":{"id":"ses_...","location":{...},...}}`.

2. Send the instruction:

```sh
opencode api post /api/session/<sessionID>/prompt --data '{"text":"..."}'
```

## Notes

- The instruction must be self-contained. The new session has none of the caller's conversation context, so include the working directory, relevant file paths, the task, and constraints in the `text`.
- Always set `location.directory` explicitly. Omitting `location` registers the session under an unpredictable default (e.g. the caller's home), not the current project.
- Do not set `parentID` and do not use the fork endpoint (`POST /api/session/{sessionID}/fork`); both link or carry context. This skill's purpose is a clean start.
- Always pin the model explicitly with `"model":{"providerID":"...","id":"..."}` at creation. Do not rely on the config default: with no `model` in config, the default can resolve to a provider/model combination the provider rejects, and the new session fails on its first request with no one watching (observed: `model_not_found`). Use the calling session's current model, which is known to work; otherwise pick an exact ID from `opencode api get /api/model`. The `id` may itself contain the `provider/model` string (e.g. `{"providerID":"pfcp","id":"z-ai/glm-5.3"}`).
- To pick an agent, pass `"agent":"<agentID>"` at creation. List agents with `opencode api get /api/agent`.
- `prompt` is asynchronous. To wait for completion, poll or block with the wait endpoint, then read the messages (newest first):

```sh
opencode api post /api/experimental/session/<sessionID>/wait   # 204 when idle
opencode api get /api/session/<sessionID>/message
```

- To open the new session interactively, run `opencode` in the target directory and select the session (title or the listed session picker), e.g. `opencode session list` to confirm its ID.
