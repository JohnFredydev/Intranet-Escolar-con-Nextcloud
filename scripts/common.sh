#!/usr/bin/env bash
# ============================================
# Biblioteca de Funciones Comunes
# Funciones compartidas para todos los scripts
# ============================================

# Script metadata
SCRIPT_VERSION="2.0.0"

# ============================================
# Configuración de colores y estilos
# ============================================
setup_colors() {
  if [[ -t 1 ]] && [[ "${NO_COLOR:-}" != "1" ]]; then
    # Colores básicos
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    
    # Estilos
    BOLD='\033[1m'
    DIM='\033[2m'
    UNDERLINE='\033[4m'
    REVERSE='\033[7m'
    
    # Reset
    NC='\033[0m'
    
    # Iconos usando unicode
    ICON_INFO="ℹ"
    ICON_SUCCESS="✓"
    ICON_WARNING="⚠"
    ICON_ERROR="✗"
    ICON_ARROW="→"
    ICON_BULLET="•"
  else
    # Sin colores
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    WHITE=''
    BOLD=''
    DIM=''
    UNDERLINE=''
    REVERSE=''
    NC=''
    
    ICON_INFO="[i]"
    ICON_SUCCESS="[OK]"
    ICON_WARNING="[!]"
    ICON_ERROR="[X]"
    ICON_ARROW="->"
    ICON_BULLET="*"
  fi
}

# Inicializar colores por defecto
setup_colors

# ============================================
# Variables globales de configuración
# ============================================
QUIET_MODE=false
DEBUG_MODE=false
DRY_RUN=false
FORCE_MODE=false

# ============================================
# Funciones de logging mejoradas
# ============================================
log_info() {
  [[ "$QUIET_MODE" == "true" ]] && return
  echo -e "${BLUE}${ICON_INFO}${NC} ${DIM}$*${NC}" >&2
}

log_success() {
  [[ "$QUIET_MODE" == "true" ]] && return
  echo -e "${GREEN}${ICON_SUCCESS}${NC} $*" >&2
}

log_warning() {
  echo -e "${YELLOW}${ICON_WARNING}${NC} $*" >&2
}

log_error() {
  echo -e "${RED}${ICON_ERROR}${NC} ${BOLD}$*${NC}" >&2
}

log_debug() {
  [[ "$DEBUG_MODE" != "true" ]] && return
  echo -e "${MAGENTA}[DEBUG]${NC} ${DIM}$*${NC}" >&2
}

log_step() {
  [[ "$QUIET_MODE" == "true" ]] && return
  echo ""
  echo -e "${CYAN}${BOLD}$*${NC}" >&2
}

log_substep() {
  [[ "$QUIET_MODE" == "true" ]] && return
  echo -e "  ${DIM}${ICON_ARROW}${NC} $*" >&2
}

log_dry_run() {
  [[ "$DRY_RUN" != "true" ]] && return
  echo -e "${MAGENTA}[DRY-RUN]${NC} $*" >&2
}

# ============================================
# Spinner animado
# ============================================
spinner() {
  local pid=$1
  local message="${2:-Procesando}"
  local delay=0.1
  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  
  [[ "$QUIET_MODE" == "true" ]] && { wait "$pid"; return $?; }
  
  tput civis # Ocultar cursor
  
  while kill -0 "$pid" 2>/dev/null; do
    local temp=${spinstr#?}
    printf " ${CYAN}%s${NC} ${DIM}%s...${NC}\r" "${spinstr:0:1}" "$message"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
  done
  
  wait "$pid"
  local exit_code=$?
  
  printf "\r\033[K" # Limpiar línea
  tput cnorm # Mostrar cursor
  
  return $exit_code
}

# ============================================
# Barra de progreso simple
# ============================================
progress_bar() {
  local current=$1
  local total=$2
  local width=${3:-50}
  local message="${4:-}"
  
  [[ "$QUIET_MODE" == "true" ]] && return
  
  local percentage=$((current * 100 / total))
  local filled=$((width * current / total))
  local empty=$((width - filled))
  
  printf "\r["
  printf "%${filled}s" | tr ' ' '█'
  printf "%${empty}s" | tr ' ' '░'
  printf "] %3d%%" "$percentage"
  [[ -n "$message" ]] && printf " ${DIM}%s${NC}" "$message"
}

progress_bar_finish() {
  [[ "$QUIET_MODE" == "true" ]] && return
  echo ""
}

# ============================================
# Prompt interactivo mejorado
# ============================================
prompt_confirm() {
  local question="$1"
  local default="${2:-n}"
  
  [[ "$FORCE_MODE" == "true" ]] && return 0
  
  local prompt
  if [[ "$default" =~ ^[Yy]$ ]]; then
    prompt="[S/n]"
    default="y"
  else
    prompt="[s/N]"
    default="n"
  fi
  
  echo -e "${YELLOW}${ICON_WARNING}${NC} ${BOLD}$question${NC} ${DIM}$prompt${NC}" >&2
  read -r -n 1 -p "  " response
  echo "" >&2
  
  response=${response:-$default}
  
  if [[ "$response" =~ ^[SsYy]$ ]]; then
    return 0
  else
    return 1
  fi
}

# ============================================
# Detección de entorno
# ============================================
detect_terminal_size() {
  TERM_COLS=$(tput cols 2>/dev/null || echo 80)
  TERM_ROWS=$(tput lines 2>/dev/null || echo 24)
  export TERM_COLS TERM_ROWS
}

is_tty() {
  [[ -t 1 ]]
}

is_root() {
  [[ $EUID -eq 0 ]]
}

# ============================================
# Validación de comandos
# ============================================
check_command() {
  local cmd="$1"
  local install_hint="${2:-}"
  
  if command -v "$cmd" &>/dev/null; then
    log_success "$cmd ${DIM}(encontrado)${NC}"
    return 0
  else
    log_error "$cmd ${DIM}(no encontrado)${NC}"
    [[ -n "$install_hint" ]] && log_substep "$install_hint"
    return 1
  fi
}

require_command() {
  local cmd="$1"
  local install_hint="${2:-}"
  
  if ! check_command "$cmd" "$install_hint"; then
    log_error "Comando requerido no disponible: $cmd"
    exit 1
  fi
}

# ============================================
# Manejo de errores
# ============================================
die() {
  log_error "$*"
  exit 1
}

cleanup_on_error() {
  local exit_code=$?
  [[ $exit_code -eq 0 ]] && return
  
  log_warning "Interrupción detectada (código $exit_code)"
  log_info "Ejecutando limpieza..."
  
  # Aquí se pueden añadir acciones de limpieza específicas
  # Por ahora solo mostramos el mensaje
  
  exit $exit_code
}

cleanup_on_interrupt() {
  echo "" >&2
  log_warning "Instalación interrumpida por el usuario"
  cleanup_on_error
  exit 130
}

setup_traps() {
  trap cleanup_on_interrupt SIGINT SIGTERM
  trap cleanup_on_error EXIT
}

# ============================================
# Utilidades de tiempo
# ============================================
timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

elapsed_time() {
  local start=$1
  local end=${2:-$(date +%s)}
  local elapsed=$((end - start))
  
  if [[ $elapsed -lt 60 ]]; then
    echo "${elapsed}s"
  elif [[ $elapsed -lt 3600 ]]; then
    echo "$((elapsed / 60))m $((elapsed % 60))s"
  else
    echo "$((elapsed / 3600))h $(((elapsed % 3600) / 60))m"
  fi
}

# ============================================
# Utilidades de sistema
# ============================================
check_disk_space() {
  local required_mb=${1:-1000}
  local path="${2:-.}"
  
  local available_mb=$(df -m "$path" | awk 'NR==2 {print $4}')
  
  if [[ $available_mb -lt $required_mb ]]; then
    log_error "Espacio en disco insuficiente: ${available_mb}MB disponible, ${required_mb}MB requerido"
    return 1
  else
    log_debug "Espacio en disco: ${available_mb}MB disponible"
    return 0
  fi
}

check_architecture() {
  local arch=$(uname -m)
  log_debug "Arquitectura detectada: $arch"
  
  case "$arch" in
    x86_64|amd64)
      log_debug "Arquitectura compatible (x86_64)"
      return 0
      ;;
    aarch64|arm64)
      log_warning "Arquitectura ARM detectada, compatibilidad limitada"
      return 0
      ;;
    *)
      log_warning "Arquitectura no probada: $arch"
      return 0
      ;;
  esac
}

# ============================================
# Separadores visuales
# ============================================
print_separator() {
  [[ "$QUIET_MODE" == "true" ]] && return
  printf '%*s\n' "${TERM_COLS:-80}" '' | tr ' ' '─'
}

print_header() {
  local text="$1"
  [[ "$QUIET_MODE" == "true" ]] && return
  
  echo ""
  echo -e "${BOLD}${CYAN}$text${NC}"
  printf '%*s\n' "${#text}" '' | tr ' ' '─'
  echo ""
}

# ============================================
# Parsing de argumentos (helper)
# ============================================
parse_common_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -q|--quiet)
        QUIET_MODE=true
        shift
        ;;
      --debug)
        DEBUG_MODE=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        log_info "Modo dry-run activado (simulación)"
        shift
        ;;
      --force)
        FORCE_MODE=true
        shift
        ;;
      --no-color)
        NO_COLOR=1
        setup_colors
        shift
        ;;
      *)
        shift
        ;;
    esac
  done
}

# ============================================
# Exportar variables y funciones principales
# ============================================
export -f log_info log_success log_warning log_error log_debug
export -f log_step log_substep log_dry_run
export -f spinner progress_bar progress_bar_finish
export -f prompt_confirm
export -f check_command require_command
export -f die cleanup_on_error cleanup_on_interrupt setup_traps
export -f timestamp elapsed_time
export -f check_disk_space check_architecture
export -f print_separator print_header
export -f detect_terminal_size is_tty is_root
export -f parse_common_args

# Detectar tamaño de terminal al cargar
detect_terminal_size
