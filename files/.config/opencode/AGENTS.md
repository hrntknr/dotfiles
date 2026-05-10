# OpenCode Instructions

## Complexity & readability
- Do not increase complexity without a clear reason.
- Prefer the simplest solution that satisfies the requirements and existing constraints.
- Complexity is allowed only when it reduces overall risk or improves maintainability (e.g., removes duplication, clarifies invariants, improves testability).
- Match the complexity to the task: small tasks should use small, straightforward changes.
- Separate modules with appropriate granularity.
- Optimize for readability: clear naming, small functions, and predictable control flow.

## Comments
- Minimize code comments. Code should be self-explanatory through clear naming and structure.
- Comments are acceptable only when:
  - The logic is inherently complex and not self-evident from the code.
  - The comment is externally visible (e.g., doc comments for public APIs, docstrings).

## Testing
- Bug fixes must include a regression test:
  - Add a test that fails before the fix and passes after the fix.
  - Place it in the closest relevant test suite.

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
"Slop code" refers to AI-generated code that is syntactically valid but bloated, vague, or mechanically produced without genuine understanding of the problem. Avoid the following patterns:
- Unnecessary defensive coding: redundant null checks, try-catch wrapping, or validation for conditions that cannot occur in context.
- Premature abstraction: introducing helpers, wrappers, factories, or config layers for one-time or straightforward operations.
- Cargo-cult patterns: applying design patterns (strategy, observer, builder, etc.) without a concrete need, simply because they seem "proper."
- Verbose boilerplate: generating repetitive code that could be expressed more concisely, or adding layers of indirection that obscure intent.
- Hollow comments and docstrings: restating what the code already says (e.g., `# increment counter` above `counter += 1`) or adding filler documentation with no informational value.
- Speculative features: adding error handling, feature flags, configuration options, or extensibility hooks that were not requested and have no foreseeable use.
- Over-logging and over-typing: inserting excessive log statements or type annotations that add noise without aiding debugging or comprehension.

When in doubt, write less code. Every line should exist for a reason traceable to the actual requirement.
