#!/usr/bin/env bash
# PreToolUse (Edit|Write): block writes to secret files.
f=$(jq -r '.tool_input.file_path // empty')
[ -z "$f" ] && exit 0
b=$(basename "$f")
case "$b" in
  .env.example|.env.sample|.env.template) exit 0 ;;
  .env|.env.*|*.pem|*.key|id_rsa*|id_ed25519*|credentials.json|*.p12|*.pfx)
    jq -n --arg f "$f" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:("Protected secret file: " + $f + ". Edit it manually.")}}'
    exit 0 ;;
esac
exit 0
