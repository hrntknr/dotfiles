---
name: impl
description: Incremental implementation workflow for non-trivial code changes. Use when a feature or fix needs planning, verification, and review.
---

# impl

Use this workflow to execute implementation tasks in small, verifiable steps.

## Workflow

1. Understand the request and inspect the relevant code first.
   - Confirm the exact behavior to change.
   - Identify constraints, risks, and affected files.
   - Ask the user only when a missing detail would make a reasonable implementation risky.
2. Break the work into small, independently verifiable scopes.
   - Prefer scopes that can be implemented and tested in isolation.
   - Order scopes by dependency and risk.
   - For substantial tasks, keep the active plan updated.
3. Use a `developer` subagent to implement one scope at a time.
   - Give the subagent a concrete scope, affected files, constraints, and expected tests.
   - Keep ownership clear when delegating parallel work.
   - Ask the subagent to follow existing patterns, avoid unnecessary complexity, use test-driven development, and add sufficient test coverage.
4. Verify the implemented scope locally.
   - Review the returned changes before accepting them.
   - Run the most relevant tests and checks for the changed behavior.
   - Fix failures before expanding scope.
5. Use a `reviewer` subagent for non-trivial scopes or final review.
   - Ask for review focused on concrete bugs, regressions, unnecessary complexity, pattern/style deviations, and missing tests.
   - Treat `🔴 Normal` findings as blocking and address them before continuing.
   - Address `🟡 Nit` findings when the fix is low-cost and clearly improves the change.
   - Do not treat `🟣 Pre-existing` findings as blockers for the current scope, but surface them in the final summary when relevant.
6. Repeat the develop -> verify -> review cycle for each remaining scope.
   - Keep scopes small enough that failures and review findings stay easy to localize.
7. Finish with full validation and a concise summary.
   - Ensure the final test/check set relevant to the request passes.
   - Summarize what changed, how it was verified, and any remaining risk.

## Rules

- Complete exactly what the user asked for at 100% completion; do not stop partway through the requested work.
- Prefer direct code inspection over assumptions.
- Preserve existing code patterns and style unless the task requires a deliberate change.
- Use test-driven development when practical.
- Add sufficient coverage for changed behavior, including regression tests when applicable.
- Use subagents for implementation and review when the task is large enough to benefit from delegation.
- Do not delegate the immediate blocking task if you need the answer locally to make the next decision.
- Do not leave the task half-finished if you can complete it within the turn.
- Escalate to the user when requirements conflict, unexpected local changes block the work, or the safe next step is unclear.
