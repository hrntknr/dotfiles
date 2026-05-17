# OpenCode Instructions

## Complexity & readability
- Prefer the simplest solution that satisfies the requirements and existing constraints.
- Treat excessive lines, moving parts, and incidental complexity as strong negatives.
- Use abstraction only at the right responsibility and granularity; good abstraction separates concerns and makes the code shorter and clearer.
- Match the complexity to the task: small tasks should use small, straightforward changes.
- Optimize for readability: clear naming, small functions, and predictable control flow.

## Comments
- Minimize code comments. Code should be self-explanatory through clear naming and structure.
- Comments are acceptable only for inherently complex logic or externally visible documentation.

## Testing
- Bug fixes must include a regression test:
  - Add a test that fails before the fix and passes after the fix.
  - Place it in the closest relevant test suite.

## Design & debugging
- Avoid heuristic fixes when the failure can be addressed by clearer lifecycle, ownership, or error boundaries.
- Put state and lifecycle logic in the component that semantically owns it; do not duplicate ownership across layers.
- For bugs, inspect actual logs, current files, generated artifacts, and command output before proposing a fix.
- Verify the real end state, not just that code was changed.

## Specifications & reviews
- When important product behavior is ambiguous, ask the smallest necessary clarifying questions before finalizing a specification.
- For reviews, write findings in Japanese, deduplicate overlapping issues, order by severity, and include concrete file/line references and behavioral risk.

## Language
- User-facing responses must use the same language as the instructions used.

## Git operations
- Do not run `git commit`, `git push`, create pull requests, merge pull requests, enable auto-merge, create tags/releases, or otherwise change remote repository state unless the user has explicitly instructed you to in the current context.
- This applies even when changes appear complete or when commit/push/PR operations seem like the natural next step.
- If you believe a Git operation is appropriate, propose it and wait for the user's confirmation before executing.

## Sandbox permissions
- When a command fails due to sandbox restrictions, do not look for workarounds to execute it anyway (e.g., rewriting paths, piping through other tools, or disabling the sandbox).
- Instead, stop and propose to the user that they relax the sandbox requirements (e.g., by updating `settings.json` permissions or adjusting the sandbox configuration).
- Explain which operation was blocked and what permission change would allow it, then wait for the user's decision.

## Libraries
- Prefer using well-known, widely adopted libraries when they simplify the solution, reduce risk, or improve maintainability.
- Do not re-implement common, well-solved functionality that a major library already provides (e.g., parsing, validation, date/time handling, HTTP clients), unless there is a clear constraint (performance, bundle size, security policy, dependency restrictions).
- Keep dependencies minimal: introduce a new library only when it provides clear value over standard library or existing dependencies.
- When adding a library, choose a stable option with strong community support and maintenance.

## Slop code
- Avoid unnecessary defensive coding, premature abstraction, cargo-cult patterns, verbose boilerplate, hollow comments, speculative features, and over-logging.

When in doubt, write less code. Every line should exist for a reason traceable to the actual requirement.
