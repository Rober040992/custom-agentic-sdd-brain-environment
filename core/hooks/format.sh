#!/usr/bin/env bash
# PostToolUse (file edits): format edited files with the project's own tool: prettier > biome > eslint --fix.
. "$(dirname "$(readlink -f "$0")")/_files.sh"
fmt() {
  local f="$1" d b
  [ -f "$f" ] || return 0
  case "$f" in *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.css|*.scss|*.md|*.yaml|*.yml) ;; *) return 0 ;; esac
  case "$f" in */node_modules/*|*/openspec/*) return 0 ;; esac
  d=$(dirname "$f")
  while [ "$d" != "/" ]; do
    b="$d/node_modules/.bin"
    if [ -x "$b/prettier" ]; then "$b/prettier" --write --log-level warn --ignore-unknown "$f"; return 0; fi
    if [ -x "$b/biome" ]; then (cd "$d" && "$b/biome" format --write "$f" >/dev/null); return 0; fi
    if [ -x "$b/eslint" ]; then
      case "$f" in *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) (cd "$d" && "$b/eslint" --fix "$f" >/dev/null) ;; esac
      return 0
    fi
    [ -f "$d/package.json" ] && [ -d "$d/.git" ] && return 0
    d=$(dirname "$d")
  done
}
json=$(cat)
while IFS= read -r f; do fmt "$f"; done < <(hook_files "$json")
exit 0
