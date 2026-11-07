# OpenCode Instructions

## Complexity & readability
- Prefer the simplest solution that satisfies the requirements and existing constraints, with complexity matched to the size of the task.
- Optimize for readability: clear naming, small functions, and predictable control flow.
- Treat excessive lines, moving parts, and incidental complexity as strong negatives.
- Use abstraction only at the right responsibility and granularity; good abstraction separates concerns and makes code shorter and clearer.
- Avoid slop: unnecessary defensive coding, cargo-cult patterns, verbose boilerplate, hollow comments, speculative features, and over-logging.
- When in doubt, write less code. Every line should exist for a reason traceable to the actual requirement.

## Comments
- Minimize code comments; code should be self-explanatory through clear naming and structure.
- Use comments only for inherently complex logic or externally visible documentation.

## Testing
- Bug fixes must include a regression test that fails before the fix and passes after it, placed in the closest relevant test suite.

## Design & debugging
- Avoid heuristic fixes when the failure can be addressed by clearer lifecycle, ownership, or error boundaries.
- Put state and lifecycle logic in the component that semantically owns it; do not duplicate ownership across layers.
- For bugs, inspect actual logs, current files, generated artifacts, and command output before proposing a fix.
- Verify the real end state, not just that code was changed.

## Delegation
- Execute all tasks via the `general` subagent instead of handling them inline in the main session.
- Always launch subagents with `background: true`. Never use blocking foreground calls; to sequence dependent scopes, launch the next subagent after the previous result notification arrives.
- Before delegating, split the work into independent scopes — topics, modules, or steps that do not depend on each other's results and do not touch the same files — and launch one `general` subagent per scope in parallel, keeping working while they run.
- Delegate sequentially only when a later scope needs the results of an earlier one; never serialize independent work just because it arrived in one request.
- Reserve the main session for work that needs the full conversation context: reviewing subagent results and making the final edits.

## Specifications & reviews
- When important product behavior is ambiguous, ask the smallest necessary clarifying questions before finalizing a specification.
- Write review findings in Japanese, deduplicated, ordered by severity, with concrete file/line references and behavioral risk.

## Language
- User-facing responses must use the same language as the instructions used.
- When responding in Japanese, always use the `humanizer` skill to format your output into natural, readable prose.

## Git operations
- Do not run `git commit`, `git push`, create or merge pull requests, enable auto-merge, create tags/releases, or otherwise change remote repository state unless the user has explicitly instructed you to in the current context.
- This applies even when the operation seems like the natural next step; in that case, propose it and wait for confirmation.

## Sandbox permissions
- When a command fails due to sandbox restrictions, do not work around it — instead, propose relaxing the configuration (e.g., updating `settings.json` permissions), explain which operation was blocked and what change would allow it, and wait for the user's decision.

## Libraries
- Prefer well-known, widely adopted libraries with strong community support when they simplify the solution, reduce risk, or improve maintainability.
- Do not re-implement common, well-solved functionality that a major library already provides (parsing, validation, date/time handling, HTTP clients) unless there is a clear constraint (performance, bundle size, security policy, dependency restrictions).
- Keep dependencies minimal: introduce a library only when it provides clear value over the standard library or existing dependencies.
