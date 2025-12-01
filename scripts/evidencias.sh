#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Generación de Evidencias Técnicas
# Captura información del sistema para documentación
# ============================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

LOGS_DIR="docs/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ============================================
# Crear directorio de logs
# ============================================
setup_logs_dir() {
  mkdir -p "$LOGS_DIR"
  log_info "Directorio de evidencias: $LOGS_DIR"
  echo ""
}

# ============================================
# Información del sistema
# ============================================
capture_system_info() {
  log_info "Capturando información del sistema..."
  
  {
    echo "================================"
    echo "INFORMACIÓN DEL SISTEMA"
    echo "================================"
    echo "Fecha: $(date)"
    echo ""
    
    echo "--- Sistema Operativo ---"
    uname -a || true
    echo ""
    
    if [ -f /etc/os-release ]; then
      cat /etc/os-release
      echo ""
    fi
    
    echo "--- Docker ---"
    docker --version || true
    docker compose version || true
    echo ""
    
    echo "--- Recursos ---"
    free -h || true
    echo ""
    df -h || true
    echo ""
    
  } > "$LOGS_DIR/sistema.txt"
  
  log_success "sistema.txt"
}

# ============================================
# Estado de Docker
# ============================================
capture_docker_status() {
  log_info "Capturando estado de Docker..."
  
  {
    echo "================================"
    echo "CONTENEDORES DOCKER"
    echo "================================"
    echo "Fecha: $(date)"
    echo ""
    
    docker compose ps
    
  } > "$LOGS_DIR/docker_ps.txt" 2>&1
  
  log_success "docker_ps.txt"
  
  # Logs de contenedores
  log_info "Capturando logs de contenedores..."
  docker compose logs --tail=100 > "$LOGS_DIR/docker_logs.txt" 2>&1 || true
  log_success "docker_logs.txt"
}

# ============================================
# Estado de la base de datos
# ============================================
capture_db_status() {
  log_info "Capturando estado de la base de datos..."
  
  {
    echo "================================"
    echo "BASE DE DATOS MARIADB"
    echo "================================"
    echo "Fecha: $(date)"
    echo ""
    
    echo "--- Ping a MariaDB ---"
    docker compose exec -T db mysqladmin ping -h localhost 2>&1 || echo "Error al conectar"
    echo ""
    
    echo "--- Variables de MariaDB ---"
    docker compose exec -T db mysql -u root -p"${MYSQL_ROOT_PASSWORD:-nextcloud}" \
      -e "SHOW VARIABLES LIKE '%version%';" 2>&1 || echo "Error al obtener variables"
    echo ""
    
    echo "--- Bases de datos ---"
    docker compose exec -T db mysql -u root -p"${MYSQL_ROOT_PASSWORD:-nextcloud}" \
      -e "SHOW DATABASES;" 2>&1 || echo "Error al listar databases"
    
  } > "$LOGS_DIR/db_logs.txt"
  
  log_success "db_logs.txt"
}

# ============================================
# Estado de Nextcloud
# ============================================
capture_nextcloud_status() {
  log_info "Capturando estado de Nextcloud..."
  
  local OCC="docker compose exec -T -u www-data app php occ"
  
  # Status general
  {
    echo "================================"
    echo "NEXTCLOUD - ESTADO GENERAL"
    echo "================================"
    echo "Fecha: $(date)"
    echo ""
    
    $OCC status 2>&1 || echo "Error al obtener status"
    
  } > "$LOGS_DIR/occ_status.txt"
  
  log_success "occ_status.txt"
  
  # Aplicaciones instaladas
  {
    echo "================================"
    echo "NEXTCLOUD - APLICACIONES"
    echo "================================"
    echo "Fecha: $(date)"
    echo ""
    
    echo "--- Aplicaciones habilitadas ---"
    $OCC app:list --enabled 2>&1 || echo "Error"
    echo ""
    
    echo "--- Aplicaciones deshabilitadas ---"
    $OCC app:list --disabled 2>&1 || echo "Error"
    
  } > "$LOGS_DIR/occ_apps.txt"
  
  log_success "occ_apps.txt"
  
  # Usuarios
  {
    echo "================================"
    echo "NEXTCLOUD - USUARIOS"
    echo "================================"
    echo "Fecha: $(date)"
    echo ""
    
    $OCC user:list 2>&1 || echo "Error al listar usuarios"
    
  } > "$LOGS_DIR/occ_users.txt"
  
  log_success "occ_users.txt"
  
  # Grupos
  {
    echo "================================"
    echo "NEXTCLOUD - GRUPOS"
    echo "================================"
    echo "Fecha: $(date)"
    echo ""
    
    $OCC group:list 2>&1 || echo "Error al listar grupos"
    
  } > "$LOGS_DIR/occ_groups.txt"
  
  log_success "occ_groups.txt"
  
  # Groupfolders
  {
    echo "================================"
    echo "NEXTCLOUD - CARPETAS GRUPALES"
    echo "================================"
    echo "Fecha: $(date)"
    echo ""
    
    $OCC groupfolders:list 2>&1 || echo "App groupfolders no disponible"
    
  } > "$LOGS_DIR/occ_groupfolders.txt"
  
  log_success "occ_groupfolders.txt"
}

# ============================================
# Pruebas HTTP
# ============================================
capture_http_tests() {
  log_info "Realizando pruebas HTTP..."
  
  {
    echo "================================"
    echo "PRUEBAS HTTP"
    echo "================================"
    echo "Fecha: $(date)"
    echo ""
    
    echo "--- Headers de Nextcloud ---"
    curl -I http://localhost:8080 2>&1 || echo "Error al conectar"
    echo ""
    
    echo "--- Status.php ---"
    curl -s http://localhost:8080/status.php 2>&1 || echo "Error"
    echo ""
    
    echo "--- Headers de Uptime Kuma ---"
    curl -I http://localhost:3001 2>&1 || echo "Error al conectar"
    
  } > "$LOGS_DIR/http_headers_app.txt"
  
  log_success "http_headers_app.txt"
}

# ============================================
# Generar compose unificado
# ============================================
generate_merged_compose() {
  log_info "Generando docker-compose unificado..."
  
  if [ -f "docker-compose.yml" ] && [ -f "compose.db.healthpatch.yml" ]; then
    docker compose -f docker-compose.yml -f compose.db.healthpatch.yml config \
      > "$LOGS_DIR/compose_merged.yml" 2>&1 || true
    log_success "compose_merged.yml"
  fi
}

# ============================================
# Resumen
# ============================================
show_summary() {
  echo ""
  log_success "Evidencias generadas en: $LOGS_DIR"
  echo ""
  
  echo "Archivos generados:"
  ls -lh "$LOGS_DIR"/*.txt "$LOGS_DIR"/*.yml 2>/dev/null || true
  echo ""
  
  log_info "Puedes revisar las evidencias en la carpeta docs/logs/"
  echo ""
}

# ============================================
# Main
# ============================================
main() {
  if [ ! -f "docker-compose.yml" ]; then
    log_error "Este script debe ejecutarse desde el directorio raíz del proyecto"
    exit 1
  fi
  
  echo ""
  log_info "Generando evidencias técnicas..."
  echo ""
  
  setup_logs_dir
  capture_system_info
  capture_docker_status
  capture_db_status
  capture_nextcloud_status
  capture_http_tests
  generate_merged_compose
  show_summary
}

main "$@"
