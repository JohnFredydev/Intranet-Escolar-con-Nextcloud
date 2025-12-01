#!/usr/bin/env bash
set -Eeuo pipefail

occ() {
  docker compose exec -u www-data -T app php occ "$@"
}

echo "[*] Comprobando estado de Nextcloud..."
# Espera a que Nextcloud esté instalado (installed: true)
until occ status 2>/dev/null | grep -q "installed: true"; do
  echo "    Esperando a que finalice la instalación inicial..."
  sleep 5
done

echo "[*] Creando grupo 'clase' (si no existe)..."
occ group:add clase || true

create_user() { 
  local user="$1" pass="$2" name="$3" quota="$4"
  echo "[*] Creando usuario '$user' y asignando a 'clase'..."
  printf "%s\n%s\n" "$pass" "$pass" | occ user:add --display-name="$name" --group clase "$user" || true
  echo "    Estableciendo cuota '$quota' para $user..."
  occ user:setting "$user" files quota "$quota"
}

# Alta de usuarios con cuotas
create_user profe   'Profe#2025'  'Profesor/a' '2 GB'
create_user alumno1 'Alu1#2025'   'Alumno 1'   '1 GB'
create_user alumno2 'Alu2#2025'   'Alumno 2'   '1 GB'

echo "[*] Instalando y habilitando Group folders..."
occ app:install groupfolders || true
occ app:enable groupfolders || true

echo "[*] Creando carpeta compartida de grupo..."
# Crea la carpeta y captura su ID
CREATE_OUT="$(occ groupfolders:create "Aula - Compartida" || true)"
echo "$CREATE_OUT"
# Intentar extraer el ID de la salida (último campo numérico)
FOLDER_ID="$(echo "$CREATE_OUT" | awk '{for(i=1;i<=NF;i++){if($i ~ /^[0-9]+$/){id=$i}}} END{print id}')"

# Si no se obtuvo ID (carpeta ya existía), buscarlo por nombre
if [ -z "${FOLDER_ID:-}" ]; then
  FOLDER_ID="$(occ groupfolders:list | awk '/Aula - Compartida/ {print $1}' | head -n1)"
fi

if [ -z "${FOLDER_ID:-}" ]; then
  echo "(!) No se pudo determinar el ID de 'Aula - Compartida'. Revisa 'occ groupfolders:list'."
  exit 1
fi

echo "[*] Dando permisos al grupo 'clase' sobre la carpeta (31 = read|write|create|delete|share)..."
occ groupfolders:group "$FOLDER_ID" clase --permissions 31

# (Opcional) cuota de la carpeta de grupo (ej. 10G)
# occ groupfolders:quota "$FOLDER_ID" 10G

echo
echo "==== Resumen ===="
occ user:list
echo
occ group:list
echo
occ groupfolders:list
