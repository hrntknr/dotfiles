---
name: pr-review
description: Review a GitHub pull request by inspecting the diff locally and with GitHub CLI, then use the reviewer subagent to identify merge-blocking issues or approve the change.
---

# PR Review

## Overview

Review a GitHub pull request with `gh`, local git, and the `reviewer` subagent. Focus on concrete issues that materially affect correctness, performance, security, or maintainability.

## Workflow

1. Identify the target PR.
   - If the user did not provide a PR number, run `gh pr list --assignee @me --state open`.
   - Ask the user which PR to review if multiple plausible PRs are returned.
2. Prepare the local branch safely.
   - Run `git status --short` first.
   - If there are local changes that would be disturbed by checkout, stop and ask the user how to proceed.
   - Check out the PR branch with `gh pr checkout <pr_number>` or an equivalent safe command.
3. Inspect the PR context.
   - Run `gh pr view <pr_number> --json number,title,body,baseRefName,headRefName`.
   - Review the diff with `gh pr diff <pr_number>`.
   - Read any local files needed to understand the changed behavior.
4. Use the `reviewer` subagent to review the change.
   - Provide the PR number, title, summary, diff context, and any relevant local code context.
   - Ask it to apply the local `reviewer` instructions.
5. Return the review result.
   - Surface every `🔴 Normal` issue as merge-blocking.
   - Include `🟡 Nit` issues only when they are worth fixing but not blocking.
   - Mention `🟣 Pre-existing` issues separately from newly introduced issues.
   - If there are no qualifying issues, approve the change clearly.

## Notes

- Do not report speculative issues.
- Prefer no findings over weak findings.
- Keep the final review concise and focused on issues the author would likely fix.
