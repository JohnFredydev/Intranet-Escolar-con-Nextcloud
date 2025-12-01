#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Configuración del Entorno Educativo
# Crea grupos, carpetas grupales y configura apps
# ============================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[⚠]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }

OCC="docker compose exec -T -u www-data app php occ"

# ============================================
# 1. CONFIGURAR TRUSTED DOMAINS (CRÍTICO PARA UPTIME KUMA)
# ============================================
log_info "Configurando trusted domains..."

# Configurar localhost en índice 0
$OCC config:system:set trusted_domains 0 --value="localhost" 2>/dev/null || true

# Configurar app en índice 1 (nombre del servicio Docker)
$OCC config:system:set trusted_domains 1 --value="app" 2>/dev/null || true

log_success "Trusted domains configurados:"
$OCC config:system:get trusted_domains 2>/dev/null || log_warning "No se pudieron leer trusted_domains"

echo ""

# ============================================
# 2. INSTALAR Y HABILITAR APLICACIONES EDUCATIVAS
# ============================================
log_info "Configurando aplicaciones educativas..."
echo ""

# Apps esenciales
apps=(
  "groupfolders"
  "impersonate"
  "admin_audit"
  "theming"
  "viewer"
  "files_pdfviewer"
  "calendar"
  "contacts"
)

for app in "${apps[@]}"; do
  if $OCC app:install "$app" 2>/dev/null; then
    log_success "$app instalado"
  elif $OCC app:enable "$app" 2>/dev/null; then
    log_success "$app habilitado"
  else
    log_warning "$app no disponible o ya habilitado"
  fi
done

echo ""

# ============================================
# 3. CREAR GRUPOS DEL COLEGIO
# ============================================
log_info "Creando grupos del colegio..."
echo ""

groups=(
  "profesorado"
  "alumnado"
  "direccion"
  "secretaria"
  "tic"
  "orientacion"
  "clase"
  "1ESO"
  "2ESO"
  "3ESO"
  "4ESO"
  "1BACH"
  "2BACH"
  "FP1"
  "FP2"
)

for group in "${groups[@]}"; do
  if $OCC group:add "$group" 2>/dev/null; then
    log_success "Grupo '$group' creado"
  else
    log_info "Grupo '$group' ya existe"
  fi
done

echo ""

# ============================================
# 4. CREAR CARPETAS GRUPALES (GROUP FOLDERS)
# ============================================
log_info "Creando carpetas grupales..."
echo ""

# Verificar si groupfolders está disponible
if ! $OCC groupfolders:list &>/dev/null; then
  log_warning "App groupfolders no disponible"
else
  # Helper: Obtener ID de carpeta por nombre
  get_folder_id() {
    local nombre="$1"
    $OCC groupfolders:list 2>/dev/null | grep -A 1 "$nombre" | grep "^[0-9]" | awk -F':' '{print $1}' | tr -d ' ' | head -1
  }
  
  # Helper: Crear carpeta si no existe
  create_folder() {
    local nombre="$1"
    local id=$(get_folder_id "$nombre")
    
    if [ -n "$id" ]; then
      log_info "Carpeta '$nombre' ya existe (ID: $id)"
      echo "$id"
    else
      id=$($OCC groupfolders:create "$nombre" 2>/dev/null | grep -oP '\d+' || echo "")
      if [ -n "$id" ]; then
        log_success "Carpeta '$nombre' creada (ID: $id)"
        echo "$id"
      else
        log_warning "No se pudo crear carpeta '$nombre'"
        echo ""
      fi
    fi
  }
  
  # CARPETA: Claustro (profesores)
  FOLDER_ID=$(create_folder "Claustro")
  if [ -n "$FOLDER_ID" ]; then
    $OCC groupfolders:group "$FOLDER_ID" profesorado write 2>/dev/null || true
    $OCC groupfolders:quota "$FOLDER_ID" 10G 2>/dev/null || true
  fi
  
  # CARPETA: Secretaría
  FOLDER_ID=$(create_folder "Secretaria")
  if [ -n "$FOLDER_ID" ]; then
    $OCC groupfolders:group "$FOLDER_ID" secretaria write 2>/dev/null || true
    $OCC groupfolders:group "$FOLDER_ID" direccion write 2>/dev/null || true
    $OCC groupfolders:quota "$FOLDER_ID" 5G 2>/dev/null || true
  fi
  
  # CARPETA: Dirección
  FOLDER_ID=$(create_folder "Direccion")
  if [ -n "$FOLDER_ID" ]; then
    $OCC groupfolders:group "$FOLDER_ID" direccion write 2>/dev/null || true
    $OCC groupfolders:quota "$FOLDER_ID" 5G 2>/dev/null || true
  fi
  
  # CARPETA: Comunicados
  FOLDER_ID=$(create_folder "Comunicados")
  if [ -n "$FOLDER_ID" ]; then
    $OCC groupfolders:group "$FOLDER_ID" profesorado write 2>/dev/null || true
    $OCC groupfolders:group "$FOLDER_ID" alumnado read 2>/dev/null || true
    $OCC groupfolders:quota "$FOLDER_ID" 2G 2>/dev/null || true
  fi
  
  # CARPETAS POR CURSO
  for curso in "1ESO" "2ESO" "3ESO" "4ESO" "1BACH" "2BACH" "FP1" "FP2"; do
    FOLDER_ID=$(create_folder "Curso_$curso")
    if [ -n "$FOLDER_ID" ]; then
      $OCC groupfolders:group "$FOLDER_ID" profesorado write 2>/dev/null || true
      $OCC groupfolders:group "$FOLDER_ID" "$curso" read 2>/dev/null || true
      $OCC groupfolders:quota "$FOLDER_ID" 15G 2>/dev/null || true
    fi
  done
  
  log_success "Carpetas grupales configuradas"
fi

echo ""

# ============================================
# 5. CONFIGURAR THEMING
# ============================================
log_info "Configurando tema personalizado..."

$OCC theming:config name "IES Intranet Escolar" 2>/dev/null || true
$OCC theming:config slogan "Plataforma Educativa" 2>/dev/null || true
$OCC theming:config url "http://localhost:8080" 2>/dev/null || true
$OCC theming:config color "#0082c9" 2>/dev/null || true

log_success "Tema configurado"
echo ""

# ============================================
# 6. CONFIGURACIONES ADICIONALES
# ============================================
log_info "Aplicando configuraciones adicionales..."

# Cuota por defecto
$OCC config:app:set files default_quota --value="5 GB" 2>/dev/null || true

# Retención de versiones
$OCC config:app:set files versions_retention_obligation --value="auto, 30" 2>/dev/null || true

# App por defecto
$OCC config:system:set defaultapp --value="files" 2>/dev/null || true

# File locking
$OCC config:system:set filelocking.enabled --value=true --type=boolean 2>/dev/null || true

log_success "Configuraciones aplicadas"
echo ""

log_success "Entorno educativo configurado correctamente"
