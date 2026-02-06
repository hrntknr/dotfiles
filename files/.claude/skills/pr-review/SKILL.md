---
name: pr-review
description: Review GitHub pull requests by inspecting changes locally and via GitHub CLI, then report only critical merge-blocking issues (bugs, performance, security, correctness) or approve.
---

# PR Review

## Overview
This skill reviews a GitHub Pull Request (PR) using GitHub CLI (`gh`) and local git. It focuses strictly on **critical** issues that must be addressed before merging:
- Potential bugs or issues
- Performance
- Security
- Correctness

The final response must be concise:
- If critical issues exist: list them in a few short bullet points, then sign off with **☑️ (issues found)**.
- If none: provide a simple approval, then sign off with **☑️ (approved)**.

Do **not** include minor style/nit suggestions unless they materially affect performance, security, or correctness.

---

## Preconditions
- `gh` is authenticated and has access to the repo.
- You are in the correct repository working directory.

---

## Workflow

### 1) Identify the PR number (if not provided)
If the user did **not** provide a PR number:
1. Run:
   ```bash
   gh pr list --assignee @me --state open
   ```

2. Present the user with clear options (PR number + title + branch), and ask which PR to review.

If the user provided a PR number already, skip this step.

---

### 2) Check out the target branch

Before checking out the PR branch, verify there are no uncommitted changes:

```bash
git status
```

Determine the PR’s head branch (via `gh pr view` or the PR list output), then:

```bash
git checkout {branch}
```

* If checkout fails, report the failure and stop.

---

### 3) Inspect the PR diff

Review the full diff using:

```bash
gh pr diff {pr_number}
```

If necessary, you can refer to the code and check parts that are not included in the diff.

Please analyze the changes in this PR and focus on identifying critical issues related to:

- Potential bugs or issues
- Performance
- Security
- Correctness

If critical issues are found, list them in a few short bullet points. If no critical issues are found, provide a simple approval.
Sign off with a checkbox emoji: ✅ or ⚠️.

Keep your response concise. Only highlight critical issues that must be addressed before merging. Skip detailed style or minor suggestions unless they impact performance, security, or correctness.
