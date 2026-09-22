#!/usr/bin/env bash
# Sobe backend (Docker), emulador Android e o app, em um comando só.
# Uso: ./run.sh [nome-do-avd]   (default: gestao)
set -euo pipefail

AVD="${1:-gestao}"
cd "$(dirname "$0")"

# Não depender do PATH de quem chamou: procura o SDK e o Flutter nos lugares usuais.
ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/sdk}}"
PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$HOME/flutter/bin:$PATH"

for cmd in docker adb emulator flutter; do
  command -v "$cmd" >/dev/null || {
    echo "ERRO: '$cmd' não encontrado." >&2
    [ "$cmd" = docker ] || echo "Confere se o SDK está em $ANDROID_HOME e o Flutter em ~/flutter." >&2
    exit 1
  }
done

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
  # sem -no-snapshot: retoma do snapshot salvo (~3s em vez de ~50s de cold boot).
  # Pra forçar boot limpo: emulator -avd gestao -no-snapshot
  emulator -avd "$AVD" -no-audio -no-boot-anim >/tmp/emulator-"$AVD".log 2>&1 &
  disown
fi

echo "==> Esperando boot completo"
for _ in $(seq 120); do   # 4 min de teto; cold boot leva ~50s
  [ "$(adb get-state 2>/dev/null)" = device ] &&
    [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] && break
  sleep 2
done
if [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != 1 ]; then
  echo "ERRO: emulador não subiu. Log: /tmp/emulator-$AVD.log" >&2
  tail -5 /tmp/emulator-"$AVD".log >&2 2>/dev/null || true
  exit 1
fi

echo "==> App (flutter run)"
cd mobile
exec flutter run -d "$(adb devices | grep -m1 'emulator-.*device$' | cut -f1)"
