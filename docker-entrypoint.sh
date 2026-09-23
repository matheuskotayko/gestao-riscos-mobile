#!/bin/sh
set -e

python manage.py migrate --noinput

# O seed apaga e recria usuarios e planos. Rodar de novo num banco ja populado
# invalida as sessoes existentes (os ids mudam, entao os JWTs ja emitidos viram
# 401) e deixa o cache dos apps com registros fantasmas dos uuids antigos. Por
# isso so popula banco vazio; pra recriar os dados de demo de proposito:
#   docker compose exec backend python manage.py seed_apresentacao
TEM_USUARIO=$(python manage.py shell -c \
  'from usuarios.models import Usuario; print(Usuario.objects.exists())' \
  | tail -n 1)

if [ "$TEM_USUARIO" = "True" ]; then
  echo "→ Banco já populado, pulando seed_apresentacao."
else
  python manage.py seed_apresentacao
fi

exec python manage.py runserver 0.0.0.0:8000
