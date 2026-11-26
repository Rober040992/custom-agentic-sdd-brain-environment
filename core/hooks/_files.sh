# Shared helper: print the file paths touched by a tool call (stdin JSON), one per line.
# Claude: tool_input.file_path / tool_response.filePath. Codex apply_patch: "*** Add|Update|Delete File: <path>" lines in tool_input.command.
hook_files() {
  local json="$1" cwd
  cwd=$(jq -r '.cwd // empty' <<<"$json"); [ -z "$cwd" ] && cwd="$PWD"
  { jq -r '.tool_response.filePath // .tool_input.file_path // empty' <<<"$json"
    jq -r '.tool_input.command // empty | if type=="array" then join("\n") else . end' <<<"$json" \
      | sed -nE 's/^\*\*\* (Add|Update|Delete) File: //p; s/^\*\*\* Move to: //p'
  } | while IFS= read -r f; do
    [ -z "$f" ] && continue
    case "$f" in /*) echo "$f" ;; *) echo "$cwd/$f" ;; esac
  done | sort -u
}
