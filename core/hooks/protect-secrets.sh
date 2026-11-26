#!/usr/bin/env bash
# PreToolUse (file edits): block writes to secret files. Works for Claude (Edit/Write) and Codex (apply_patch).
. "$(dirname "$(readlink -f "$0")")/_files.sh"
json=$(cat)
while IFS= read -r f; do
  b=$(basename "$f")
  case "$b" in
    .env.example|.env.sample|.env.template) ;;
    .env|.env.*|*.pem|*.key|id_rsa*|id_ed25519*|credentials.json|*.p12|*.pfx)
      jq -n --arg f "$f" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:("Protected secret file: " + $f + ". Edit it manually.")}}'
      exit 0 ;;
  esac
done < <(hook_files "$json")
exit 0
