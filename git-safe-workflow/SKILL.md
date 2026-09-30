---
name: git-safe-workflow
description: >
  Read-only Git preflight, isolation, explicit staging, validation, atomic
  commit, and evidence-at-handoff checklist for any Agent about to modify a
  repository or nested repository. Encodes the network Git-management baseline:
  no destructive, remote, merge, or submodule action without separate authority.
  Use before the first `git` write in a task; it does NOT grant push/merge
  authority, is not a project-convention list, and must never be used to clean
  up someone else's work.
version: 1.2.0
last_changed_at: "2026-08-05T01:56:00+08:00"
tags: [git, workflow, security, evidence]
---

# Git-safe workflow

## When this applies

Use before any Agent modifies Git-tracked files or nested repositories. Applies
to the task's repository, its worktrees, and its submodules. This is a common
floor: project-specific branches, reviewers, tests, and release rules live in
the project addendum and win where they are stricter.

This skill is a checklist and evidence contract, not an authority grant. A
local commit is never permission to publish or integrate.

## What this skill never authorizes

- push, PR open/update/merge, tag/release, or any remote deletion;
- force push (`--force` or `--force-with-lease`), `reset --hard`, `clean -f/-x`,
  broad `restore`/`checkout` discard, `branch -D`, remote branch/tag deletion,
  `commit --amend`, rebase/history rewrite, filter-repo, prune/GC aimed at
  removing recoverable objects, worktree removal, or stash drop;
- `--no-verify` hook bypass;
- submodule init/deinit/update/URL change/pointer advance;
- working in another Agent's worktree or on a protected/shared base branch.

Each requires separate written authority plus, for destructive operations, a
recovery plan. "It seemed safe" is not authority.

## Eon 强调（2026-08-05，修正简化版）

Eon 的 git 管理要求就是：<b>做好本地 commit 记录与 GitHub 记录，及时 push/PR，
不丢失劳动成果</b>。不要执行繁重的 preflight / 隔离分支 / staging 校验仪式，
避免浪费 token。破坏性、远程删除或强推等操作仍须单独授权；其余保持简单直接。

## Workflow

### 0. Read local instructions first

Read the project addendum and the task's authorized scope. Confirm the
repository, base branch, review path, test command, and who approves
push/merge. Stop if scope, ownership, or base branch is unclear.

### 1. Preflight before touching anything

Run the read-only probe on the intended directory:

```powershell
powershell -NoProfile -File scripts/git_preflight.ps1 -Path <path>
```

Record: canonical root, bare/non-bare, branch or detached HEAD + SHA, upstream,
ahead/behind, tracked/staged/unstaged/untracked counts, worktree count, stash
count, `.gitmodules` presence, and submodule states. Never infer the repository
from the current directory.

Decision points (stop and ask the project total):

- not a Git repository, or a bare repository, or detached HEAD;
- dirty base worktree, unowned worktree, or pre-existing unrelated changes;
- missing expected upstream, or submodule state you cannot explain.

### 2. Isolate

- Use one task-owned branch; when concurrency or a shared checkout makes it
  prudent, one task-owned worktree named for the task. Record the base ref/SHA.
- Never develop directly on `main`, another protected/shared branch, or in
  another Agent's worktree without explicit authorization.
- Re-check status before switching branches or removing a worktree. Never
  manipulate `.git` internals or delete a worktree directory by hand.
- Keep unrelated edits out of the task worktree; preserve and report them,
  never silently reset/checkout/stash them away.

### 3. Stage and review

- Change only authorized task files.
- Stage explicit paths: `git add -- <path...>`; no broad catch-all unless every
  included change was reviewed.
- Inspect both the working diff (`git diff`) and the staged diff
  (`git diff --cached`) before committing.

### 4. Validate

- Run the project-required checks. If they cannot run, record the exact
  command, reason, and risk; never imply validation.

### 5. Commit (only when authorized)

- Make a local commit only when it is within the authorized task scope and the
  project's policy; otherwise preserve the changes and hand off exact evidence.
- `git diff --check` must be clean; one coherent atomic change per commit.
- The message states what changed and why. No credentials, generated noise, or
  unrelated formatting. Re-check status and the committed diff before and after
  committing.

### 6. Handoff

Use `assets/handoff-template.md` and report every field: repository top-level,
worktree, branch, base ref/SHA, final HEAD SHA, commit SHA(s), change summary,
status/diff check, validation commands and outcomes (including not-run), any
uncommitted/untracked/stashed items with owner/status, submodule/worktree
state, and explicit push/PR/merge state plus remaining risks.

Never leave an unrecorded dirty worktree. If a commit is not authorized, leave
changes intact and hand over exact file/status evidence.

## Submodules and worktrees

- A submodule is a separate repository: it needs separate scope, preflight,
  pinned-SHA and dirty-state evidence, and authority. Record its pinned SHA in
  the handoff.
- No init/deinit/recursive update/URL change/pointer advance without explicit
  submodule scope from the project total.
- Do not remove or prune worktrees another process may still use; preserve task
  worktrees until handoff acceptance or explicitly authorized cleanup.

## Failure branches

- Preflight errors or ambiguous state: pause, preserve evidence, ask the
  project total; do not improvise a fix.
- A failed, ambiguous, or timed-out Git command is evidence to inspect, not
  permission to retry a destructive variant.
- Validation cannot run: record command, reason, and risk, then hand off with
  that stated.
- A remote/submodule/destructive request arrives: stop at the authority
  boundary and obtain separate written approval; this skill is not that
  approval.

## Exceptions

An exception must name: repository/worktree, exact command or policy clause,
reason, approver, recovery/rollback plan, and final outcome. Record it in the
handoff; keep it visible and time-boxed.

## Scripts and assets

- `scripts/git_preflight.ps1` — read-only preflight probe producing compact
  JSON. It never prints remote URLs or file contents; exit 0 for handled
  non-repo/error states, nonzero only for real execution failure.
- `assets/handoff-template.md` — the required final-evidence template.
