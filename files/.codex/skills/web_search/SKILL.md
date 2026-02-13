---
name: web_search
description: Research and fact-check current information with concise, evidence-aware outputs. Use when tasks require latest updates, comparisons, recommendations, policy or pricing checks, statistics, schedules, or any claim that should be verified with concrete dates and selective source citation.
---

# Research

Execute research with verifiable evidence and clear uncertainty handling.

## Workflow

1. Run a quick search first.
   - Clarify only essential scope (topic, region, timeframe).
   - Convert relative time words to absolute dates only when time-sensitive.
2. Use 1-2 high-quality sources to draft the answer fast.
   - Prefer official or primary sources when easy to access.
   - Do not explore local files unless the user asks.
3. Escalate only if needed.
   - Add extra sources only for high-stakes claims, conflicting data, or user request.
4. Respond directly and briefly.
   - Keep only the most decision-relevant facts.
   - Note uncertainty in one short line when needed.

## Source Selection

Use `references/source-playbook.md` only when source quality is unclear or the topic is high-stakes.

## Output Contract

Use Markdown for readability (short paragraphs and bullets).
Avoid heavy section splitting unless the user explicitly asks for it.
Start with a very short conclusion sentence.
Immediately follow with concise supporting explanation and cite sources in-text as (ref1), (ref2), ... at the relevant claims.
At the end, provide a compact References list that maps each ref id to [title](url).
Keep links selective: include them only where they materially improve trust, verify high-stakes points, or were requested by the user.
Always include concrete dates for time-sensitive claims.

## Failure Handling

If reliable sources are missing or blocked:

1. Say what was attempted.
2. State exactly what remains unverified.
3. Give the minimal next search path needed to close the gap.
