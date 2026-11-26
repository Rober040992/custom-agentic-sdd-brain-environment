#!/usr/bin/env bash
# SessionStart: tell the agent whether the project's brain (.agents/brain.md) is fresh.
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
brain="$root/.agents/brain.md"
ignore='^(\.agents|\.claude)/'
dirty=$(git -C "$root" status --porcelain 2>/dev/null | cut -c4- | grep -Ev "$ignore" | grep -c .)
extra=""; [ "$dirty" -gt 0 ] && extra=" Además hay $dirty ficheros sin commitear: tenlos en cuenta si afectan al cerebro."
say() { jq -n --arg m "$1$extra" '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$m}}'; exit 0; }
if [ ! -f "$brain" ]; then
  [ -f "$root/AGENTS.local.md" ] && say "CEREBRO: este proyecto no tiene .agents/brain.md. Propón crearlo (skill cerebro)."
  exit 0
fi
sha=$(grep -o 'commit=[0-9a-f]*' "$brain" | head -1 | cut -d= -f2)
[ -z "$sha" ] && say "CEREBRO: .agents/brain.md no tiene commit registrado; trátalo como posiblemente desactualizado."
head=$(git -C "$root" rev-parse HEAD 2>/dev/null)
if ! git -C "$root" cat-file -e "$sha^{commit}" 2>/dev/null; then
  say "CEREBRO: el commit $sha del cerebro no existe en este repo (rebase/otra rama). Pregunta al usuario si releer el proyecto para realinearlo."
fi
case "$head" in "$sha"*) say "CEREBRO: al día (commit ${sha:0:8}). Úsalo antes de leer el disco." ;; esac
files=$(git -C "$root" diff --name-only "$sha" HEAD | grep -Ev "$ignore")
n=$(printf '%s\n' "$files" | grep -c .)
[ "$n" -eq 0 ] && say "CEREBRO: al día (sin cambios relevantes desde ${sha:0:8}). Úsalo antes de leer el disco."
list=$(printf '%s\n' "$files" | head -25 | tr '\n' ' ')
if [ "$n" -gt 60 ]; then
  say "CEREBRO DESACTUALIZADO: $n ficheros cambiados desde ${sha:0:8}. Pregunta al usuario si releer el proyecto para realinear el cerebro. Muestra: $list"
fi
say "CEREBRO desactualizado: $n ficheros cambiados desde ${sha:0:8}: $list. Cuando trabajes en esas zonas, actualiza las secciones afectadas del cerebro y su commit."
