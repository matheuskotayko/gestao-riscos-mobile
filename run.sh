#!/usr/bin/env bash
# Sobe backend (Docker), emulador Android e o app, em um comando só.
# Uso: ./run.sh [nome-do-avd]   (default: gestao)
set -euo pipefail

AVD="${1:-gestao}"
cd "$(dirname "$0")"

echo "==> Backend (docker compose)"
# sem --wait: ele retorna erro quando o minio-init (one-shot) termina
docker compose up -d
until curl -sf -o /dev/null http://localhost:8000/api/usuarios/setores/; do
  sleep 2
done
echo "    API respondendo em http://localhost:8000"

echo "==> Emulador ($AVD)"
if adb devices | grep -q "emulator-.*device$"; then
  echo "    já rodando"
else
  rm -f ~/.android/avd/"$AVD".avd/*.lock
  emulator -avd "$AVD" -no-snapshot >/tmp/emulator-"$AVD".log 2>&1 &
  disown
fi

echo "==> Esperando boot completo"
adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
  sleep 3
done

echo "==> App (flutter run)"
cd mobile
exec flutter run -d "$(adb devices | grep -m1 'emulator-.*device$' | cut -f1)"
