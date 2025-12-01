#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Configuración del Entorno Educativo
# Grupos, carpetas compartidas, políticas y theming
# ============================================

occ() { docker compose exec -u www-data -T app php occ "$@"; }

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }

echo ""
echo "================================================================"
echo "   Configuración del Entorno Educativo"
echo "   Intranet Escolar con Nextcloud"
echo "================================================================"
echo ""

log_info "Verificando instalación de Nextcloud..."
until occ status 2>/dev/null | grep -q "installed: true"; do
  log_info "Esperando a que Nextcloud esté instalado..."; sleep 5
done
log_success "Nextcloud instalado y accesible"
echo ""

log_info "Habilitando aplicaciones necesarias..."
occ app:enable theming 2>/dev/null || true
occ app:enable groupfolders 2>/dev/null || true
occ app:enable calendar 2>/dev/null || true
occ app:enable contacts 2>/dev/null || true
occ app:enable tasks 2>/dev/null || true
occ app:enable spreed 2>/dev/null || true
occ app:enable viewer 2>/dev/null || true
occ app:enable files_pdfviewer 2>/dev/null || true
log_success "Aplicaciones habilitadas"
echo ""

log_info "Configurando branding del centro educativo..."
CENTER_NAME="Intranet Escolar - Centro Educativo"
CENTER_SLOGAN="Aprender, Compartir, Colaborar"
CENTER_URL="https://www.centro-educativo.edu"
CENTER_COLOR="#0b5ed7"

occ theming:config name "$CENTER_NAME" 2>/dev/null || true
occ theming:config slogan "$CENTER_SLOGAN" 2>/dev/null || true
occ theming:config url "$CENTER_URL" 2>/dev/null || true
occ theming:config color "$CENTER_COLOR" 2>/dev/null || true
log_success "Theming configurado"
echo ""

log_info "Configurando ajustes globales..."
occ config:system:set default_language --value es 2>/dev/null || true
occ config:system:set default_locale   --value es_ES 2>/dev/null || true
occ config:system:set default_phone_region --value ES 2>/dev/null || true
occ config:system:set overwrite.cli.url --value "http://localhost:8080" 2>/dev/null || true
log_success "Configuración regional aplicada"
echo ""

log_info "Aplicando políticas de compartición seguras..."
occ config:app:set core shareapi_allow_links --value=yes 2>/dev/null || true
occ config:app:set core shareapi_default_expire_date --value=yes 2>/dev/null || true
occ config:app:set core shareapi_expire_after_n_days --value=30 2>/dev/null || true
occ config:app:set core shareapi_enforce_links_password --value=yes 2>/dev/null || true
occ config:app:set core shareapi_only_share_with_group_members --value=yes 2>/dev/null || true
occ config:app:set core shareapi_allow_public_upload --value=no 2>/dev/null || true
occ config:app:set files default_quota --value "2 GB" 2>/dev/null || true
log_success "Políticas de compartición y cuotas configuradas"
echo ""

log_info "Creando estructura skeleton para nuevos usuarios..."
docker compose exec -T app bash -lc '
  mkdir -p /var/www/html/custom_skeleton/{Alumnado,Profesorado,Compartido}
  printf "Bienvenido/a a la Intranet del Centro Educativo.\n" > /var/www/html/custom_skeleton/LEEME.txt
  printf "Normas de uso y convivencia digital.\n" > /var/www/html/custom_skeleton/Reglamento.txt
  printf "Guía rápida de Nextcloud.\n" > /var/www/html/custom_skeleton/Guia_Nextcloud.txt
' 2>/dev/null || true
occ config:system:set skeletondirectory --value /var/www/html/custom_skeleton 2>/dev/null || true
log_success "Skeleton directory configurado"
echo ""

log_info "Creando grupos de perfiles y departamentos..."
for g in profesorado alumnado direccion secretaria tic orientacion; do
  occ group:add "$g" 2>/dev/null || true
done
log_success "Grupos de perfiles creados"
echo ""

log_info "Creando grupos por cursos..."
CURSOS=( "1ESO" "2ESO" "3ESO" "4ESO" "1BACH" "2BACH" "FP1" "FP2" )
for c in "${CURSOS[@]}"; do
  occ group:add "$c" 2>/dev/null || true
done
log_success "Grupos de cursos creados"
echo ""

log_info "Creando carpetas de grupo (Group Folders)..."
make_folder() {
  local name="$1"
  local out id
  out="$(occ groupfolders:create "$name" 2>/dev/null || true)"
  id="$(echo "$out" | awk '{for(i=1;i<=NF;i++){if($i ~ /^[0-9]+$/){x=$i}}} END{print x}')"
  if [ -z "$id" ]; then id="$(occ groupfolders:list | awk -v n="$name" '$0 ~ n {print $1; exit}')"; fi
  printf "%s" "$id"
}

set_perm() {
  occ groupfolders:group "$1" "$2" --permissions "$3" 2>/dev/null || true
}

log_info "Configurando carpetas de departamentos..."
ID_CLAUSTRO="$(make_folder 'Claustro - Profesorado')"
ID_SECRETARIA="$(make_folder 'Secretaría')"
ID_DIRECCION="$(make_folder 'Dirección')"
ID_COM_ALUMNADO="$(make_folder 'Comunicados Alumnado')"

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
log_success "Carpetas de departamentos configuradas"
echo ""

log_info "Configurando carpetas por curso..."
for c in "${CURSOS[@]}"; do
  FID="$(make_folder "Curso ${c} - Material")"
  if [ -n "$FID" ]; then
    set_perm "$FID" profesorado 31
    set_perm "$FID" "$c" 1
  fi
done
log_success "Carpetas por curso configuradas"
echo ""

log_info "Configuración de usuarios de ejemplo..."
mkuser () {
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
mkuser alumno1 'Alu1#2025!Abc' 'Alumno 1 (1ESO)' 'alumnado,1ESO' '1 GB'
mkuser alumno2 'Alu2#2025!Abc' 'Alumno 2 (1ESO)' 'alumnado,1ESO' '1 GB'
log_success "Usuarios de ejemplo configurados"
echo ""

echo "================================================================"
echo "   RESUMEN DE CONFIGURACIÓN"
echo "================================================================"
echo ""
log_info "Grupos creados:"
occ group:list 2>/dev/null | head -20 || true
echo ""
log_info "Usuarios creados:"
occ user:list 2>/dev/null || true
echo ""
log_info "Carpetas de grupo (Group Folders):"
occ groupfolders:list 2>/dev/null || true
echo ""
log_success "Configuración del entorno educativo finalizada"
echo ""
