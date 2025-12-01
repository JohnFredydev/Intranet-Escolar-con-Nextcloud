#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Script de Inicialización Completa
# Despliegue automático de la Intranet Escolar
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

# Detectar modo automático
AUTO_MODE=false
if [[ "${1:-}" == "--auto" ]]; then
  AUTO_MODE=true
  log_info "Modo automático activado"
  echo ""
fi

# ============================================
# Verificar estructura
# ============================================
if [ ! -f "docker-compose.yml" ]; then
  log_error "Este script debe ejecutarse desde el directorio raíz del proyecto"
  exit 1
fi

# ============================================
# 1. CONFIGURAR ENTORNO EDUCATIVO
# ============================================
log_step "1. Configurando entorno educativo de Nextcloud"
echo ""

if [ -f "scripts/cole_setup.sh" ]; then
  bash scripts/cole_setup.sh
else
  log_error "No se encuentra scripts/cole_setup.sh"
  exit 1
fi

echo ""

# ============================================
# 2. CREAR USUARIOS DE DEMOSTRACIÓN
# ============================================
log_step "2. Creando usuarios de demostración"
echo ""

if [ -f "scripts/alta_colegio_basica.sh" ]; then
  bash scripts/alta_colegio_basica.sh
else
  log_warning "No se encuentra scripts/alta_colegio_basica.sh, saltando..."
fi

echo ""

# ============================================
# 3. GENERAR EVIDENCIAS (OPCIONAL)
# ============================================
if [[ "$AUTO_MODE" == "true" ]]; then
  log_step "3. Generando evidencias técnicas"
  echo ""
  
  if [ -f "scripts/evidencias.sh" ]; then
    bash scripts/evidencias.sh || log_warning "Error al generar evidencias (no crítico)"
  else
    log_info "No se encuentra scripts/evidencias.sh, creando evidencias básicas..."
    mkdir -p docs/logs
    docker compose ps > docs/logs/docker_ps.txt 2>&1 || true
    docker compose exec -T -u www-data app php occ status > docs/logs/occ_status.txt 2>&1 || true
    log_success "Evidencias básicas generadas"
  fi
  
  echo ""
fi

# ============================================
# RESUMEN FINAL
# ============================================
echo ""
echo -e "${BOLD}${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║         CONFIGURACIÓN COMPLETADA EXITOSAMENTE              ║${NC}"
echo -e "${BOLD}${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

log_success "Entorno educativo configurado correctamente"
echo ""
