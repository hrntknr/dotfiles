# Codex Instructions

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
