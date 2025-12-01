#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Importación de Imágenes Docker desde .tar
# Para cargar imágenes exportadas previamente
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
echo "   Importación de Imágenes Docker"
echo "   Intranet Escolar con Nextcloud"
echo "================================================================"
echo ""

# ============================================
# Verificar parámetro
# ============================================
if [ $# -eq 0 ]; then
  log_error "Uso: $0 <directorio-con-imagenes>"
  echo ""
  log_info "Ejemplo:"
  log_info "  $0 docker-images-offline/20251201_143022"
  echo ""
  log_info "Este script importa todas las imágenes .tar del directorio especificado."
  echo ""
  exit 1
fi

IMPORT_DIR="$1"

# ============================================
# Verificar que existe el directorio
# ============================================
if [ ! -d "$IMPORT_DIR" ]; then
  log_error "El directorio '$IMPORT_DIR' no existe"
  exit 1
fi

log_info "Directorio de importación: $IMPORT_DIR"
echo ""

# ============================================
# Buscar archivos .tar
# ============================================
TAR_FILES=()
while IFS= read -r -d '' file; do
  TAR_FILES+=("$file")
done < <(find "$IMPORT_DIR" -maxdepth 1 -name "*.tar" -print0)

if [ ${#TAR_FILES[@]} -eq 0 ]; then
  log_error "No se encontraron archivos .tar en '$IMPORT_DIR'"
  exit 1
fi

log_info "Se encontraron ${#TAR_FILES[@]} archivos .tar"
echo ""

# ============================================
# Importar cada imagen
# ============================================
log_info "Importando imágenes..."
echo ""

IMPORTED=0
FAILED=0

for tarfile in "${TAR_FILES[@]}"; do
  BASENAME=$(basename "$tarfile")
  log_info "Cargando: $BASENAME"
  
  if docker load -i "$tarfile"; then
    log_success "Importada correctamente"
    IMPORTED=$((IMPORTED + 1))
  else
    log_error "Error al importar $BASENAME"
    FAILED=$((FAILED + 1))
  fi
  echo ""
done

# ============================================
# Resumen
# ============================================
echo "================================================================"
echo "   Resumen de Importación"
echo "================================================================"
echo ""
echo "Imágenes importadas correctamente: $IMPORTED"
echo "Imágenes con errores: $FAILED"
echo ""

if [ $IMPORTED -gt 0 ]; then
  log_info "Imágenes del proyecto disponibles:"
  echo ""
  docker images | head -1
  docker images | grep -E "mariadb|nextcloud|uptime-kuma" || log_warning "No se encontraron las imágenes esperadas"
  echo ""
fi

if [ $FAILED -eq 0 ]; then
  log_success "Todas las imágenes se importaron correctamente"
  echo ""
  log_info "Ahora puedes iniciar el proyecto con:"
  log_info "  bash scripts/init.sh"
  echo ""
else
  log_warning "Algunas imágenes no se pudieron importar"
  log_info "Verifica los archivos .tar y vuelve a intentarlo"
  echo ""
fi
