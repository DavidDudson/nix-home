---
name: pickup
description: >
  Pick up an in-progress branch or PR in any repo. Checks it out, updates it to
  the latest main, resolves conflicts, then fixes the red CI builds the branch
  caused, leaving alone failures that are also red on main. Use when the user
  says "pickup", "pick up #n", "continue this PR", "update this branch", "fix
  the red builds", or "what was I doing".
argument-hint: "[pr-number | branch]"
---

# Pick up a branch

A repo's own `pickup` skill in its `.claude/skills/` takes precedence over this
one inside that repo.

## 1. Find and check out the branch

- **Argument:** a PR number or branch name.
- **No argument:** the current branch if it is not the default branch. Otherwise
  list candidates (`ws status` in a ws workspace, then
  `gh pr list --author "@me" --state open`) and ask which, unless one is clearly
  the most recent.

Inside a ws workspace (`$WS_NAME` set), change branch only with
`ws checkout <repo> <branch>` or `ws checkout <repo> #<pr>`, never with plain
git branch switching or `gh pr checkout`. If `ws checkout` refuses because
another workspace claims the branch, stop and tell the user. Outside ws, use
`gh pr checkout <pr>`.

Rebuild context: `gh pr view <pr> --comments`, `git log origin/<default>..HEAD`,
and the repo's `CLAUDE.md` or `AGENTS.md` for its check commands and commit
rules.

## 2. Update to the latest main

Find the default branch:
`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`.

- **Stacked PR** (`gh stack view` shows a stack): `gh stack sync`, resolve with
  `gh stack rebase` / `gh stack rebase --continue`, and handle every open layer,
  lowest first.
- **Otherwise rebase**, so no merge commit lands on the branch:

  ```sh
  git fetch origin
  git rebase origin/<default>
  ```

For each conflict, read both sides and the commits behind them
(`git log -p origin/<default> -- <file>`) and keep the intent of both. Never
drop main's change to make the branch win. Regenerate lockfiles and generated
files with the repo's tool instead of hand-merging. If a conflict needs a
product decision, `git rebase --abort` and ask.

Run the repo's checks locally, fix what the new main broke, and push with
`git push --force-with-lease`.

## 3. Red builds

Wait for CI on the new head (`gh pr checks <pr> --watch`, in the background),
then list what failed:

```sh
gh pr checks <pr> --json name,bucket,link,workflow \
  | jq '[.[] | select(.bucket == "fail")]'
```

**Exclude main's own failures.** A check that is red on the branch and also red
on main is not this branch's to fix:

```sh
gh api repos/{owner}/{repo}/commits/<default>/check-runs --paginate \
  --jq '.check_runs[] | select(.conclusion == "failure") | .name'
```

Use the latest main commit whose checks have finished, or
`gh run list --branch <default> --status completed`. A check is excluded only
when it fails on main **for the same reason**: compare the failing step and
error text in both logs (`gh run view <run> --log-failed`). The same name with a
different error means the branch broke it too, so fix it.

For each remaining red check:

1. Read the failure and reproduce it locally with the repo's matching command.
2. Fix the cause in the branch's code. Do not relax a lint rule, skip or delete
   a test, or update snapshots to get green. A flaky check gets one rerun
   (`gh run rerun <run> --failed`); say so if it then passes.
3. Commit following the repo's commit rules, push, and wait for CI again.

Repeat until only main's failures are red. Stop and ask if a fix needs a product
decision or one check stays red after three attempts.

## 4. Report

What was picked up, the rebase result (conflicts and how resolved), red builds
fixed, the main failures left alone (name and why), and the PR state. Do not
merge.
