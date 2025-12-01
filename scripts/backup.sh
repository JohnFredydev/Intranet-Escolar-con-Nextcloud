#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Script de Backup
# Realiza backup de datos y configuración
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
log_warning() { echo -e "${YELLOW}[AVISO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${TIMESTAMP}"

# ============================================
# Crear directorio de backups
# ============================================
setup_backup_dir() {
  mkdir -p "$BACKUP_DIR/$BACKUP_NAME"
  log_info "Directorio de backup: $BACKUP_DIR/$BACKUP_NAME"
  echo ""
}

# ============================================
# Backup de base de datos
# ============================================
backup_database() {
  log_info "Realizando backup de la base de datos..."
  
  local db_password="${MYSQL_ROOT_PASSWORD:-nextcloud}"
  
  if docker compose exec -T db mysqldump \
    -u root -p"$db_password" \
    --all-databases \
    --single-transaction \
    --quick \
    --lock-tables=false \
    > "$BACKUP_DIR/$BACKUP_NAME/database.sql" 2>/dev/null; then
    
    log_success "Backup de base de datos completado"
  else
    log_error "Error al hacer backup de la base de datos"
    return 1
  fi
  
  echo ""
}

# ============================================
# Backup de archivos de Nextcloud
# ============================================
backup_nextcloud_data() {
  log_info "Realizando backup de datos de Nextcloud..."
  
  # Copiar archivos importantes
  docker compose exec -T -u www-data app tar czf - \
    -C /var/www/html config \
    2>/dev/null > "$BACKUP_DIR/$BACKUP_NAME/nextcloud_config.tar.gz" || true
  
  log_success "Backup de configuración de Nextcloud completado"
  echo ""
}

# ============================================
# Backup de docker-compose y .env
# ============================================
backup_compose_files() {
  log_info "Copiando archivos de configuración..."
  
  [ -f "docker-compose.yml" ] && cp docker-compose.yml "$BACKUP_DIR/$BACKUP_NAME/" || true
  [ -f "compose.db.healthpatch.yml" ] && cp compose.db.healthpatch.yml "$BACKUP_DIR/$BACKUP_NAME/" || true
  [ -f ".env" ] && cp .env "$BACKUP_DIR/$BACKUP_NAME/" || true
  
  log_success "Archivos de configuración copiados"
  echo ""
}

# ============================================
# Comprimir backup
# ============================================
compress_backup() {
  log_info "Comprimiendo backup..."
  
  cd "$BACKUP_DIR"
  tar czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
  rm -rf "$BACKUP_NAME"
  cd - > /dev/null
  
  log_success "Backup comprimido: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
  echo ""
}

# ============================================
# Resumen
# ============================================
show_summary() {
  local backup_size=$(du -h "$BACKUP_DIR/${BACKUP_NAME}.tar.gz" | cut -f1)
  
  echo ""
  log_success "Backup completado exitosamente"
  echo ""
  echo "  Archivo: ${CYAN}$BACKUP_DIR/${BACKUP_NAME}.tar.gz${NC}"
  echo "  Tamaño:  ${CYAN}$backup_size${NC}"
  echo ""
  
  log_info "Para restaurar este backup, consulta la documentación"
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
  
  # Verificar que los servicios están corriendo
  if ! docker compose ps app | grep -q "Up"; then
    log_error "Los servicios no están ejecutándose"
    exit 1
  fi
  
  echo ""
  log_info "Iniciando proceso de backup..."
  echo ""
  
  setup_backup_dir
  backup_database
  backup_nextcloud_data
  backup_compose_files
  compress_backup
  show_summary
}

main "$@"
