#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Instalador - Intranet Escolar Nextcloud
# Despliegue automático profesional
# ============================================

# Variables globales
REPO_URL="https://github.com/JohnFredydev/Intranet-Escolar-con-Nextcloud.git"
INSTALL_DIR="${INSTALL_DIR:-$HOME/Intranet-Escolar-con-Nextcloud}"
START_TIME=$(date +%s)
SCRIPT_VERSION="2.0.0"

# Flags globales
QUIET_MODE=false
DEBUG_MODE=false
DRY_RUN=false
FORCE_MODE=false
NO_COLOR="${NO_COLOR:-0}"

# ============================================
# Funciones básicas inline (para ejecución remota)
# ============================================
setup_colors_inline() {
  if [[ -t 1 ]] && [[ "${NO_COLOR}" != "1" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
    ICON_INFO="ℹ"
    ICON_SUCCESS="✓"
    ICON_WARNING="⚠"
    ICON_ERROR="✗"
    ICON_ARROW="→"
    ICON_BULLET="•"
  else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; CYAN=''; BOLD=''; DIM=''; NC=''
    ICON_INFO="[i]"; ICON_SUCCESS="[OK]"; ICON_WARNING="[!]"
    ICON_ERROR="[X]"; ICON_ARROW="->"; ICON_BULLET="*"
  fi
  TERM_COLS=$(tput cols 2>/dev/null || echo 80)
}

log_info() { [[ "$QUIET_MODE" == "true" ]] && return; echo -e "${BLUE}${ICON_INFO}${NC} ${DIM}$*${NC}" >&2; }
log_success() { [[ "$QUIET_MODE" == "true" ]] && return; echo -e "${GREEN}${ICON_SUCCESS}${NC} $*" >&2; }
log_warning() { echo -e "${YELLOW}${ICON_WARNING}${NC} $*" >&2; }
log_error() { echo -e "${RED}${ICON_ERROR}${NC} ${BOLD}$*${NC}" >&2; }
log_debug() { [[ "$DEBUG_MODE" != "true" ]] && return; echo -e "[DEBUG] ${DIM}$*${NC}" >&2; }
log_step() { [[ "$QUIET_MODE" == "true" ]] && return; echo ""; echo -e "${CYAN}${BOLD}$*${NC}" >&2; }
log_substep() { [[ "$QUIET_MODE" == "true" ]] && return; echo -e "  ${DIM}${ICON_ARROW}${NC} $*" >&2; }
log_dry_run() { [[ "$DRY_RUN" != "true" ]] && return; echo -e "[DRY-RUN] $*" >&2; }

die() { log_error "$*"; exit 1; }

print_separator() {
  [[ "$QUIET_MODE" == "true" ]] && return
  printf '%*s\n' "${TERM_COLS:-80}" '' | tr ' ' '─'
}

elapsed_time() {
  local start=$1
  local end=${2:-$(date +%s)}
  local elapsed=$((end - start))
  if [[ $elapsed -lt 60 ]]; then echo "${elapsed}s"
  elif [[ $elapsed -lt 3600 ]]; then echo "$((elapsed / 60))m $((elapsed % 60))s"
  else echo "$((elapsed / 3600))h $(((elapsed % 3600) / 60))m"; fi
}

prompt_confirm() {
  local question="$1"
  local default="${2:-n}"
  [[ "$FORCE_MODE" == "true" ]] && return 0
  
  local prompt; [[ "$default" =~ ^[Yy]$ ]] && prompt="[S/n]" || prompt="[s/N]"
  echo -e "${YELLOW}${ICON_WARNING}${NC} ${BOLD}$question${NC} ${DIM}$prompt${NC}" >&2
  read -r -n 1 -p "  " response
  echo "" >&2
  response=${response:-$default}
  [[ "$response" =~ ^[SsYy]$ ]] && return 0 || return 1
}

progress_bar() {
  local current=$1 total=$2 width=${3:-50} message="${4:-}"
  [[ "$QUIET_MODE" == "true" ]] && return
  local percentage=$((current * 100 / total))
  local filled=$((width * current / total))
  local empty=$((width - filled))
  printf "\r["; printf "%${filled}s" | tr ' ' '█'; printf "%${empty}s" | tr ' ' '░'
  printf "] %3d%%" "$percentage"
  [[ -n "$message" ]] && printf " ${DIM}%s${NC}" "$message"
}

progress_bar_finish() { [[ "$QUIET_MODE" == "true" ]] && return; echo ""; }

check_command() {
  local cmd="$1"
  if command -v "$cmd" &>/dev/null; then
    log_success "$cmd ${DIM}(encontrado)${NC}"
    return 0
  else
    log_error "$cmd ${DIM}(no encontrado)${NC}"
    return 1
  fi
}

setup_traps() {
  trap 'echo ""; log_warning "Instalación interrumpida"; exit 130' SIGINT SIGTERM
}

# Inicializar colores
setup_colors_inline

# ============================================
# Mostrar ayuda
# ============================================
show_help() {
  cat << EOF
Instalador de Intranet Escolar con Nextcloud

USO:
  ./install.sh [opciones]
  bash <(curl -fsSL https://raw.githubusercontent.com/.../install.sh)

OPCIONES:
  -h, --help          Mostrar esta ayuda
  -q, --quiet         Modo silencioso (menos output)
  -d, --debug         Modo debug (más información)
  -f, --force         No pedir confirmaciones
  --dry-run           Simular sin ejecutar comandos destructivos
  --no-color          Desactivar colores en salida
  --dir=PATH          Directorio de instalación (por defecto: ~/Intranet-Escolar-con-Nextcloud)

EJEMPLOS:
  ./install.sh                    # Instalación interactiva
  ./install.sh --force --quiet    # Instalación automática sin prompts
  ./install.sh --dry-run          # Ver qué haría sin ejecutar

DOCUMENTACIÓN:
  README.md           Documentación completa
  docs/               Guías y changelog

EOF
  exit 0
}

# ============================================
# Parsing de argumentos
# ============================================
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        show_help
        ;;
      -q|--quiet)
        QUIET_MODE=true
        shift
        ;;
      -d|--debug)
        DEBUG_MODE=true
        shift
        ;;
      -f|--force)
        FORCE_MODE=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        log_info "Modo dry-run activado (simulación)"
        shift
        ;;
      --no-color)
        NO_COLOR=1
        setup_colors_inline
        shift
        ;;
      --dir=*)
        INSTALL_DIR="${1#*=}"
        shift
        ;;
      *)
        log_warning "Opción desconocida: $1"
        shift
        ;;
    esac
  done
}

# ============================================
# Verificar requisitos del sistema
# ============================================
check_requirements() {
  log_step "Verificando requisitos del sistema"
  
  local all_ok=true
  local missing_cmds=()
  
  # Comandos requeridos
  for cmd in docker git curl bash; do
    if ! check_command "$cmd"; then
      all_ok=false
      missing_cmds+=("$cmd")
    fi
  done
  
  # Docker Compose (plugin o standalone)
  if docker compose version &>/dev/null; then
    log_success "docker compose ${DIM}(plugin)${NC}"
  elif command -v docker-compose &>/dev/null; then
    log_success "docker-compose ${DIM}(standalone)${NC}"
  else
    log_error "docker compose ${DIM}(no encontrado)${NC}"
    all_ok=false
    missing_cmds+=("docker-compose")
  fi
  
  if [[ "$all_ok" == "false" ]]; then
    echo ""
    log_error "Faltan dependencias requeridas"
    log_substep "Comandos faltantes: ${missing_cmds[*]}"
    echo ""
    log_info "Instalar en Ubuntu/Debian:"
    echo "  sudo apt update"
    echo "  sudo apt install -y docker.io docker-compose-plugin git curl"
    echo "  sudo usermod -aG docker \$USER"
    echo "  newgrp docker"
    echo ""
    die "Instala las dependencias y vuelve a intentarlo"
  fi
  
  # Verificar espacio en disco (2GB mínimo)
  local available_mb=$(df -m . 2>/dev/null | awk 'NR==2 {print $4}')
  if [[ -n "$available_mb" ]] && [[ $available_mb -lt 2000 ]]; then
    log_warning "Espacio en disco bajo: ${available_mb}MB disponible"
  else
    log_debug "Espacio en disco: ${available_mb}MB disponible"
  fi
  
  log_success "Todos los requisitos cumplidos"
}

# ============================================
# Clonar o verificar repositorio
# ============================================
setup_repository() {
  # Si ya estamos en el directorio del proyecto
  if [[ -f "docker-compose.yml" ]] && [[ -f "scripts/init.sh" ]]; then
    log_info "Usando repositorio local existente"
    return 0
  fi
  
  log_step "Configurando repositorio"
  
  # Verificar si el directorio existe
  if [[ -d "$INSTALL_DIR" ]]; then
    log_warning "El directorio ya existe: $INSTALL_DIR"
    
    # Verificar si es un repositorio válido
    if [[ -f "$INSTALL_DIR/docker-compose.yml" ]]; then
      if prompt_confirm "¿Usar el directorio existente?"; then
        log_info "Usando directorio existente"
        cd "$INSTALL_DIR" || die "No se pudo acceder a $INSTALL_DIR"
        return 0
      fi
    fi
    
    # Preguntar si eliminar
    if prompt_confirm "¿Eliminar y clonar de nuevo?" "n"; then
      if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "rm -rf \"$INSTALL_DIR\""
      else
        log_info "Eliminando directorio existente..."
        rm -rf "$INSTALL_DIR"
        log_success "Directorio eliminado"
      fi
    else
      die "Instalación cancelada por el usuario"
    fi
  fi
  
  # Clonar repositorio
  log_info "Clonando repositorio..."
  log_substep "Origen: $REPO_URL"
  log_substep "Destino: $INSTALL_DIR"
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_dry_run "git clone \"$REPO_URL\" \"$INSTALL_DIR\""
    return 0
  fi
  
  echo ""
  if git clone "$REPO_URL" "$INSTALL_DIR" 2>&1; then
    log_success "Repositorio clonado correctamente"
    cd "$INSTALL_DIR" || die "No se pudo acceder a $INSTALL_DIR"
  else
    log_error "Error al clonar el repositorio"
    die "Clonación fallida"
  fi
}

# ============================================
# Verificar estructura del proyecto
# ============================================
verify_project_structure() {
  log_step "Verificando estructura del proyecto"
  
  local required_files=(
    "docker-compose.yml"
    "scripts/init.sh"
    "scripts/cole_setup.sh"
    ".env.example"
  )
  
  local missing_files=()
  
  for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      missing_files+=("$file")
      log_error "Falta archivo: $file"
    else
      log_debug "Encontrado: $file"
    fi
  done
  
  if [[ ${#missing_files[@]} -gt 0 ]]; then
    die "Estructura del proyecto incompleta"
  fi
  
  log_success "Estructura del proyecto correcta"
  log_info "Directorio: ${CYAN}$(pwd)${NC}"
}

# ============================================
# Configurar variables de entorno
# ============================================
setup_environment() {
  log_step "Configurando variables de entorno"
  
  if [[ -f ".env" ]]; then
    log_info "Archivo .env existente encontrado"
    
    if [[ "$FORCE_MODE" == "true" ]]; then
      # En modo force, sobrescribir si estamos en instalación remota inicial
      if [[ ! -s ".env" ]] || ! grep -q "NEXTCLOUD_ADMIN_PASSWORD" .env 2>/dev/null; then
        if [[ "$DRY_RUN" == "true" ]]; then
          log_dry_run "cp .env.example .env"
        else
          cp .env.example .env
          log_success "Archivo .env creado desde plantilla"
        fi
      else
        log_info "Usando .env existente"
      fi
    elif ! prompt_confirm "¿Sobrescribir con valores por defecto?" "n"; then
      log_info "Usando .env existente"
    else
      if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "cp .env.example .env"
      else
        cp .env.example .env
        log_success "Archivo .env actualizado"
      fi
    fi
  else
    if [[ "$DRY_RUN" == "true" ]]; then
      log_dry_run "cp .env.example .env"
    else
      if [[ -f ".env.example" ]]; then
        cp .env.example .env
        log_success "Archivo .env creado desde plantilla"
      else
        log_error "No se encuentra .env.example"
        die "Archivo .env.example no disponible"
      fi
    fi
  fi
  
  # Cargar variables
  if [[ "$DRY_RUN" != "true" ]] && [[ -f ".env" ]]; then
    set -a
    source .env 2>/dev/null || log_warning "No se pudo cargar .env"
    set +a
    
    log_substep "Zona horaria: ${TZ:-Europe/Madrid}"
    log_substep "Usuario admin: ${NEXTCLOUD_ADMIN_USER:-admin}"
  fi
}

# ============================================
# Iniciar servicios Docker
# ============================================
start_docker_services() {
  log_step "Iniciando servicios Docker"
  
  local compose_files="-f docker-compose.yml"
  [[ -f "compose.db.healthpatch.yml" ]] && compose_files="$compose_files -f compose.db.healthpatch.yml"
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_dry_run "docker compose $compose_files up -d"
    return 0
  fi
  
  log_info "Descargando imágenes e iniciando contenedores..."
  
  if docker compose $compose_files up -d; then
    log_success "Contenedores iniciados correctamente"
  else
    log_error "Error al iniciar contenedores"
    die "Fallo en docker compose up"
  fi
  
  # Mostrar estado
  echo ""
  log_info "Estado de los contenedores:"
  docker compose ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null || docker compose ps
}

# ============================================
# Esperar a que MariaDB esté healthy
# ============================================
wait_for_database() {
  log_step "Esperando a que MariaDB esté lista"
  
  [[ "$DRY_RUN" == "true" ]] && { log_dry_run "Esperar MariaDB healthy"; return 0; }
  
  local max_wait=180
  local elapsed=0
  local check_interval=5
  
  while [ $elapsed -lt $max_wait ]; do
    if docker compose ps db 2>/dev/null | grep -q "healthy"; then
      log_success "MariaDB está healthy"
      return 0
    fi
    
    progress_bar $elapsed $max_wait 40 "Esperando base de datos"
    sleep $check_interval
    elapsed=$((elapsed + check_interval))
  done
  
  progress_bar_finish
  log_error "MariaDB no alcanzó estado healthy en ${max_wait}s"
  
  if prompt_confirm "¿Continuar de todos modos?" "n"; then
    log_warning "Continuando sin verificar estado de DB"
    return 0
  else
    log_info "Puedes revisar los logs con: docker compose logs db"
    die "Base de datos no disponible"
  fi
}

# ============================================
# Esperar a que Nextcloud responda
# ============================================
wait_for_nextcloud() {
  log_step "Esperando a que Nextcloud esté listo"
  
  [[ "$DRY_RUN" == "true" ]] && { log_dry_run "Esperar Nextcloud ready"; return 0; }
  
  local max_wait=120
  local elapsed=0
  local check_interval=3
  local occ="docker compose exec -T -u www-data app php occ"
  
  while [ $elapsed -lt $max_wait ]; do
    if $occ status &>/dev/null; then
      log_success "Nextcloud responde correctamente"
      return 0
    fi
    
    progress_bar $elapsed $max_wait 40 "Inicializando Nextcloud"
    sleep $check_interval
    elapsed=$((elapsed + check_interval))
  done
  
  progress_bar_finish
  log_warning "Nextcloud tardó más de lo esperado (${max_wait}s)"
  
  if prompt_confirm "¿Continuar de todos modos?" "y"; then
    log_warning "Continuando sin verificar completamente"
    return 0
  else
    log_info "Puedes revisar los logs con: docker compose logs app"
    die "Nextcloud no disponible"
  fi
}

# ============================================
# Ejecutar configuración automática
# ============================================
run_initialization() {
  log_step "Ejecutando configuración educativa"
  
  if [[ ! -f "scripts/init.sh" ]]; then
    die "No se encuentra scripts/init.sh"
  fi
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_dry_run "bash scripts/init.sh --auto"
    return 0
  fi
  
  log_info "Configurando grupos, carpetas y usuarios..."
  echo ""
  
  if bash scripts/init.sh --auto; then
    log_success "Configuración completada"
  else
    log_error "Error durante la configuración"
    die "Fallo en scripts/init.sh"
  fi
}

# ============================================
# Mostrar resumen final
# ============================================
show_summary() {
  local end_time=$(date +%s)
  local total_time=$(elapsed_time "$START_TIME" "$end_time")
  
  echo ""
  print_separator
  echo ""
  log_success "${BOLD}Instalación completada exitosamente${NC}"
  echo ""
  
  log_info "Servicios disponibles:"
  echo ""
  echo -e "  ${ICON_BULLET} Nextcloud:    ${CYAN}${BOLD}http://localhost:8080${NC}"
  echo -e "  ${ICON_BULLET} Uptime Kuma:  ${CYAN}${BOLD}http://localhost:3001${NC}"
  echo ""
  
  log_info "Credenciales por defecto:"
  echo ""
  echo -e "  ${ICON_BULLET} Admin:    ${YELLOW}admin${NC} / ${DIM}(ver NEXTCLOUD_ADMIN_PASSWORD en .env)${NC}"
  echo -e "  ${ICON_BULLET} Profesor: ${YELLOW}profe${NC} / Profesor2025!Demo"
  echo -e "  ${ICON_BULLET} Alumno:   ${YELLOW}alumno1${NC} / Alumno2025!Uno"
  echo ""
  
  log_info "Comandos útiles:"
  echo ""
  echo -e "  ${DIM}#${NC} Ver estado de contenedores"
  echo -e "  ${CYAN}docker compose ps${NC}"
  echo ""
  echo -e "  ${DIM}#${NC} Ver logs en tiempo real"
  echo -e "  ${CYAN}docker compose logs -f app${NC}"
  echo ""
  echo -e "  ${DIM}#${NC} Ejecutar comandos OCC"
  echo -e "  ${CYAN}docker compose exec -u www-data app php occ status${NC}"
  echo ""
  echo -e "  ${DIM}#${NC} Hacer backup"
  echo -e "  ${CYAN}bash scripts/backup.sh${NC}"
  echo ""
  
  log_substep "Tiempo total: ${BOLD}$total_time${NC}"
  echo ""
  print_separator
  echo ""
}

# ============================================
# Función principal
# ============================================
main() {
  # Configurar manejo de errores
  setup_traps
  
  # Parsear argumentos
  parse_args "$@"
  
  # Mostrar cabecera
  if [[ "$QUIET_MODE" != "true" ]]; then
    echo ""
    echo -e "${BOLD}${CYAN}Instalador de Intranet Escolar con Nextcloud${NC}"
    echo -e "${DIM}Proyecto Final ASIR - Versión $SCRIPT_VERSION${NC}"
    echo ""
  fi
  
  # Ejecutar pasos de instalación
  check_requirements
  setup_repository
  verify_project_structure
  setup_environment
  start_docker_services
  wait_for_database
  wait_for_nextcloud
  run_initialization
  
  # Mostrar resumen
  show_summary
  
  # Desactivar trap de error (instalación exitosa)
  trap - EXIT
}

# Ejecutar instalación
main "$@"
