#!/usr/bin/env bash
# Eine Prüfung für alles: Format, Build, Tests, Kennzahlen.
# Ausgabe kurz halten, bei Fehlern nur die relevanten Zeilen zeigen.
set -euo pipefail
cd "$(dirname "$0")/.."

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

# Build verlangt Java 25+ (maven-enforcer). Ist die aktive JVM älter, auf macOS eine passende wählen.
JAVA_MAJOR="$("${JAVA_HOME:+$JAVA_HOME/bin/}java" -XshowSettings:properties -version 2>&1 \
  | awk '/java.specification.version/{print $3}' | cut -d. -f1 || true)"
if [ "${JAVA_MAJOR:-0}" -lt 25 ] && [ -x /usr/libexec/java_home ]; then
  if JDK="$(/usr/libexec/java_home -v 25+ 2>/dev/null)"; then
    export JAVA_HOME="$JDK"
    echo "Hinweis: JAVA_HOME auf $JDK gesetzt (Build verlangt Java 25+)"
  fi
fi

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

echo "--- Kennzahlen ---"
CSV="target/site/jacoco/jacoco.csv"
if [ -f "$CSV" ]; then
  awk -F, 'NR>1{m+=$8;c+=$9}END{if(m+c>0)printf "Zeilenabdeckung: %.1f%% (%d von %d)\n",100*c/(m+c),c,m+c}' "$CSV"
fi
SB="target/spotbugsXml.xml"
if [ -f "$SB" ]; then
  echo "SpotBugs-Findings: $(grep -o '<BugInstance' "$SB" | wc -l | tr -d ' ')"
fi

echo "OK: alles grün"
