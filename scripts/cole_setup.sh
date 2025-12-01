#!/usr/bin/env bash
set -Eeuo pipefail

occ() { docker compose exec -u www-data -T app php occ "$@"; }

echo "[*] Comprobando que Nextcloud esté instalado..."
until occ status 2>/dev/null | grep -q "installed: true"; do
  echo "    Esperando instalación..."; sleep 5
done

echo "[*] Habilitando apps base de intranet..."
occ app:enable theming 2>/dev/null || true
occ app:enable groupfolders 2>/dev/null || true
occ app:enable calendar 2>/dev/null || true
occ app:enable contacts 2>/dev/null || true
occ app:enable tasks 2>/dev/null || true
occ app:enable spreed 2>/dev/null || true        # Talk (chat/salas) para el centro
occ app:enable viewer 2>/dev/null || true        # Visor de documentos/imágenes
occ app:enable files_pdfviewer 2>/dev/null || true

echo "[*] Branding / Theming del centro..."
# Personaliza estos valores
CENTER_NAME="Intranet Colegio San Example"
CENTER_SLOGAN="Aprender · Compartir · Colaborar"
CENTER_URL="https://www.colegio-san-example.edu"
CENTER_COLOR="#0b5ed7"  # azul corporativo (cambia hex si quieres)

occ theming:config name "$CENTER_NAME" 2>/dev/null || true
occ theming:config slogan "$CENTER_SLOGAN" 2>/dev/null || true
occ theming:config url "$CENTER_URL" 2>/dev/null || true
occ theming:config color "$CENTER_COLOR" 2>/dev/null || true
# Logo/Favicon opcional (pon tus archivos y descomenta):
# occ theming:config logo /var/www/html/custom_skeleton/logo_colegio.png
# occ theming:config favicon /var/www/html/custom_skeleton/favicon.png

echo "[*] Ajustes globales (idioma, región, URLs, privacidad de compartición)..."
occ config:system:set default_language --value es 2>/dev/null || true
occ config:system:set default_locale   --value es_ES 2>/dev/null || true
occ config:system:set default_phone_region --value ES 2>/dev/null || true
occ config:system:set overwrite.cli.url --value "http://localhost:8080" 2>/dev/null || true

# Políticas de compartición seguras para colegio
occ config:app:set core shareapi_allow_link --value=yes 2>/dev/null || true
occ config:app:set core shareapi_default_expire_date --value=yes 2>/dev/null || true
occ config:app:set core shareapi_expire_after_n_days --value=30 2>/dev/null || true
occ config:app:set core shareapi_enforce_links_password --value=yes 2>/dev/null || true
occ config:app:set core shareapi_only_share_with_group_members --value=yes 2>/dev/null || true
occ config:app:set core shareapi_allow_public_upload --value=no 2>/dev/null || true

# Cuotas por defecto (puedes cambiar)
occ config:app:set files default_quota --value "2 GB" 2>/dev/null || true

echo "[*] Estructura inicial (skeleton) para altas nuevas..."
docker compose exec -T app bash -lc '
  mkdir -p /var/www/html/custom_skeleton/{Alumnado,Profesorado,Compartido}
  printf "Bienvenido/a a la Intranet del Colegio.\n" > /var/www/html/custom_skeleton/LEEME.txt
  printf "Normas de uso y convivencia digital.\n" > /var/www/html/custom_skeleton/Reglamento.txt
  printf "Guía rápida de Nextcloud para el centro.\n" > /var/www/html/custom_skeleton/Guia_Nextcloud.txt
' 2>/dev/null || true
occ config:system:set skeletondirectory --value /var/www/html/custom_skeleton 2>/dev/null || true

echo "[*] Creación de grupos de perfiles y departamentos..."
for g in profesorado alumnado direccion secretaria tic orientacion; do
  occ group:add "$g" 2>/dev/null || true
done

echo "[*] Creación de grupos por cursos (puedes editar la lista)..."
CURSOS=( "1ESO" "2ESO" "3ESO" "4ESO" "1BACH" "2BACH" "FP1" "FP2" )
for c in "${CURSOS[@]}"; do
  occ group:add "$c" 2>/dev/null || true
done

echo "[*] Carpetas de grupo para departamentos y comunicación interna..."
make_folder() { # nombre -> id
  local name="$1"
  local out id
  out="$(occ groupfolders:create "$name" 2>/dev/null || true)"
  id="$(echo "$out" | awk '{for(i=1;i<=NF;i++){if($i ~ /^[0-9]+$/){x=$i}}} END{print x}')"
  if [ -z "$id" ]; then id="$(occ groupfolders:list | awk -v n="$name" '$0 ~ n {print $1; exit}')"; fi
  printf "%s" "$id"
}
set_perm() {  # id grupo permisos
  occ groupfolders:group "$1" "$2" --permissions "$3" 2>/dev/null || true
}

# Departamentos
ID_CLAUSTRO="$(make_folder 'Claustro - Profesorado')"        # Solo profesorado
ID_SECRETARIA="$(make_folder 'Secretaría')"                   # Solo secretaría
ID_DIRECCION="$(make_folder 'Dirección')"                     # Dirección + profesorado (lectura)
ID_COM_ALUMNADO="$(make_folder 'Comunicados Alumnado')"       # Profes: editar; alumnado: leer

# Permisos: 31=RWCDS (read|write|create|delete|share), 1=read
if [ -n "$ID_CLAUSTRO" ]; then set_perm "$ID_CLAUSTRO" profesorado 31; fi
if [ -n "$ID_SECRETARIA" ]; then set_perm "$ID_SECRETARIA" secretaria 31; fi
if [ -n "$ID_DIRECCION" ]; then
  set_perm "$ID_DIRECCION" direccion 31
  set_perm "$ID_DIRECCION" profesorado 1
fi
if [ -n "$ID_COM_ALUMNADO" ]; then
  set_perm "$ID_COM_ALUMNADO" profesorado 31
  set_perm "$ID_COM_ALUMNADO" alumnado 1
fi

# Cursos (carpeta por curso con permisos de lectura para alumnado y edición para profesorado)
for c in "${CURSOS[@]}"; do
  FID="$(make_folder "Curso ${c} - Material")"
  if [ -n "$FID" ]; then
    set_perm "$FID" profesorado 31
    set_perm "$FID" "$c" 1
  fi
done

# (Opcional) cuota para carpetas de grupo (ej. 50 GB para Comunicados Alumnado)
# occ groupfolders:quota "$ID_COM_ALUMNADO" 50G

echo "[*] Usuarios de ejemplo (profe y dos alumnos) para probar y capturar..."
mkuser () { # user pass nombre grupos(coma) cuota
  local u="$1" p="$2" n="$3" gs="$4" q="$5"
  if ! occ user:list 2>/dev/null | grep -qE "  - ${u}:"; then
    printf "%s\n%s\n" "$p" "$p" | occ user:add --display-name="$n" "$u" 2>/dev/null || true
  fi
  IFS=',' read -ra arr <<< "$gs"
  for gg in "${arr[@]}"; do 
    occ group:adduser "$gg" "$u" 2>/dev/null || true
  done
  occ user:setting "$u" files quota "$q" 2>/dev/null || true
}
mkuser profe 'Profe#2025!Abc' 'Profesor/a Referente' 'profesorado,1ESO' '5 GB'
mkuser alu1  'Alu1#2025!Abc'  'Alumno 1 (1ESO)'     'alumnado,1ESO'   '1 GB'
mkuser alu2  'Alu2#2025!Abc'  'Alumno 2 (1ESO)'     'alumnado,1ESO'   '1 GB'

echo
echo "==== Resumen ===="
occ group:list 2>/dev/null || true
echo
occ user:list 2>/dev/null || true
echo
occ groupfolders:list 2>/dev/null || true
echo "[✓] Configuración de intranet escolar finalizada."
