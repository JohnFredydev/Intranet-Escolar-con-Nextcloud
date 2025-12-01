#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Aprovisionamiento de Imágenes Docker
# Verifica y descarga las imágenes necesarias
# ============================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[AVISO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

echo ""
echo "================================================================"
echo "   Aprovisionamiento de Imágenes Docker"
echo "   Intranet Escolar con Nextcloud"
echo "================================================================"
echo ""

# Imágenes necesarias
IMAGES=(
  "mariadb:11"
  "nextcloud:29-apache"
  "louislam/uptime-kuma:1"
)

# ============================================
# Verificar imágenes locales
# ============================================
log_info "Verificando imágenes Docker locales..."
echo ""

MISSING_IMAGES=()
EXISTING_IMAGES=()

for img in "${IMAGES[@]}"; do
  if docker image inspect "$img" &>/dev/null; then
    EXISTING_IMAGES+=("$img")
    log_success "Encontrada: $img"
  else
    MISSING_IMAGES+=("$img")
    log_warning "Falta: $img"
  fi
done

echo ""
echo "================================================================"
echo "   Resumen"
echo "================================================================"
echo ""
echo "Imágenes presentes: ${#EXISTING_IMAGES[@]}/${#IMAGES[@]}"
echo "Imágenes faltantes: ${#MISSING_IMAGES[@]}/${#IMAGES[@]}"
echo ""

# ============================================
# Mostrar tamaños de imágenes existentes
# ============================================
if [ ${#EXISTING_IMAGES[@]} -gt 0 ]; then
  log_info "Tamaños de imágenes locales:"
  echo ""
  for img in "${EXISTING_IMAGES[@]}"; do
    SIZE=$(docker image inspect "$img" --format='{{.Size}}' | awk '{printf "%.2f MB", $1/1024/1024}')
    echo "  - $img: $SIZE"
  done
  echo ""
fi

# ============================================
# Ofrecer descarga de imágenes faltantes
# ============================================
if [ ${#MISSING_IMAGES[@]} -gt 0 ]; then
  log_warning "Faltan ${#MISSING_IMAGES[@]} imágenes."
  echo ""
  log_info "Imágenes faltantes:"
  for img in "${MISSING_IMAGES[@]}"; do
    echo "  - $img"
  done
  echo ""
  
  read -p "¿Deseas descargar las imágenes faltantes ahora? (s/N): " -n 1 -r
  echo ""
  
  if [[ $REPLY =~ ^[SsYy]$ ]]; then
    log_info "Descargando imágenes..."
    echo ""
    
    for img in "${MISSING_IMAGES[@]}"; do
      log_info "Descargando $img..."
      if docker pull "$img"; then
        log_success "$img descargada correctamente"
      else
        log_error "Error al descargar $img"
      fi
      echo ""
    done
    
    log_success "Proceso de descarga completado"
    echo ""
    
    # Mostrar tamaños actualizados
    log_info "Tamaños de todas las imágenes:"
    echo ""
    for img in "${IMAGES[@]}"; do
      if docker image inspect "$img" &>/dev/null; then
        SIZE=$(docker image inspect "$img" --format='{{.Size}}' | awk '{printf "%.2f MB", $1/1024/1024}')
        echo "  - $img: $SIZE"
      fi
    done
    echo ""
  else
    log_info "Descarga cancelada por el usuario"
    echo ""
    log_warning "NOTA: Sin las imágenes necesarias, el proyecto no podrá iniciarse."
    log_info "Puedes descargarlas más tarde ejecutando:"
    log_info "  bash scripts/provision_images.sh"
    echo ""
  fi
else
  log_success "Todas las imágenes necesarias están disponibles localmente"
  echo ""
  log_info "Puedes exportarlas para uso offline con:"
  log_info "  bash scripts/export_images.sh"
  echo ""
fi

echo "================================================================"
log_success "Aprovisionamiento completado"
echo "================================================================"
echo ""
