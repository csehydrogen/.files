---
name: gh-pr-review
description: Review a GitHub pull request from a PR URL and leave high-signal, resolvable inline review comments. Use when the user asks to review a PR, inspect a PR URL, perform code review, or leave comments on changed lines; prefer GitHub PR review/diff comments rather than general issue comments so each finding can be resolved in the PR UI.
---

# GH PR Review

## Workflow

1. Parse the GitHub PR URL into `OWNER`, `REPO`, and `PR`.
2. Fetch context before judging code:
   - `gh pr view "$PR_URL" --json title,body,author,baseRefName,headRefName,headRepository,headRepositoryOwner,commits,files,reviews,comments`
   - `gh pr diff "$PR_URL" --patch`
   - Check out the PR if local inspection/tests help: `gh pr checkout "$PR_URL"`.
3. Review only changed behavior unless surrounding code proves the change is unsafe.
4. Prefer finding correctness, race/concurrency, security, API compatibility, resource lifetime, test coverage, and maintainability issues. Do not comment on style/nits unless they cause real cost.
5. For every finding, verify the exact file and changed line are commentable in the PR diff.
6. Leave comments as GitHub pull request review comments, not normal PR issue comments, so they are resolvable.
7. Finish with a short summary of what was reviewed and comments left.

## Comment quality bar

Each comment must be:

- Specific: identify the concrete failing scenario or invariant.
- Actionable: state what to change or what test to add.
- Bounded: one issue per comment thread.
- Polite and direct.
- Resolvable: attached to the smallest relevant changed line.

Avoid comments that merely ask the author to explain code you can inspect yourself. If uncertain, do more local investigation first; if still uncertain, phrase as a risk with the evidence.

## Posting resolvable comments

Prefer batching comments into one review when possible. First identify the PR head SHA:

```bash
gh pr view "$PR_URL" --json commits --jq '.commits[-1].oid'
```

Use one of these approaches:

### Batch review comments

Create a review with `event: COMMENT` and a `comments` array. Use line-based fields for changed lines:

```bash
gh api \
  --method POST \
  -H 'Accept: application/vnd.github+json' \
  "/repos/$OWNER/$REPO/pulls/$PR/reviews" \
  -f event='COMMENT' \
  -f body='Review comments.' \
  -F comments='[{"path":"path/file.py","line":123,"side":"RIGHT","body":"..."}]'
```

If `-F comments=...` is awkward, write JSON to a temp file and use `--input file.json`.

### Single inline comment

```bash
gh api \
  --method POST \
  -H 'Accept: application/vnd.github+json' \
  "/repos/$OWNER/$REPO/pulls/$PR/comments" \
  -f body='...' \
  -f commit_id="$HEAD_SHA" \
  -f path='path/file.py' \
  -F line=123 \
  -f side='RIGHT'
```

Use `side: LEFT` only when commenting on removed/base-side lines. For multi-line comments, include `start_line`, `line`, `start_side`, and `side` only when GitHub accepts the selected range.

## Validation before posting

Before calling `gh api` to post comments:

- Re-open the patch hunk and confirm each `path` + `line` exists on the diff side.
- Remove duplicate comments and low-confidence speculation.
- If there are no review-worthy issues, do not manufacture comments; report that no actionable findings were found.
