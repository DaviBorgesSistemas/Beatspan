#!/usr/bin/env bash
# Roda o OSV-Scanner (https://github.com/google/osv-scanner) contra o pubspec.lock
# para checar vulnerabilidades conhecidas nas dependências do projeto (SEC-003).
#
# Uso: ./scripts/scan_dependencies.sh
#
# Baixa o binário standalone do OSV-Scanner para .tools/ (fora do controle de
# versão) na primeira execução; execuções seguintes reusam o binário já baixado.

set -euo pipefail

cd "$(dirname "$0")/.."

TOOLS_DIR=".tools"
OSV_BIN="$TOOLS_DIR/osv-scanner.exe"
OSV_VERSION_URL="https://github.com/google/osv-scanner/releases/latest/download/osv-scanner_windows_amd64.exe"

mkdir -p "$TOOLS_DIR"

if [ ! -f "$OSV_BIN" ]; then
  echo "OSV-Scanner não encontrado em $OSV_BIN — baixando..."
  curl -sL -o "$OSV_BIN" "$OSV_VERSION_URL"
  chmod +x "$OSV_BIN"
fi

echo "Versão do OSV-Scanner:"
"$OSV_BIN" --version

echo ""
echo "Escaneando pubspec.lock..."
"$OSV_BIN" scan source --lockfile=pubspec.lock --format table
