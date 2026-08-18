#!/usr/bin/env bash
# Genera un PDF a partir de un HTML usando Chrome headless + servidor local.
# Uso: ./generar-folleto.sh [archivo-entrada.html] [archivo-salida.pdf]
# Ejemplo: ./generar-folleto.sh cv-gerencia.html cv-gerencia.pdf

set -euo pipefail

cd "$(dirname "$0")"

CHROME="${CHROME:-google-chrome}"
IN="${1:-index.html}"
OUT="${2:-solvio-folleto.pdf}"
PORT=$((RANDOM % 10000 + 20000))

if [ "$IN" = "$OUT" ]; then
  echo "ERROR: El archivo de entrada y salida no pueden ser el mismo." >&2
  exit 1
fi

command -v "$CHROME" >/dev/null || { echo "No se encuentra Chrome: $CHROME" >&2; exit 1; }

# Servidor local necesario para que Chrome cargue fuentes/íconos externos
python3 -m http.server "$PORT" &>/dev/null &
SERVER_PID=$!
trap "kill $SERVER_PID 2>/dev/null" EXIT
sleep 1

timeout 120 "$CHROME" --headless --disable-gpu --no-sandbox \
  --no-pdf-header-footer \
  --virtual-time-budget=30000 \
  --window-size=1400,900 \
  --print-to-pdf="$OUT" \
  "http://localhost:$PORT/$IN"

echo "PDF generado: $OUT"
pdfinfo "$OUT" 2>/dev/null | grep -E 'Pages|Page size' || true
