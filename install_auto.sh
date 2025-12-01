#!/usr/bin/env bash
set -Eeuo pipefail

#================================================================
# Instalador Automático - Intranet Escolar Nextcloud
# Un solo comando para desplegar TODO el sistema
# Proyecto Final ASIR
#================================================================

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
log_title() { echo -e "${BOLD}${CYAN}$*${NC}"; }

echo ""
log_title "╔════════════════════════════════════════════════════════════╗"
log_title "║   INSTALADOR AUTOMÁTICO - INTRANET ESCOLAR NEXTCLOUD      ║"
log_title "║   Proyecto Final ASIR - Despliegue en un Solo Comando     ║"
log_title "╚════════════════════════════════════════════════════════════╝"
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

log_success "Todos los requisitos satisfechos"
echo ""

# ============================================
# 2. CREAR .ENV SI NO EXISTE
# ============================================
log_step "2. Configurando variables de entorno"
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
  log_success "Archivo .env ya existe"
fi

# Cargar variables
set -a
source .env 2>/dev/null || true
set +a

echo ""

# ============================================
# 3. LEVANTAR SERVICIOS DOCKER
# ============================================
log_step "3. Levantando servicios Docker"
echo ""

log_info "Ejecutando: docker compose up -d..."
if docker compose -f docker-compose.yml -f compose.db.healthpatch.yml up -d; then
  log_success "Contenedores iniciados"
else
  log_error "Error al iniciar contenedores"
  exit 1
fi

echo ""
log_info "Esperando a que los servicios estén saludables..."
MAX_WAIT=120
elapsed=0

while [ $elapsed -lt $MAX_WAIT ]; do
  if docker compose ps | grep -E "(db|app)" | grep -q "healthy\|Up"; then
    log_success "Servicios están saludables"
    break
  fi
  echo -n "."
  sleep 5
  elapsed=$((elapsed + 5))
done

if [ $elapsed -ge $MAX_WAIT ]; then
  log_error "Timeout esperando servicios"
  log_info "Verifica con: docker compose ps"
  log_info "Logs: docker compose logs"
  exit 1
fi

echo ""

# ============================================
# 4. ESPERAR A QUE NEXTCLOUD ESTÉ INSTALADO
# ============================================
log_step "4. Esperando instalación de Nextcloud"
echo ""

log_info "Nextcloud se está instalando automáticamente..."
MAX_WAIT=180
elapsed=0

until docker compose exec -T -u www-data app php occ status 2>/dev/null | grep -q "installed: true"; do
  if [ $elapsed -ge $MAX_WAIT ]; then
    log_error "Timeout esperando instalación de Nextcloud"
    exit 1
  fi
  echo -n "."
  sleep 10
  elapsed=$((elapsed + 10))
done

log_success "Nextcloud instalado correctamente"
echo ""

# ============================================
# 5. CONFIGURAR NEXTCLOUD (COLE_SETUP)
# ============================================
log_step "5. Configurando entorno educativo"
echo ""

if [[ -f "scripts/cole_setup.sh" ]]; then
  log_info "Ejecutando scripts/cole_setup.sh..."
  bash scripts/cole_setup.sh
  log_success "Configuración educativa completada"
else
  log_warning "scripts/cole_setup.sh no encontrado"
fi

echo ""

# ============================================
# 6. CONFIGURAR UPTIME KUMA
# ============================================
log_step "6. Configurando Uptime Kuma"
echo ""

if [[ -f "scripts/setup_kuma.sh" ]]; then
  log_info "Ejecutando scripts/setup_kuma.sh..."
  if bash scripts/setup_kuma.sh; then
    log_success "Uptime Kuma configurado"
  else
    log_warning "Uptime Kuma requiere configuración manual"
    log_info "Accede a: http://localhost:3001"
  fi
else
  log_warning "scripts/setup_kuma.sh no encontrado"
fi

echo ""

# ============================================
# 7. VALIDAR DESPLIEGUE
# ============================================
log_step "7. Validando despliegue completo"
echo ""

if [[ -f "scripts/validate.sh" ]]; then
  log_info "Ejecutando scripts/validate.sh..."
  echo ""
  
  if bash scripts/validate.sh; then
    VALIDATION_OK=true
  else
    VALIDATION_OK=false
  fi
else
  log_warning "scripts/validate.sh no encontrado"
  VALIDATION_OK=true  # No fallar si no existe
fi

echo ""

# ============================================
# 8. RESUMEN FINAL
# ============================================
echo ""
log_title "╔════════════════════════════════════════════════════════════╗"
log_title "║         DESPLIEGUE COMPLETADO                              ║"
log_title "╚════════════════════════════════════════════════════════════╝"
echo ""

if [[ "$VALIDATION_OK" == "true" ]]; then
  log_success "Sistema desplegado y validado correctamente"
  echo ""
  log_info "Servicios disponibles:"
  echo "  → Nextcloud:    ${CYAN}http://localhost:8080${NC}"
  echo "  → Uptime Kuma:  ${CYAN}http://localhost:3001${NC}"
  echo ""
  log_info "Credenciales de demo:"
  echo "  Nextcloud:"
  echo "    • admin    / Admin#2025!Cole"
  echo "    • profe    / Profe#2025!Abc"
  echo "    • alumno1  / Alu1#2025!Abc"
  echo "  Uptime Kuma:"
  echo "    • admin    / Admin#2025!Kuma"
  echo ""
  log_warning "⚠ Estas credenciales son SOLO para demostración"
  echo ""
  log_info "Comandos útiles:"
  echo "  ${CYAN}docker compose ps${NC}              # Estado de servicios"
  echo "  ${CYAN}docker compose logs -f app${NC}     # Logs de Nextcloud"
  echo "  ${CYAN}bash scripts/validate.sh${NC}       # Re-validar sistema"
  echo "  ${CYAN}bash scripts/backup.sh${NC}         # Crear backup"
  echo ""
  exit 0
else
  log_error "Se detectaron errores durante la validación"
  log_info "Revisa los mensajes arriba para más detalles"
  echo ""
  exit 1
fi
