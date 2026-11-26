#!/usr/bin/env bash
# Install the agentic SDD brain environment by symlinking this repo into each tool.
# Usage: ./install.sh [--tools claude[,codex]] [--dry-run]
# Idempotent. Anything it replaces is moved to ~/.agents/backups/<timestamp>/.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS="claude"; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --tools) TOOLS="$2"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    *) echo "unknown option: $1"; exit 1 ;;
  esac
done
BACKUP="$HOME/.agents/backups/$(date +%Y%m%d-%H%M%S)"

run() { if [ "$DRY" = 1 ]; then echo "  would: $*"; else "$@"; fi; }

# link <source in repo> <target>
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then return; fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    run mkdir -p "$BACKUP/$(dirname "${dst#$HOME/}")"
    run mv "$dst" "$BACKUP/${dst#$HOME/}"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  echo "  linked ${dst/#$HOME/~}"
}

common() {
  echo "core → ~/.agents"
  link "$REPO/core/AGENTS.md" "$HOME/.agents/AGENTS.md"
  link "$REPO/core/vendor/modern-web-guidance" "$HOME/.agents/vendor/modern-web-guidance"
}

claude() {
  local C="$HOME/.claude"
  echo "claude → ~/.claude"
  link "$REPO/adapters/claude/CLAUDE.md" "$C/CLAUDE.md"
  for d in "$REPO"/core/skills/*/; do link "${d%/}" "$C/skills/$(basename "$d")"; done
  for f in "$REPO"/core/agents/*.md; do link "$f" "$C/agents/$(basename "$f")"; done
  for d in "$REPO"/core/rules/*/; do link "${d%/}" "$C/rules/$(basename "$d")"; done
  for f in "$REPO"/adapters/claude/hooks/*.sh; do link "$f" "$C/hooks/$(basename "$f")"; done
  # settings.json is also written by Claude and other apps: merge, never link.
  local S="$C/settings.json" tmp
  [ -f "$S" ] || echo '{}' > "$S"
  tmp="$(mktemp)"
  jq -s '
    def uniq: reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
    .[0] as $cur | .[1] as $env
    | $cur
    | .env = (($cur.env // {}) + $env.env)
    | reduce ("allow","deny","ask") as $k (.; .permissions[$k] = ((($cur.permissions[$k] // []) + $env.permissions[$k]) | uniq))
    | reduce ($env.hooks | keys[]) as $e (.;
        .hooks[$e] = ($env.hooks[$e] + [ (.hooks[$e] // [])[]
          | select(any(.hooks[]?; (.command // "") | test("(protect-secrets|format-prettier|brain-check)\\.sh")) | not) ]))
  ' "$S" "$REPO/adapters/claude/settings.json" > "$tmp"
  if cmp -s "$S" "$tmp"; then rm "$tmp"; echo "  settings.json up to date"
  elif [ "$DRY" = 1 ]; then rm "$tmp"; echo "  would: merge settings.json"
  else mkdir -p "$BACKUP/.claude"; cp "$S" "$BACKUP/.claude/settings.json"; mv "$tmp" "$S"; echo "  merged settings.json"; fi
}

common
IFS=',' read -ra list <<< "$TOOLS"
for t in "${list[@]}"; do
  case "$t" in
    claude) claude ;;
    codex) echo "codex: adapter not ready yet (phase 2)" ;;
    *) echo "unknown tool: $t"; exit 1 ;;
  esac
done
[ -d "$BACKUP" ] && echo "backups → ${BACKUP/#$HOME/~}"
echo "done. Restart the tool to load changes."
