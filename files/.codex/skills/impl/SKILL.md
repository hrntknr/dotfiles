---
name: impl
description: Implement changes from a provided Markdown issue/requirements file, then review the implementation for major issues and iterate until the review passes. Use when the user wants a workflow that takes an .md file path as input, applies code changes based on the file contents, and performs a self-review loop.
---

# Impl

## Overview

Implement based on a Markdown file (issue/requirements) and run a self-review loop that blocks on major issues until the review is clean.

## Workflow

1. **Read the Markdown input**

   - Open the file path the user provides.
   - Extract: problem statement, expected vs actual behavior, repro steps, acceptance criteria, constraints, and affected components.
   - If critical details are missing, ask focused questions before coding.

2. **Interview for missing requirements (if needed)**

   - Ask only what is necessary to proceed safely.
   - Prefer short, targeted questions; avoid long questionnaires.
   - Example questions:
     - "What is the expected behavior in this edge case?"
     - "Which environment/versions should this support?"
     - "Are there constraints on dependencies or configs?"
     - "Is there an acceptance test or repro script to use?"

3. **Implement the change**

   - Identify the minimal set of files to touch.
   - Apply changes that directly satisfy the Markdown requirements.
   - Prefer small, safe diffs; add tests if the change warrants it.
   - Keep edits aligned with the repo's conventions.

4. **Run a review pass (major issues only)**

   - Check for correctness, edge cases, regressions, and missing requirements.
   - Validate error handling and failure modes.
   - Flag missing tests only if they create real risk.
   - Do not nitpick style; focus on impactful issues.

5. **Iterate until review passes**
   - If review finds major issues, implement fixes and re-review.
   - Repeat until the review has no major findings.
   - Summarize the final changes and any remaining risks.

## Review Checklist (Major Issues)

- Requirement mismatch or missing acceptance criteria
- Incorrect control flow or logic errors
- Broken error handling, resource leaks, or unsafe behavior
- Incomplete integration (e.g., feature added but not wired up)
- Tests needed to prevent regressions in critical paths

## Output Expectations

- Provide a concise change summary.
- List any tests run or suggest tests if none were run.
- If clarifications are needed, ask targeted questions.
