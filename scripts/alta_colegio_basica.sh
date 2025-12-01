#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Alta de Usuarios de Demostración
# Crea usuarios ejemplo para el proyecto
# ============================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[⚠]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }

OCC="docker compose exec -T -u www-data app php occ"

# ============================================
# Crear usuario con grupos y cuota
# ============================================
create_user() {
  local username="$1"
  local password="$2"
  local displayname="$3"
  shift 3
  local groups=("$@")
  
  # Crear usuario si no existe
  if $OCC user:info "$username" &>/dev/null; then
    log_info "Usuario '$username' ya existe"
  else
    # Usar OC_PASS para pasar contraseña por variable de entorno
    if OC_PASS="$password" $OCC user:add "$username" --password-from-env --display-name="$displayname" 2>/dev/null; then
      log_success "Usuario '$username' creado"
    else
      log_error "Error al crear usuario '$username'"
      return 1
    fi
  fi
  
  # Asignar grupos
  for group in "${groups[@]}"; do
    if $OCC group:adduser "$group" "$username" 2>/dev/null; then
      log_success "  → Añadido a grupo '$group'"
    else
      log_info "  → Ya está en grupo '$group'"
    fi
  done
}

# ============================================
# Configurar cuota
# ============================================
set_quota() {
  local username="$1"
  local quota="$2"
  
  if $OCC user:setting "$username" files quota "$quota" 2>/dev/null; then
    log_success "  → Cuota configurada: $quota"
  else
    log_warning "  → No se pudo configurar cuota"
  fi
}

# ============================================
# CREAR USUARIOS DE DEMO
# ============================================
echo ""
log_info "Creando usuarios de demostración..."
echo ""

# PROFESOR
log_info "Creando usuario: profe"
create_user "profe" "Profe123!" "Profesor Demo" "profesorado" "1ESO"
set_quota "profe" "5GB"
echo ""

# ALUMNO 1
log_info "Creando usuario: alumno1"
create_user "alumno1" "Alumno123!" "Alumno Uno" "alumnado" "1ESO" "clase"
set_quota "alumno1" "1GB"
echo ""

# ALUMNO 2
log_info "Creando usuario: alumno2"
create_user "alumno2" "Alumno123!" "Alumno Dos" "alumnado" "1ESO" "clase"
set_quota "alumno2" "1GB"
echo ""

# ============================================
# RESUMEN DE CREDENCIALES
# ============================================
echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              CREDENCIALES DE DEMOSTRACIÓN                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}ADMINISTRADOR:${NC}"
echo "  admin / (ver .env: NEXTCLOUD_ADMIN_PASSWORD)"
echo ""

echo -e "${YELLOW}PROFESOR:${NC}"
echo "  profe / Profe123!"
echo "  Grupos: profesorado, 1ESO"
echo "  Cuota: 5 GB"
echo ""

echo -e "${YELLOW}ALUMNOS:${NC}"
echo "  alumno1 / Alumno123!"
echo "  alumno2 / Alumno123!"
echo "  Grupos: alumnado, 1ESO, clase"
echo "  Cuota: 1 GB cada uno"
echo ""

echo -e "${GREEN}Acceso:${NC} http://localhost:8080"
echo ""

log_success "Usuarios de demostración creados correctamente"
