#!/usr/bin/env bash
# Wrap-UP installer — copies (or symlinks) the canonical wrap-up.md into each
# AI tool's command/skill location. One source of truth: wrap-up.md.
#
#   ./install.sh                         # all four tools, user-global, copy
#   ./install.sh --tools claude,gemini   # subset
#   ./install.sh --project /path/to/repo # project-scoped copies instead of ~/
#   ./install.sh --link                  # symlink instead of copy
#   ./install.sh --help
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/wrap-up.md"

TOOLS="claude,codex,gemini,opencode"
PROJECT=""
LINK=0

while [ $# -gt 0 ]; do
  case "$1" in
    --tools)   TOOLS="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --link)    LINK=1; shift ;;
    --help|-h)
      sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -f "$SRC" ] || { echo "error: wrap-up.md not found next to installer" >&2; exit 1; }

# --- helpers -----------------------------------------------------------------
strip_frontmatter() { awk 'f>=2{print} /^---[[:space:]]*$/{f++}' "$SRC"; }
get_description()  { awk '/^description:/{sub(/^description: */,""); print; exit}' "$SRC"; }

place() {  # place <target-file> <mode: full|body>
  local target="$1" mode="$2"
  mkdir -p "$(dirname "$target")"
  if [ "$mode" = "body" ]; then
    strip_frontmatter > "$target"             # frontmatter stripped (Codex)
  elif [ "$LINK" -eq 1 ]; then
    ln -sf "$SRC" "$target"                    # symlink the canonical file
  else
    cp -f "$SRC" "$target"                     # copy as-is
  fi
  echo "  ✓ $target"
}

gen_gemini_toml() {  # gen_gemini_toml <target.toml>
  local target="$1"; mkdir -p "$(dirname "$target")"
  { printf "description = '%s'\n" "$(get_description)"
    printf "prompt = '''\n"
    strip_frontmatter
    printf "'''\n"; } > "$target"
  echo "  ✓ $target (generated)"
}

# --- resolve roots -----------------------------------------------------------
if [ -n "$PROJECT" ]; then
  CLAUDE="$PROJECT/.claude/skills/wrap-up/SKILL.md"
  GEMINI="$PROJECT/.gemini/commands/wrap-up.toml"
  OPENCODE="$PROJECT/.opencode/command/wrap-up.md"
else
  CLAUDE="$HOME/.claude/skills/wrap-up/SKILL.md"
  GEMINI="$HOME/.gemini/commands/wrap-up.toml"
  OPENCODE="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/command/wrap-up.md"
fi
CODEX="$HOME/.codex/prompts/wrap-up.md"   # Codex prompts are user-global only

echo "Installing wrap-up ($([ "$LINK" -eq 1 ] && echo symlink || echo copy)) ->"
case ",$TOOLS," in *,claude,*)   place "$CLAUDE" full ;; esac
case ",$TOOLS," in *,codex,*)    place "$CODEX"  body ;; esac
case ",$TOOLS," in *,gemini,*)   gen_gemini_toml "$GEMINI" ;; esac
case ",$TOOLS," in *,opencode,*) place "$OPENCODE" full ;; esac
echo "Done. Run /wrap-up in any installed tool."
