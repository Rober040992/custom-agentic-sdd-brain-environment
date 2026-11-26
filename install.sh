#!/usr/bin/env bash
# Install the agentic SDD brain environment by symlinking this repo into each tool.
#
#   ./install.sh                  detect installed tools, link everything, ask which hooks to enable
#   ./install.sh hooks            only (re)choose hooks
#   --tools claude,codex,opencode pick tools instead of detecting them
#   --hooks all|none|secrets,format,brain   choose hooks without asking
#   --dry-run                     show what would change
#
# Idempotent. Anything it replaces is moved to ~/.agents/backups/<timestamp>/.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS=""; DRY=0; MODE=all; HOOKS_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    hooks) MODE=hooks; shift ;;
    --tools) TOOLS="$2"; shift 2 ;;
    --hooks) HOOKS_ARG="$2"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    *) echo "unknown option: $1"; exit 1 ;;
  esac
done
BACKUP="$HOME/.agents/backups/$(date +%Y%m%d-%H%M%S)"
HOOKS_DIR="$HOME/.agents/hooks"
HOOKS_CONF="$HOME/.agents/hooks.conf"

run() { if [ "$DRY" = 1 ]; then echo "  would: $*"; else "$@"; fi; }

backup() { # backup <file>
  run mkdir -p "$BACKUP/$(dirname "${1#$HOME/}")"
  run cp -P "$1" "$BACKUP/${1#$HOME/}"
}

link() { # link <source in repo> <target>
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then return; fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then backup "$dst"; run rm -rf "$dst"; fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  echo "  linked ${dst/#$HOME/~}"
}

prune() { # remove links into this repo whose target no longer exists
  local d
  for d in "$@"; do
    [ -d "$d" ] || continue
    find "$d" -maxdepth 1 -type l | while read -r l; do
      case "$(readlink "$l")" in "$REPO"/*) [ -e "$l" ] || { run rm "$l"; echo "  removed stale ${l/#$HOME/~}"; } ;; esac
    done
  done
}

write_if_changed() { # write_if_changed <target> <new file>
  if [ -f "$1" ] && cmp -s "$1" "$2"; then rm "$2"; echo "  ${1/#$HOME/~} up to date"
  elif [ "$DRY" = 1 ]; then rm "$2"; echo "  would: update ${1/#$HOME/~}"
  else [ -f "$1" ] && backup "$1"; mv "$2" "$1"; echo "  updated ${1/#$HOME/~}"; fi
}

# ---------- hooks ----------

choose_hooks() {
  local sel=""
  if [ -n "$HOOKS_ARG" ]; then
    case "$HOOKS_ARG" in all) sel="secrets,format,brain" ;; none) sel="" ;; *) sel="$HOOKS_ARG" ;; esac
  elif [ "$MODE" = all ] && [ -f "$HOOKS_CONF" ]; then
    sel=$(sed -n 's/^HOOKS=//p' "$HOOKS_CONF")
  elif [ -t 0 ]; then
    echo; echo "Hooks (Enter = yes):"
    local key label a
    for key in secrets format brain; do
      case "$key" in
        secrets) label="Block edits to .env / keys / credentials" ;;
        format)  label="Format edited files (prettier > biome > eslint)" ;;
        brain)   label="Check the project brain at session start" ;;
      esac
      read -r -p "  $label? [Y/n] " a
      case "$a" in n|N|no) ;; *) sel="$sel${sel:+,}$key" ;; esac
    done
  else
    sel="secrets,format,brain"
  fi
  HOOKS="$sel"
  [ "$DRY" = 1 ] || { mkdir -p "$(dirname "$HOOKS_CONF")"; echo "HOOKS=$HOOKS" > "$HOOKS_CONF"; }
  echo "hooks: ${HOOKS:-none}"
}

# hooks_json <file-edit matcher>: our hook entries in the shared Claude/Codex format
hooks_json() {
  jq -n --arg m "$1" --arg sel ",$HOOKS," --arg d "$HOOKS_DIR" '
    def on($k): $sel | contains("," + $k + ",");
    def cmd($s; $t): {type:"command", command:($d + "/" + $s), timeout:$t};
    {
      PreToolUse:   (if on("secrets") then [{matcher:$m, hooks:[cmd("protect-secrets.sh"; 10)]}] else [] end),
      PostToolUse:  (if on("format")  then [{matcher:$m, hooks:[cmd("format.sh"; 30)]}] else [] end),
      SessionStart: (if on("brain")   then [{hooks:[cmd("brain-check.sh"; 10)]}] else [] end)
    }'
}

# merge_hooks <json file> <matcher>: replace our entries, keep everyone else's
merge_hooks() {
  local f="$1" tmp; tmp="$(mktemp)"
  [ -f "$f" ] || echo '{}' > "$tmp.in"; [ -f "$f" ] && cp "$f" "$tmp.in"
  jq --argjson ours "$(hooks_json "$2")" '
    def mine: any(.hooks[]?; (.command // "") | test("/(protect-secrets|format|format-prettier|brain-check)\\.sh"));
    reduce ("PreToolUse","PostToolUse","SessionStart") as $e (.;
      ($ours[$e] + [ (.hooks[$e] // [])[] | select(mine | not) ]) as $new
      | if ($new | length) > 0 then .hooks[$e] = $new else del(.hooks[$e]) end)
  ' "$tmp.in" > "$tmp"; rm "$tmp.in"
  write_if_changed "$f" "$tmp"
}

# ---------- tools ----------

common() {
  echo "core → ~/.agents"
  link "$REPO/core/AGENTS.md" "$HOME/.agents/AGENTS.md"
  link "$REPO/core/hooks" "$HOOKS_DIR"
  link "$REPO/core/vendor/modern-web-guidance" "$HOME/.agents/vendor/modern-web-guidance"
  # ~/.agents/skills is the shared skills dir (Codex and OpenCode read it natively)
  for d in "$REPO"/core/skills/*/; do link "${d%/}" "$HOME/.agents/skills/$(basename "$d")"; done
  prune "$HOME/.agents/skills"
}

# gen_agents <dir> <ext>: convert core/agents/*.md to another tool's agent format
gen_agents() {
  [ "$DRY" = 1 ] && { echo "  would: generate agents in ${1/#$HOME/~}"; return; }
  mkdir -p "$1"
  python3 -I - "$REPO/core/agents" "$1" "$2" <<'PY'
import sys, pathlib, re, json
src, dst, fmt = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), sys.argv[3]
note = "Generated from core/agents by install.sh. Edit the .md in the repo."
for md in sorted(src.glob("*.md")):
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", md.read_text(), re.S)
    meta, body = (m.group(1), m.group(2).strip()) if m else ("", md.read_text())
    d = re.search(r"^description:\s*(.*)$", meta, re.M)
    desc = d.group(1).strip().strip('"') if d else md.stem
    if fmt == "toml":   # Codex
        out = f"# {note}\nname = {json.dumps(md.stem)}\ndescription = {json.dumps(desc)}\ndeveloper_instructions = {json.dumps(body)}\n"
        (dst / f"{md.stem}.toml").write_text(out)
    else:               # OpenCode
        out = f"---\ndescription: {json.dumps(desc)}\nmode: subagent\n---\n<!-- {note} -->\n\n{body}\n"
        (dst / f"{md.stem}.md").write_text(out)
print(f"  generated {len(list(src.glob('*.md')))} agents in {str(dst).replace(str(pathlib.Path.home()), '~')}")
PY
}

claude() {
  local C="$HOME/.claude"
  echo "claude → ~/.claude"
  link "$REPO/adapters/claude/CLAUDE.md" "$C/CLAUDE.md"
  for d in "$REPO"/core/skills/*/; do link "${d%/}" "$C/skills/$(basename "$d")"; done
  for f in "$REPO"/core/agents/*.md; do link "$f" "$C/agents/$(basename "$f")"; done
  for d in "$REPO"/core/rules/*/; do link "${d%/}" "$C/rules/$(basename "$d")"; done
  prune "$C/skills" "$C/agents" "$C/rules" "$C/hooks"
  # settings.json is also written by Claude and other apps: merge, never link.
  local S="$C/settings.json" tmp; tmp="$(mktemp)"
  [ -f "$S" ] || echo '{}' > "$S"
  jq -s '
    def uniq: reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
    .[0] as $cur | .[1] as $env
    | $cur
    | .env = (($cur.env // {}) + $env.env)
    | reduce ("allow","deny","ask") as $k (.; .permissions[$k] = ((($cur.permissions[$k] // []) + $env.permissions[$k]) | uniq))
  ' "$S" "$REPO/adapters/claude/settings.json" > "$tmp"
  write_if_changed "$S" "$tmp"
}

claude_hooks() { merge_hooks "$HOME/.claude/settings.json" "Edit|Write"; }

codex() {
  local X="$HOME/.codex"
  echo "codex → ~/.codex"
  link "$REPO/core/AGENTS.md" "$X/AGENTS.md"
  for f in "$REPO"/adapters/codex/rules/*.rules; do link "$f" "$X/rules/$(basename "$f")"; done
  prune "$X/rules"
  gen_agents "$X/agents" toml   # re-run install.sh after editing an agent
}

codex_hooks() {
  merge_hooks "$HOME/.codex/hooks.json" "apply_patch|Edit|Write"
  [ -n "$HOOKS" ] && echo "  codex: open /hooks in Codex once to trust the new hooks"
  return 0
}

opencode() {
  local O="$HOME/.config/opencode" F
  echo "opencode → ~/.config/opencode"
  link "$REPO/core/AGENTS.md" "$O/AGENTS.md"
  for f in "$REPO"/adapters/opencode/plugins/*.js; do link "$f" "$O/plugins/$(basename "$f")"; done
  prune "$O/plugins"
  gen_agents "$O/agents" md     # re-run install.sh after editing an agent
  # opencode.json(c) is user config: merge our permission rules, never link.
  F="$O/opencode.jsonc"; [ -f "$F" ] || F="$O/opencode.json"
  [ -f "$F" ] || echo '{"$schema":"https://opencode.ai/config.json"}' > "$F"
  local tmp; tmp="$(mktemp)"
  if jq -s '.[0] * .[1]' "$F" "$REPO/adapters/opencode/opencode.json" > "$tmp" 2>/dev/null; then
    write_if_changed "$F" "$tmp"
  else
    rm -f "$tmp"; echo "  ! ${F/#$HOME/~} has comments; merge adapters/opencode/opencode.json by hand"
  fi
}

opencode_hooks() { echo "  opencode: plugin reads ~/.agents/hooks.conf (no session-start hook in OpenCode)"; }

# ---------- main ----------

if [ -z "$TOOLS" ]; then
  for t in claude codex opencode; do command -v "$t" >/dev/null && TOOLS="$TOOLS${TOOLS:+,}$t"; done
  [ -z "$TOOLS" ] && { echo "no supported tool found (claude, codex, opencode)"; exit 1; }
  echo "detected: $TOOLS"
fi
IFS=',' read -ra list <<< "$TOOLS"
for t in "${list[@]}"; do case "$t" in claude|codex|opencode) ;; *) echo "unknown tool: $t"; exit 1 ;; esac; done

if [ "$MODE" = all ]; then
  common
  for t in "${list[@]}"; do "$t"; done
fi
choose_hooks
for t in "${list[@]}"; do echo "$t hooks"; "${t}_hooks"; done

[ -d "$BACKUP" ] && echo "backups → ${BACKUP/#$HOME/~}"
echo "done. Restart the tool to load changes."
