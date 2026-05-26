# Wrap-UP

A portable **post-ship housekeeping** skill for AI coding agents. After work is shipped and
verified, `/wrap-up` cleans the repo, refreshes docs, and syncs project memory — **without
ever destroying live state.** Core principle: *only tidy finished work, and only delete what
you can name.*

One canonical source ([`wrap-up.md`](./wrap-up.md)) installs into **Claude Code, Codex,
Gemini CLI, and OpenCode**. Edit the one file, re-run the installer, and all four update.

---

## Quick start

```bash
# macOS / Linux / Git Bash — installs for every tool found, into your user config
./install.sh

# Windows PowerShell
./install.ps1
```

```powershell
# Only some tools, or a project-scoped install:
./install.sh  --tools claude,gemini          # subset
./install.sh  --project /path/to/repo        # drop project-local copies instead of ~/
./install.sh  --link                          # symlink instead of copy (needs dev-mode on Windows)
./install.ps1 -Tools claude,codex -Project C:\path\to\repo
```

By default the installer **copies** the skill to each tool's **user-global** config so it's
available in every project. Use `--link`/`-Link` to symlink (single source of truth, but
Windows symlinks need Developer Mode or an admin shell). Use `--project`/`-Project` to drop
project-scoped copies into a specific repo instead.

---

## What gets installed where

| Tool | Target (user-global) | Format | How |
|---|---|---|---|
| **Claude Code** | `~/.claude/skills/wrap-up/SKILL.md` | Markdown + `name`/`description` frontmatter | copied as-is — the frontmatter makes it a valid skill |
| **Codex** | `~/.codex/prompts/wrap-up.md` | Markdown prompt | frontmatter stripped → clean `/wrap-up` prompt |
| **Gemini CLI** | `~/.gemini/commands/wrap-up.toml` | TOML (`description` + `prompt`) | **generated** from the md (Gemini can't read raw markdown commands) |
| **OpenCode** | `~/.config/opencode/command/wrap-up.md` | Markdown + frontmatter | copied as-is (`description` honored; extra `name` ignored) |

Project-scoped equivalents (with `--project DIR`): `DIR/.claude/skills/wrap-up/SKILL.md`,
`DIR/.gemini/commands/wrap-up.toml`, `DIR/.opencode/command/wrap-up.md`. (Codex prompts are
user-global only, so Codex always installs to `~/.codex/prompts/`.)

---

## Manual install (no script)

If you'd rather not run the installer, copy by hand:

**Claude Code**
```bash
mkdir -p ~/.claude/skills/wrap-up && cp wrap-up.md ~/.claude/skills/wrap-up/SKILL.md
```

**Codex** — strip the frontmatter (everything between the first two `---` lines), then:
```bash
mkdir -p ~/.codex/prompts && cp wrap-up.md ~/.codex/prompts/wrap-up.md   # frontmatter is cosmetic-only here
```

**OpenCode**
```bash
mkdir -p ~/.config/opencode/command && cp wrap-up.md ~/.config/opencode/command/wrap-up.md
```

**Gemini CLI** — Gemini needs TOML, so wrap the body:
```toml
# ~/.gemini/commands/wrap-up.toml
description = "Post-ship housekeeping: clean the repo, refresh docs, sync memory — never destroy live state."
prompt = """
<paste the body of wrap-up.md here, without the frontmatter>
"""
```
(The installer generates this for you.)

---

## Usage

In any of the four tools, run the command after work is **shipped and verified**:

```
/wrap-up
```

It will: gate on "is this actually committed + pushed + green?", then do an **allowlisted**
cleanup (never a blind `git clean`), refresh the docs the change touched, sync any project
memory, and report what it did — flagging anything it deliberately left alone.

## Editing the skill

`wrap-up.md` is the **single source of truth**. Edit it, then re-run the installer to
propagate the change to every tool. The `## Optional integrations` section is where
project-specific extensions (notes vaults, agent memory, vector stores) live — gated so they
no-op on projects that don't use them.

## License

MIT — see [LICENSE](./LICENSE).
