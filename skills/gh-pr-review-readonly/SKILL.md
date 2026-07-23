---
name: gh-pr-review-readonly
description: Review a GitHub pull request from a PR URL and report high-signal findings in chat without posting reviews or comments to GitHub. Use when the user asks for a read-only or non-posting PR review, asks to inspect a PR without leaving comments, or explicitly invokes this skill.
---

# GH PR Review (Read Only)

## Read-only rule

Treat GitHub as read-only. Never submit a review, post an inline or issue comment, resolve a thread, or otherwise mutate the pull request. Do not run `gh pr review`, `gh pr comment`, or a write request through `gh api`. Report all findings only in the response.

## Workflow

1. Parse the GitHub PR URL into `OWNER`, `REPO`, and `PR`.
2. Fetch context before judging code:
   - `gh pr view "$PR_URL" --json title,body,author,baseRefName,headRefName,headRepository,headRepositoryOwner,commits,files,reviews,comments`
   - `gh pr diff "$PR_URL" --patch`
   - Check out the PR if local inspection or tests help: `gh pr checkout "$PR_URL"`.
3. Review only changed behavior unless surrounding code proves the change is unsafe.
4. Prioritize correctness, race/concurrency, security, API compatibility, resource lifetime, test coverage, and maintainability issues. Ignore style and nits unless they cause real cost.
5. Investigate each suspected issue until its failing scenario or violated invariant is concrete. Run relevant tests when practical.
6. Verify the exact file and changed line for every finding. Remove duplicates and low-confidence speculation.
7. Return findings in the response only; do not post anything to GitHub.

## Finding quality bar

Each finding must be:

- Specific: identify the concrete failing scenario or invariant.
- Actionable: state what to change or what test to add.
- Bounded: cover one issue at a time.
- Evidence-based: cite the smallest relevant file and line range from the PR diff.
- Polite and direct.

Do not ask the author to explain code that can be inspected directly. If uncertainty remains after investigation, omit the finding or clearly label the remaining risk and evidence.

## Response format

List findings first, ordered by severity. For each finding, include a short severity-tagged title, the changed `path:line`, the concrete impact, and a concise remediation. Then briefly summarize the reviewed scope and tests run.

If there are no actionable findings, say so explicitly and mention any material testing gaps or residual risks. Do not manufacture findings.
