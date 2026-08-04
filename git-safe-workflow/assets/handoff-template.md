# Git task handoff — final evidence template

Fill every applicable field; mark unavailable items explicitly. Never include
credentials or credential-bearing remote URLs; when a remote must be named in a
report, state only the remote name and redact any embedded token.

## Identity

- Repository top-level (canonical root): <path>
- Task worktree (if any): <path or "none">
- Branch: <name, or "detached @ <sha>">
- Base ref/SHA: <ref or sha>
- Final HEAD SHA: <sha, or "no commit made">
- Commit SHA(s): <sha1, sha2, ... or "none">
- Change summary: <what changed and why, one short paragraph>

## State at handoff

- `git status --short --branch`: <paste, or "clean">
- `git diff --check`: <clean, or exact violations>
- Submodule state: <pinned SHA and dirty state per submodule, or "none">
- Worktree state: <list and owners, or "single checkout">

## Validation

- Commands run: <command -> exit code / result>
- Not run: <command, reason, risk>

## Uncommitted / untracked / stashed

- Uncommitted: <files + owner/status, or "none">
- Untracked: <files + owner/status, or "none">
- Stashed: <list + owner/status, or "none">

## Remote / integration state (pick one)

- Not performed
- Performed with authority — describe: <remote/branch, authority, result>
- Blocked — reason: <...>

## Remaining risks

<explicit list, or "none">

## Exceptions (if any)

- Repository/worktree: <...>
- Exact command or policy clause: <...>
- Reason: <...>
- Approver: <...>
- Recovery/rollback plan: <...>
- Final outcome: <...>
