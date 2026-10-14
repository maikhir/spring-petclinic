#!/usr/bin/env bash
# Läuft, wenn der Agent "fertig" melden will.
# Prüft nur, wenn Code oder Build-Dateien geändert wurden, sonst bleibt reine Beratung schnell.
INPUT="$(cat)"

# Endlosschleife vermeiden: Wurde der Agent durch diesen Hook schon einmal zurückgeschickt, durchlassen.
if echo "$INPUT" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

cd "$(git rev-parse --show-toplevel)" || exit 0

if [ -z "$(git status --porcelain -- src pom.xml build.gradle 2>/dev/null)" ]; then
  exit 0
fi

OUT="$(scripts/verify.sh 2>&1)" && exit 0

echo "$OUT" >&2
echo "scripts/verify.sh ist fehlgeschlagen. Bitte beheben, bevor du fertig meldest." >&2
exit 2
