#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Exportación de Imágenes Docker a Archivos .tar
# Para demos offline o transferencia por USB
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
echo "   Exportación de Imágenes Docker"
echo "   Intranet Escolar con Nextcloud"
echo "================================================================"
echo ""

# Imágenes a exportar
IMAGES=(
  "mariadb:11"
  "nextcloud:29-apache"
  "louislam/uptime-kuma:1"
)

# ============================================
# Verificar que existen todas las imágenes
# ============================================
log_info "Verificando imágenes..."

MISSING=()
for img in "${IMAGES[@]}"; do
  if ! docker image inspect "$img" &>/dev/null; then
    MISSING+=("$img")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  log_error "Faltan las siguientes imágenes:"
  for img in "${MISSING[@]}"; do
    echo "  - $img"
  done
  echo ""
  log_info "Descárgalas primero con:"
  log_info "  bash scripts/provision_images.sh"
  echo ""
  exit 1
fi

log_success "Todas las imágenes están disponibles"
echo ""

# ============================================
# Crear directorio de exportación
# ============================================
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
EXPORT_DIR="docker-images-offline/${TIMESTAMP}"

log_info "Creando directorio de exportación: $EXPORT_DIR"
mkdir -p "$EXPORT_DIR"
log_success "Directorio creado"
echo ""

# ============================================
# Exportar cada imagen
# ============================================
log_info "Exportando imágenes..."
echo ""

for img in "${IMAGES[@]}"; do
  # Convertir nombre de imagen a nombre de archivo válido
  FILENAME=$(echo "$img" | tr '/:' '_')
  FILEPATH="$EXPORT_DIR/${FILENAME}.tar"
  
  log_info "Exportando $img..."
  log_info "  -> $FILEPATH"
  
  if docker save -o "$FILEPATH" "$img"; then
    SIZE=$(du -h "$FILEPATH" | cut -f1)
    log_success "Exportada correctamente ($SIZE)"
  else
    log_error "Error al exportar $img"
  fi
  echo ""
done

# ============================================
# Crear script de importación
# ============================================
log_info "Generando script de importación..."

cat > "$EXPORT_DIR/import.sh" << 'IMPORT_SCRIPT'
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
IMPORT_SCRIPT

chmod +x "$EXPORT_DIR/import.sh"
log_success "Script de importación creado: $EXPORT_DIR/import.sh"
echo ""

# ============================================
# Crear archivo README en el directorio
# ============================================
cat > "$EXPORT_DIR/README.txt" << 'README_CONTENT'
================================================================
  Imágenes Docker - Intranet Escolar con Nextcloud
  Exportación para uso offline
================================================================

CONTENIDO
---------
Este directorio contiene las imágenes Docker necesarias para
ejecutar el proyecto sin conexión a Internet.

Imágenes incluidas:
  - mariadb:11
  - nextcloud:29-apache
  - louislam/uptime-kuma:1

IMPORTACIÓN
-----------
Para cargar estas imágenes en otro equipo:

1. Copia este directorio completo al equipo destino
2. Ejecuta el script de importación:
   
   bash import.sh

3. Verifica que las imágenes se han cargado:
   
   docker images

ALTERNATIVA MANUAL
------------------
Puedes cargar las imágenes manualmente:

   docker load -i mariadb_11.tar
   docker load -i nextcloud_29-apache.tar
   docker load -i louislam_uptime-kuma_1.tar

SIGUIENTE PASO
--------------
Una vez importadas las imágenes, puedes clonar o copiar el
repositorio del proyecto y ejecutar:

   bash scripts/init.sh

================================================================
README_CONTENT

log_success "README.txt creado en $EXPORT_DIR"
echo ""

# ============================================
# Resumen final
# ============================================
TOTAL_SIZE=$(du -sh "$EXPORT_DIR" | cut -f1)

echo "================================================================"
echo "   Exportación completada"
echo "================================================================"
echo ""
log_success "Directorio: $EXPORT_DIR"
log_success "Tamaño total: $TOTAL_SIZE"
echo ""
log_info "Contenido:"
ls -lh "$EXPORT_DIR"
echo ""
log_info "Para importar en otro equipo:"
echo "  1. Copia el directorio completo"
echo "  2. Ejecuta: bash $EXPORT_DIR/import.sh"
echo ""
log_info "O usa el script independiente:"
echo "  bash scripts/import_images.sh $EXPORT_DIR"
echo ""
log_success "Las imágenes están listas para demos offline"
echo ""
