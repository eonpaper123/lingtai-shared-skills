# Eon Station shared skills

This directory is the canonical, reviewable source for reusable operating procedures shared by station Agents whose configured skill roots include it.

## Stewardship

- Control-total owns cross-project procedure packaging and independent verification.
- Project totals own installation/adoption inside their independent Agent trees.
- A file in this directory is **not** proof that another Agent loaded it; verify configured roots, catalog rescan/runtime state, and the task-specific evidence.
- Store no credentials, provider auth, chat tokens, private project data, runtime logs, or generated Agent state here.
- Local commits are for review/rollback. No remote is configured; push, publication, or mirroring requires separate authorization.

## Change workflow

1. Inspect the repository status and current rules/skills.
2. Stage only reviewed skill paths.
3. Run the bundled skill validator and any script syntax/self-tests.
4. Inspect the staged diff and `git diff --check`.
5. Commit one coherent procedure change.
6. Record commit/hash and distribute through the rightful project totals.
