---
name: gh-pr-address-reviews
description: Inspect reviews and review threads on a GitHub pull request from a PR URL, treat comments from the current GitHub identity or previous agents as valid feedback, propose an address plan before editing code, and after explicit user approval implement fixes, push changes, and resolve addressed PR review threads. Use when the user asks to rebut, address, handle, fix, or resolve PR review comments.
---

# GH PR Address Reviews

## Required interaction contract

1. Inspect the PR reviews and review threads first.
2. Treat review comments written by the current GitHub account as relevant; prior agents may have used the same identity. Do not ignore feedback only because `author.login` matches `gh api user`.
3. Produce an address plan before editing code. Include which comments will be fixed, rejected, or need clarification and why.
4. Stop after the plan and wait for explicit user approval such as "proceed" before editing, committing, pushing, or resolving threads.
5. After approval, implement the plan, run appropriate validation, push the branch, and resolve only threads actually addressed.

## Inspecting reviews

Parse the PR URL into `OWNER`, `REPO`, and `PR`, then gather context:

```bash
gh pr view "$PR_URL" --json title,body,author,baseRefName,headRefName,headRepository,headRepositoryOwner,commits,files,reviews,comments,reviewDecision
```

Fetch review comments:

```bash
gh api "/repos/$OWNER/$REPO/pulls/$PR/comments" --paginate
```

Fetch resolvable review threads with GraphQL:

```bash
gh api graphql -f owner="$OWNER" -f repo="$REPO" -F number="$PR" -f query='\
query($owner:String!, $repo:String!, $number:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) {
      reviewThreads(first:100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first:20) {
            nodes {
              id
              author { login }
              body
              createdAt
              url
            }
          }
        }
      }
    }
  }
}'
```

If there are more than 100 threads or comments, paginate before planning.

## Address plan format

Before code edits, respond with:

- PR summary: title, branch, and scope.
- Threads/comments found: grouped by file and thread URL or ID.
- Proposed action for each thread:
  - **Fix**: concrete code/test change.
  - **No change**: why the comment is invalid or already addressed.
  - **Clarify**: question to ask before editing.
- Validation plan: tests/builds/lints to run.
- Push/resolve plan: branch to push and which thread IDs should be resolved after successful validation.

Do not modify files before this plan unless the user already explicitly approved in the same request.

## Implementing after approval

1. Check out the PR branch: `gh pr checkout "$PR_URL"`.
2. Apply the approved code/test/doc changes.
3. Run targeted validation first, then broader validation if risk warrants it.
4. Commit only if the workflow requires a local commit; otherwise leave changes staged/unstaged according to the repository norm. When committing, do not add co-authors.
5. Push to the PR branch.
6. Resolve only threads whose requested change is actually addressed and pushed.
7. Reply with the pushed commit/branch, validation results, and resolved/unresolved thread list.

## Resolving review threads

Resolve threads through GraphQL after fixes are pushed:

```bash
gh api graphql -f thread_id="$THREAD_ID" -f query='\
mutation($thread_id:ID!) {
  resolveReviewThread(input:{threadId:$thread_id}) {
    thread { id isResolved }
  }
}'
```

If a thread should remain open, leave it unresolved and explain why. If GitHub rejects the mutation due permissions or stale IDs, report the failure and include the thread URL.

## Safety rules

- Never resolve a thread just because it is outdated; check whether the concern is addressed.
- Never force-push unless the user explicitly approves and the repository workflow expects it.
- If validation fails, do not resolve related threads unless the failure is unrelated and explained.
- If a review comment requests a design/product decision, ask before making a broad change.
