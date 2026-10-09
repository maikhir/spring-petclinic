#!/usr/bin/env bash
# Eine Prüfung für alles: Format, Build, Tests.
# Ausgabe kurz halten, bei Fehlern nur die relevanten Zeilen zeigen.
set -euo pipefail
cd "$(dirname "$0")/.."

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

fail() {
  echo "FEHLER in Schritt: $1"
  echo "--- relevante Zeilen ---"
  grep -E '^\[ERROR\]|FAIL|Tests run:.*(Failures|Errors): [1-9]' "$LOG" | head -40 \
    || tail -n 40 "$LOG"
  exit 1
}

echo "1/2 Format anwenden"
./mvnw -B -q spring-javaformat:apply >"$LOG" 2>&1 || fail "Format"

echo "2/2 Build und Tests"
./mvnw -B verify >"$LOG" 2>&1 || fail "Build und Tests"

grep -E 'Tests run:|Total time' "$LOG" | tail -2
echo "OK: alles grün"
