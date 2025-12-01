#!/usr/bin/env bash
set -Eeuo pipefail

# Script de importación automática
# Generado por export_images.sh

echo ""
echo "================================================================"
echo "   Importación de Imágenes Docker"
echo "   Intranet Escolar con Nextcloud"
echo "================================================================"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info "Importando imágenes desde: $SCRIPT_DIR"
echo ""

for tarfile in "$SCRIPT_DIR"/*.tar; do
  if [ -f "$tarfile" ]; then
    log_info "Cargando: $(basename "$tarfile")"
    docker load -i "$tarfile"
    log_success "Cargada correctamente"
    echo ""
  fi
done

log_success "Todas las imágenes han sido importadas"
echo ""
log_info "Imágenes disponibles:"
docker images | grep -E "mariadb|nextcloud|uptime-kuma" || true
echo ""
