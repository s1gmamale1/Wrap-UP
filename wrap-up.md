---
name: wrap-up
description: Use when a unit of work is finished and shipped (a goal met, a feature merged, a PR/commit pushed and verified green) and the repo needs post-ship housekeeping — leftover junk / build / test artifacts, dead code, stale git worktrees, or out-of-date docs and project memory. Also triggers on "wrap up", "clean up after", "post-ship housekeeping", or "tidy up and update docs/memory".
---

# Wrap-Up (post-ship housekeeping)

## Overview
Run the standard housekeeping after work is **shipped and verified** — clean the repo,
refresh the docs, and sync any project memory — without ever destroying live state. Core
principle: **only tidy finished work, and only delete what you can name.**

## When to use
- A feature/fix is committed + pushed and verification passed (build + tests green) — a
  goal met, a PR merged.
- The user says "wrap up", "clean up after", "post-ship", "update docs + memory".
- **Do NOT use** when work is unfinished/unverified — finish + verify + ship first.
  Wrapping up half-done work hides real state.

## Precondition gate (verify before touching anything)
Work is committed AND pushed (`git log origin/<branch>..<branch>` is empty) and
verification passed. If not, STOP and finish first.

## Steps
1. **Cleanup — allowlisted, never blind.**
   - `git status --porcelain | grep '^??'` → identify junk: malformed / short-name files
     left at the repo root by tool shell redirects (e.g. `1`, `{`, `set({`, `tuple[int`,
     `Promise`). Delete ONLY those, by exact quoted name (`rm -f -- '<name>'`). If unsure,
     confirm they're 0-byte / code fragments first.
   - Clear regen-able artifacts: test caches (`.pytest_cache`, coverage), stray build
     output, misfiled screenshots/PNGs.
   - `git worktree prune` (removes only dead admin refs — SAFE).
   - Remove dead code the shipped change orphaned (now-unused files/imports). Grep that
     nothing imports them first — **then re-run the build + tests after deleting**: a file
     that wasn't actually dead fails compilation, and that is the *only* real proof the
     deletion was safe (grep alone misses re-exports, dynamic imports, and string-keyed
     lookups). If the build/tests were green before but red after, you deleted something
     live — restore it.
   - Harden `.gitignore` for any local-only artifacts that newly appeared (local DBs,
     caches, generated config) so they never get committed.
2. **Docs.** Update the in-repo docs the change touched — README, architecture/API docs,
   a `STATE.md` / `CONTRACTS.md` if the project keeps one. Additive + accurate; don't
   rewrite whole files.
3. **Project memory (if the project keeps one).** Append/prepend a dated, most-recent-first
   entry to whatever running log the project uses (a changelog, a memory/notes vault, an
   index file). If it's an untracked local vault, edit it — don't commit it.
4. **Verify + report.** `git status -s` shows only intended changes. **If you deleted any
   code in step 1, the build + tests must be green *after* the deletion** (not just before) —
   that is the deletion's proof. Commit the docs (+ the skill / any code) with a clear message
   and push. Summarize what was cleaned, documented, and stored — and flag anything you
   deliberately left (e.g. stale worktrees).

## NEVER (safety — these are why blind cleanup is dangerous)
| Don't | Why |
|---|---|
| `git clean -fd` / `-x` | Wipes untracked **live** state: local databases, knowledge/notes vaults, screenshots, `.env` files. Delete junk by explicit name instead. |
| Delete a local database / memory store / cache you're meant to KEEP or UPDATE | That state is often the thing the project relies on between runs — losing it is silent and expensive. |
| `git worktree remove` an existing worktree | Most belong to other live sessions / may hold unmerged work. Only `prune` dead refs; surface stale ones to the user — never force-remove. |
| Touch infra unrelated to the shipped change | Out of scope for housekeeping. If the task didn't change it, leave it. |

## Common mistakes
- Treating a real untracked file (a new doc, a notes vault, a local DB) as "junk" — only
  delete malformed shell-fragment names you can enumerate.
- Committing an untracked-by-design vault or local store.
- Mass-editing tests to "tidy up" — only touch docs/tests the shipped change requires.

## Optional integrations (skip any your project doesn't use)
These extend the core flow for specific setups. Ignore the ones that don't apply.

- **Knowledge / notes vault** (e.g. an Obsidian `notes/` folder): prepend a one-row entry
  to its index file and a dated section to its main log, most-recent-first. Usually an
  untracked local vault — edit, don't commit.
- **Behavior / agent memory** (e.g. a per-project `memory/` dir with a `MEMORY.md` index):
  if a reusable lesson emerged, write one fact-file and add a one-line pointer to the index.
  Skip if nothing new was learned.
- **Vector / pattern memory** (e.g. Ruflo AgentDB, an embeddings store): confirm the store
  is healthy, then persist this work's reusable patterns/domain so future sessions can
  recall them. Never delete the store's data files — that IS the memory you're updating.
- **Auto-run:** invoke on demand as `/wrap-up`. To run it automatically when a task
  completes, chain it into the task ("…then wrap up") or wire a stop/finish hook — but the
  steps need judgment, so on-demand invocation is the reliable path.
