# Claude Instructions

## Complexity & readability
- Do not increase complexity without a clear reason.
- Prefer the simplest solution that satisfies the requirements and existing constraints.
- Complexity is allowed only when it reduces overall risk or improves maintainability (e.g., removes duplication, clarifies invariants, improves testability).
- Match the complexity to the task: small tasks should use small, straightforward changes.
- Optimize for readability: clear naming, small functions, and predictable control flow.

## Testing
- Bug fixes must include a regression test:
  - Add a test that fails before the fix and passes after the fix.
  - Place it in the closest relevant test suite.

## Language
- User-facing responses must use the same language as the instructions used.

### Libraries
- Prefer using well-known, widely adopted libraries when they simplify the solution, reduce risk, or improve maintainability.
- Do not re-implement common, well-solved functionality that a major library already provides (e.g., parsing, validation, date/time handling, HTTP clients), unless there is a clear constraint (performance, bundle size, security policy, dependency restrictions).
- Keep dependencies minimal: introduce a new library only when it provides clear value over standard library or existing dependencies.
- When adding a library, choose a stable option with strong community support and maintenance; document the reason briefly (e.g., in a comment, PR description, or dependency note).
