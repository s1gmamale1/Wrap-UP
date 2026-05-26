# Design — Wrap-UP portable skill

**Date:** 2026-05-26
**Goal:** publish the `wrap-up` post-ship-housekeeping skill as a standalone, public repo
that **Claude Code, Codex, Gemini CLI, and OpenCode** can all use, from a single source.

## Decision: one canonical body + per-tool wrappers (generated at install)

`wrap-up.md` is the single source of truth. The installer places it into each tool's native
location, transforming only where a tool's format demands it. Editing one file + re-running
the installer keeps all four in sync.

### Why not a native committed file per tool?
Considered (Claude `SKILL.md` + Gemini `.toml` + OpenCode `.md` + `AGENTS.md`, all committed).
Rejected: four committed copies drift. A single `wrap-up.md` + an installer that derives the
others removes drift by construction. The repo stays tiny and obvious.

## Per-tool mapping

| Tool | Target | Transform |
|---|---|---|
| Claude Code | `~/.claude/skills/wrap-up/SKILL.md` | none — `name`/`description` frontmatter = valid skill |
| Codex | `~/.codex/prompts/wrap-up.md` | strip frontmatter (cosmetic in a prompt) |
| Gemini CLI | `~/.gemini/commands/wrap-up.toml` | generate TOML (`description` + `prompt`=body); Gemini can't read raw md commands |
| OpenCode | `~/.config/opencode/command/wrap-up.md` | none — `description` honored, `name` ignored |

Codex prompts are user-global only, so Codex always installs to `~/.codex/prompts/` even
under `--project`.

## Portability of the body

The original skill was Homeworks-specific (Ruflo AgentDB, an Obsidian `notes/` vault,
`agentdb.rvf`, the `Skill` tool). For a public, portable skill the body was split:

- **Core (universal):** precondition gate → allowlisted cleanup (never blind `git clean`) →
  docs → verify+report → `NEVER` safety table → common mistakes.
- **`## Optional integrations (skip if absent)`:** notes/knowledge vault, behavior/agent
  memory dir, vector/pattern store, auto-run hook. Gated so they no-op on vanilla projects
  and leak no project internals.

## Install ergonomics (judgment calls)

1. **Copy by default, `--link` for symlink** — Windows symlinks need Developer Mode/admin.
2. **User-global by default, `--project DIR` for project-scoped** — Codex is global-only, so
   global keeps all four consistent.
3. **Generate Gemini's `.toml` at install** — no committed copy to drift.
4. **MIT license** — standard for a shareable public skill.
5. **Two installers** — `install.sh` (Git Bash/macOS/Linux) and `install.ps1` (Windows).

## Repo layout

```
Wrap-UP/
├── README.md          # what it is + per-tool install + quick start
├── wrap-up.md         # THE skill — single source of truth
├── install.sh         # bash installer
├── install.ps1        # PowerShell installer
├── LICENSE            # MIT
└── docs/DESIGN.md     # this file
```
