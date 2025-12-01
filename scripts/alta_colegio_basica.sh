#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Alta de Usuarios Básicos de Demostración
# Proyecto Final ASIR
# ============================================

occ() { docker compose exec -u www-data -T app php occ "$@"; }

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[AVISO]${NC} $*"; }

echo ""
echo "================================================================"
echo "   Alta de Usuarios Básicos de Demostración"
echo "   Intranet Escolar con Nextcloud"
echo "================================================================"
echo ""

log_info "Verificando instalación de Nextcloud..."
until occ status 2>/dev/null | grep -q "installed: true"; do
  log_info "Esperando a que Nextcloud esté instalado..."; sleep 5
done
log_success "Nextcloud instalado y accesible"
echo ""

log_info "Creando grupo de clase básico..."
occ group:add clase 2>/dev/null || true
log_success "Grupo 'clase' creado"
echo ""

mkuser () {
  local u="$1" p="$2" d="$3" q="$4"
  if ! occ user:list 2>/dev/null | grep -qE "  - ${u}:"; then
    log_info "Creando usuario: $u ($d)"
    printf "%s\n%s\n" "$p" "$p" | occ user:add --display-name="$d" --group clase "$u" 2>/dev/null || true
    occ user:setting "$u" files quota "$q" 2>/dev/null || true
    log_success "Usuario '$u' creado correctamente"
  else
    log_warning "Usuario '$u' ya existe, omitiendo"
  fi
}

log_info "Creando usuarios de demostración..."
echo ""
mkuser profe   'Profe#2025!Abc' 'Profesor/a Referente' '5 GB'
mkuser alumno1 'Alu1#2025!Abc'  'Alumno 1 (1ESO)'      '1 GB'
mkuser alumno2 'Alu2#2025!Abc'  'Alumno 2 (1ESO)'      '1 GB'

echo ""
echo "================================================================"
echo "   RESUMEN DE USUARIOS CREADOS"
echo "================================================================"
echo ""
log_info "Listado de usuarios:"
occ user:list 2>/dev/null || true
echo ""
log_info "Listado de grupos:"
occ group:list 2>/dev/null || true
echo ""
log_success "Alta de usuarios básicos completada"
echo ""
