#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Instalador Único - Intranet Escolar Nextcloud
# Despliegue automático completo
# ============================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[⚠]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }
log_step() { echo -e "${CYAN}══${NC} $*"; }

echo ""
echo -e "${BOLD}${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║   INSTALADOR AUTOMÁTICO - INTRANET ESCOLAR NEXTCLOUD      ║${NC}"
echo -e "${BOLD}${CYAN}║   Proyecto Final ASIR                                      ║${NC}"
echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# 1. VERIFICAR REQUISITOS
# ============================================
log_step "1. Verificando requisitos del sistema"
echo ""

ALL_OK=true

for cmd in docker git curl bash; do
  if command -v $cmd &>/dev/null; then
    log_success "$cmd instalado"
  else
    log_error "$cmd NO instalado"
    ALL_OK=false
  fi
done

if docker compose version &>/dev/null; then
  log_success "docker compose instalado"
else
  log_error "docker compose NO instalado"
  ALL_OK=false
fi

if [[ "$ALL_OK" == "false" ]]; then
  echo ""
  log_error "Faltan dependencias. Instala con:"
  echo "  sudo apt update && sudo apt install -y docker.io docker-compose-plugin git curl"
  echo "  sudo usermod -aG docker \$USER && newgrp docker"
  exit 1
fi

echo ""

# ============================================
# 2. VERIFICAR ESTRUCTURA DEL PROYECTO
# ============================================
log_step "2. Verificando estructura del proyecto"
echo ""

if [[ ! -f "docker-compose.yml" ]]; then
  log_error "Este script debe ejecutarse desde el directorio raíz del proyecto"
  log_info "Estructura esperada: docker-compose.yml, scripts/, .env.example"
  exit 1
fi

log_success "Estructura correcta"
echo ""

# ============================================
# 3. CREAR .ENV SI NO EXISTE
# ============================================
log_step "3. Configurando variables de entorno"
echo ""

if [[ ! -f ".env" ]]; then
  if [[ -f ".env.example" ]]; then
    cp .env.example .env
    log_success "Archivo .env creado desde plantilla"
  else
    log_error "No existe .env.example"
    exit 1
  fi
else
  log_info "Archivo .env ya existe (no se sobrescribe)"
fi

# Cargar variables
set -a
source .env 2>/dev/null || true
set +a

echo ""

# ============================================
# 4. LEVANTAR SERVICIOS DOCKER
# ============================================
log_step "4. Levantando servicios Docker"
echo ""

log_info "Ejecutando: docker compose up -d..."
if docker compose -f docker-compose.yml -f compose.db.healthpatch.yml up -d; then
  log_success "Contenedores iniciados"
else
  log_error "Error al iniciar contenedores"
  exit 1
fi

echo ""

# ============================================
# 5. ESPERAR A QUE DB ESTÉ HEALTHY
# ============================================
log_step "5. Esperando a que MariaDB esté healthy"
echo ""

MAX_WAIT=120
elapsed=0

while [ $elapsed -lt $MAX_WAIT ]; do
  if docker compose ps db | grep -q "healthy"; then
    log_success "MariaDB está healthy"
    break
  fi
  echo -n "."
  sleep 5
  elapsed=$((elapsed + 5))
done

if [ $elapsed -ge $MAX_WAIT ]; then
  log_error "MariaDB no alcanzó estado healthy en ${MAX_WAIT}s"
  log_info "Continuando de todos modos..."
fi

echo ""
echo ""

# ============================================
# 6. ESPERAR A QUE NEXTCLOUD RESPONDA
# ============================================
log_step "6. Esperando a que Nextcloud esté listo"
echo ""

MAX_WAIT=60
elapsed=0
OCC="docker compose exec -T -u www-data app php occ"

while [ $elapsed -lt $MAX_WAIT ]; do
  if $OCC status &>/dev/null; then
    log_success "Nextcloud responde correctamente"
    break
  fi
  echo -n "."
  sleep 3
  elapsed=$((elapsed + 3))
done

if [ $elapsed -ge $MAX_WAIT ]; then
  log_warning "Nextcloud tardó más de lo esperado, pero continuando..."
fi

echo ""
echo ""

# ============================================
# 7. EJECUTAR INICIALIZACIÓN AUTOMÁTICA
# ============================================
log_step "7. Ejecutando configuración automática"
echo ""

if [[ -f "scripts/init.sh" ]]; then
  log_info "Llamando a scripts/init.sh --auto..."
  bash scripts/init.sh --auto
else
  log_error "No se encuentra scripts/init.sh"
  exit 1
fi

echo ""

# ============================================
# 8. RESUMEN FINAL
# ============================================
echo ""
echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║         INSTALACIÓN COMPLETADA EXITOSAMENTE                ║${NC}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_success "Servicios disponibles:"
echo ""
echo -e "  Nextcloud:     ${CYAN}http://localhost:8080${NC}"
echo -e "  Uptime Kuma:   ${CYAN}http://localhost:3001${NC}"
echo ""

log_info "Verificaciones recomendadas:"
echo -e "  ${CYAN}docker compose ps${NC}                                      # Ver estado"
echo -e "  ${CYAN}docker compose exec -T -u www-data app php occ status${NC}  # Estado de Nextcloud"
echo -e "  ${CYAN}docker compose exec kuma curl -s -o /dev/null -w '%{http_code}' http://app/status.php${NC}"
echo ""

log_info "Usuarios de demo creados (ver credenciales en scripts/alta_colegio_basica.sh):"
echo "  • admin (administrador)"
echo "  • profe (profesorado)"
echo "  • alumno1, alumno2 (alumnado)"
echo ""

log_success "¡Intranet Escolar lista para usar!"
echo ""
