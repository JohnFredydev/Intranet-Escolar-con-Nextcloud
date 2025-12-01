#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Importar Imágenes Docker Offline
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

# Directorio offline (puede pasarse como argumento)
OFFLINE_DIR="${1:-docker-images-offline}"

# ============================================
# Buscar directorio más reciente
# ============================================
find_latest_offline_dir() {
  if [ -d "$OFFLINE_DIR" ]; then
    # Si es un directorio específico con timestamp
    if [[ "$OFFLINE_DIR" =~ 202[0-9]{5}_[0-9]{6} ]]; then
      echo "$OFFLINE_DIR"
      return 0
    fi
    
    # Buscar subdirectorio más reciente
    local latest=$(find "$OFFLINE_DIR" -maxdepth 1 -type d -name "202*" | sort -r | head -1)
    if [ -n "$latest" ]; then
      echo "$latest"
      return 0
    fi
  fi
  
  return 1
}

# ============================================
# Importar imágenes
# ============================================
import_images() {
  local dir="$1"
  
  log_info "Buscando imágenes en: $dir"
  echo ""
  
  # Buscar archivos .tar o .tar.gz
  local images=$(find "$dir" -maxdepth 1 -type f \( -name "*.tar" -o -name "*.tar.gz" \) 2>/dev/null)
  
  if [ -z "$images" ]; then
    log_warning "No se encontraron imágenes para importar"
    return 1
  fi
  
  local count=0
  while IFS= read -r image_file; do
    log_info "Importando: $(basename "$image_file")"
    
    if docker load -i "$image_file"; then
      log_success "$(basename "$image_file") importada correctamente"
      count=$((count + 1))
    else
      log_error "Error al importar $(basename "$image_file")"
    fi
    echo ""
  done <<< "$images"
  
  if [ $count -gt 0 ]; then
    log_success "$count imagen(es) importada(s) correctamente"
  fi
  
  return 0
}

# ============================================
# Main
# ============================================
main() {
  echo ""
  log_info "Iniciando importación de imágenes offline..."
  echo ""
  
  local target_dir
  if target_dir=$(find_latest_offline_dir); then
    log_info "Directorio encontrado: $target_dir"
    echo ""
    
    import_images "$target_dir"
  else
    log_error "No se encontró directorio de imágenes offline"
    log_info "Uso: $0 [ruta_al_directorio_offline]"
    exit 1
  fi
  
  echo ""
  log_success "Proceso de importación completado"
  echo ""
}

main "$@"
