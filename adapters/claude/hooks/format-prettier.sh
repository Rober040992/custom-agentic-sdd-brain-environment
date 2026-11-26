#!/usr/bin/env bash
# PostToolUse (Edit|Write): format the edited file with the project's own tool: prettier > biome > eslint --fix.
f=$(jq -r '.tool_response.filePath // .tool_input.file_path // empty')
[ -f "$f" ] || exit 0
case "$f" in *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.css|*.scss|*.md|*.yaml|*.yml) ;; *) exit 0 ;; esac
case "$f" in */node_modules/*|*/openspec/*) exit 0 ;; esac
d=$(dirname "$f")
while [ "$d" != "/" ]; do
  b="$d/node_modules/.bin"
  if [ -x "$b/prettier" ]; then "$b/prettier" --write --log-level warn --ignore-unknown "$f"; exit 0; fi
  if [ -x "$b/biome" ]; then (cd "$d" && "$b/biome" format --write "$f" >/dev/null); exit 0; fi
  if [ -x "$b/eslint" ]; then
    case "$f" in *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) (cd "$d" && "$b/eslint" --fix "$f" >/dev/null) ;; esac
    exit 0
  fi
  [ -f "$d/package.json" ] && [ -d "$d/.git" ] && exit 0
  d=$(dirname "$d")
done
exit 0
