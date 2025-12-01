#!/usr/bin/env bash
set -Eeuo pipefail
occ() { docker compose exec -u www-data -T app php occ "$@"; }

echo "[*] Esperando a que Nextcloud esté instalado..."
until occ status 2>/dev/null | grep -q "installed: true"; do
  echo "   ..."; sleep 5
done

echo "[*] Grupo 'clase'..."
occ group:add clase 2>/dev/null || true

mkuser () { # user pass display quota
  local u="$1" p="$2" d="$3" q="$4"
  if ! occ user:list 2>/dev/null | grep -qE "  - ${u}:"; then
    printf "%s\n%s\n" "$p" "$p" | occ user:add --display-name="$d" --group clase "$u" 2>/dev/null || true
  else
    echo "   Usuario '$u' ya existe, saltando alta."
  fi
  occ user:setting "$u" files quota "$q" 2>/dev/null || true
}

# Claves 12+ caracteres
mkuser profe   'Profe#2025!Abc' 'Profesor/a' '5 GB'
mkuser alumno1 'Alu1#2025!Abc'  'Alumno 1'   '1 GB'
mkuser alumno2 'Alu2#2025!Abc'  'Alumno 2'   '1 GB'

echo
occ user:list
occ group:list
