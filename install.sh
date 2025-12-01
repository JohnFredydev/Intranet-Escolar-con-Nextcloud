#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Instalador Interactivo - Intranet Escolar Nextcloud
# Proyecto Final ASIR
# ============================================

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[AVISO]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step() { echo -e "${CYAN}[PASO]${NC} $*"; }
log_title() { echo -e "${BOLD}${CYAN}$*${NC}"; }

ask_yes_no() {
  local prompt="$1"
  local default="${2:-n}"
  local response
  
  if [[ "$default" == "y" ]]; then
    read -p "$(echo -e "${YELLOW}[?]${NC} $prompt [S/n]: ")" -n 1 -r response
  else
    read -p "$(echo -e "${YELLOW}[?]${NC} $prompt [s/N]: ")" -n 1 -r response
  fi
  echo ""
  
  [[ -z "$response" ]] && response="$default"
  [[ "$response" =~ ^[SsYy]$ ]]
}

show_menu() {
  echo ""
  log_title "╔════════════════════════════════════════════════════════════╗"
  log_title "║                                                            ║"
  log_title "║   Instalador Interactivo - Intranet Escolar Nextcloud     ║"
  log_title "║   Proyecto Final ASIR                                      ║"
  log_title "║                                                            ║"
  log_title "╚════════════════════════════════════════════════════════════╝"
  echo ""
}

# ============================================
# Verificar requisitos del sistema
# ============================================
check_requirements() {
  log_step "Verificando requisitos del sistema..."
  echo ""
  
  local all_ok=true
  
  if command -v docker &>/dev/null; then
    log_success "Docker instalado: $(docker --version | cut -d' ' -f3 | tr -d ',')"
  else
    log_error "Docker NO instalado"
    all_ok=false
  fi
  
  if docker compose version &>/dev/null; then
    log_success "Docker Compose instalado: $(docker compose version --short)"
  else
    log_error "Docker Compose plugin NO instalado"
    all_ok=false
  fi
  
  if command -v git &>/dev/null; then
    log_success "Git instalado: $(git --version | cut -d' ' -f3)"
  else
    log_error "Git NO instalado"
    all_ok=false
  fi
  
  if command -v curl &>/dev/null; then
    log_success "Curl instalado"
  else
    log_error "Curl NO instalado"
    all_ok=false
  fi
  
  echo ""
  
  if [[ "$all_ok" == "false" ]]; then
    log_error "Faltan dependencias necesarias."
    echo ""
    log_info "En Ubuntu/Debian, instala con:"
    echo -e "  ${CYAN}sudo apt update && sudo apt install -y docker.io docker-compose-plugin git curl${NC}"
    echo -e "  ${CYAN}sudo usermod -aG docker \$USER${NC}"
    echo -e "  ${CYAN}newgrp docker${NC}"
    echo ""
    exit 1
  fi
  
  log_success "Todos los requisitos están satisfechos"
  echo ""
}

# ============================================
# Verificar y gestionar imágenes Docker
# ============================================
check_docker_images() {
  log_step "Verificando imágenes Docker necesarias..."
  echo ""
  
  local images=("mariadb:11" "nextcloud:29-apache" "louislam/uptime-kuma:1")
  local missing=()
  local present=()
  
  for img in "${images[@]}"; do
    if docker image inspect "$img" &>/dev/null; then
      local size=$(docker image inspect "$img" --format='{{.Size}}' | awk '{printf "%.0f MB", $1/1024/1024}')
      log_success "$img disponible ($size)"
      present+=("$img")
    else
      log_warning "$img NO disponible"
      missing+=("$img")
    fi
  done
  
  echo ""
  
  if [ ${#missing[@]} -gt 0 ]; then
    log_warning "Faltan ${#missing[@]} imagen(es) Docker"
    echo ""
    
    # Buscar directorio offline
    local offline_dir=""
    if [ -d "docker-images-offline" ]; then
      offline_dir=$(find docker-images-offline -maxdepth 1 -type d -name "202*" | sort -r | head -1)
    fi
    
    if [ -n "$offline_dir" ] && [ -d "$offline_dir" ]; then
      log_info "Se detectó paquete offline: $offline_dir"
      echo ""
      
      if ask_yes_no "¿Deseas importar imágenes desde el paquete offline?" "y"; then
        echo ""
        log_info "Importando imágenes desde $offline_dir..."
        # Usar ruta absoluta para evitar problemas de contexto
        local absolute_offline_dir="$(cd "$offline_dir" && pwd)"
        bash scripts/import_images.sh "$absolute_offline_dir" || true
        echo ""
        return 0
      fi
    fi
    
    echo ""
    if ask_yes_no "¿Deseas descargar las imágenes faltantes desde Internet?" "y"; then
      echo ""
      log_info "Descargando imágenes Docker..."
      for img in "${missing[@]}"; do
        log_info "Descargando $img..."
        docker pull "$img" || log_error "Error al descargar $img"
      done
      echo ""
      log_success "Descarga completada"
    else
      log_warning "Continuando sin descargar imágenes..."
      log_warning "El despliegue puede fallar si las imágenes no están disponibles"
    fi
  else
    log_success "Todas las imágenes Docker están disponibles localmente"
  fi
  
  echo ""
}

# ============================================
# Configurar directorio de instalación
# ============================================
configure_install_dir() {
  local default_dir="$HOME/Intranet-Escolar-con-Nextcloud"
  
  INSTALL_DIR="${INSTALL_DIR:-$default_dir}"
  
  log_info "Directorio de instalación por defecto: ${CYAN}$INSTALL_DIR${NC}"
  echo ""
  
  if ask_yes_no "¿Deseas usar este directorio?" "y"; then
    echo ""
  else
    echo ""
    read -p "$(echo -e "${YELLOW}[?]${NC} Introduce la ruta completa del directorio: ")" custom_dir
    if [ -n "$custom_dir" ]; then
      INSTALL_DIR="$custom_dir"
    fi
    echo ""
  fi
  
  log_success "Directorio configurado: $INSTALL_DIR"
  echo ""
}

# ============================================
# Clonar o actualizar repositorio
# ============================================
get_source_code() {
  log_step "Obteniendo código fuente..."
  echo ""
  
  local REPO_URL="https://github.com/JohnFredydev/Intranet-Escolar-con-Nextcloud.git"
  
  if [ -d "$INSTALL_DIR/.git" ]; then
    log_info "Repositorio existente detectado"
    echo ""
    
    if ask_yes_no "¿Deseas actualizar el repositorio existente?" "y"; then
      echo ""
      cd "$INSTALL_DIR"
      log_info "Actualizando repositorio..."
      if git pull --ff-only; then
        log_success "Repositorio actualizado correctamente"
      else
        log_warning "No se pudo actualizar automáticamente"
        log_info "Puedes revisar manualmente: cd $INSTALL_DIR && git status"
      fi
    else
      log_info "Usando repositorio existente sin actualizar"
      cd "$INSTALL_DIR"
    fi
  elif [ -d "$INSTALL_DIR" ]; then
    log_error "El directorio $INSTALL_DIR existe pero no es un repositorio git"
    echo ""
    
    if ask_yes_no "¿Deseas eliminarlo y clonar de nuevo?" "n"; then
      echo ""
      rm -rf "$INSTALL_DIR"
      log_info "Clonando repositorio desde GitHub..."
      git clone "$REPO_URL" "$INSTALL_DIR"
      cd "$INSTALL_DIR"
      log_success "Repositorio clonado correctamente"
    else
      log_error "No se puede continuar con un directorio inválido"
      exit 1
    fi
  else
    log_info "Clonando repositorio desde GitHub..."
    log_info "URL: $REPO_URL"
    echo ""
    
    if git clone "$REPO_URL" "$INSTALL_DIR"; then
      cd "$INSTALL_DIR"
      log_success "Repositorio clonado correctamente"
    else
      log_error "Error al clonar el repositorio"
      exit 1
    fi
  fi
  
  echo ""
}

# ============================================
# Configurar permisos
# ============================================
setup_permissions() {
  log_step "Configurando permisos de scripts..."
  
  if [ -d "scripts" ]; then
    chmod +x scripts/*.sh 2>/dev/null || true
    chmod +x install.sh 2>/dev/null || true
    log_success "Permisos configurados correctamente"
  else
    log_warning "Directorio scripts/ no encontrado"
  fi
  
  echo ""
}

# ============================================
# Menú de opciones de despliegue
# ============================================
deployment_menu() {
  log_title "╔════════════════════════════════════════════════════════════╗"
  log_title "║           OPCIONES DE DESPLIEGUE                           ║"
  log_title "╚════════════════════════════════════════════════════════════╝"
  echo ""
  echo -e "  ${BOLD}1.${NC} Despliegue completo automático (recomendado)"
  echo "     → Levanta servicios y configura entorno educativo"
  echo ""
  echo -e "  ${BOLD}2.${NC} Solo levantar servicios Docker"
  echo "     → Sin configuración educativa"
  echo ""
  echo -e "  ${BOLD}3.${NC} Configuración manual paso a paso"
  echo "     → Control total del proceso"
  echo ""
  echo -e "  ${BOLD}4.${NC} Salir sin desplegar"
  echo ""
  
  read -p "$(echo -e "${YELLOW}[?]${NC} Selecciona una opción [1-4]: ")" -n 1 -r option
  echo ""
  echo ""
  
  case "$option" in
    1)
      log_info "Iniciando despliegue completo automático..."
      echo ""
      bash scripts/init.sh
      ;;
    2)
      log_info "Levantando solo servicios Docker..."
      echo ""
      if [ ! -f ".env" ] && [ -f ".env.example" ]; then
        cp .env.example .env
        log_success "Archivo .env creado desde plantilla"
      fi
      docker compose -f docker-compose.yml -f compose.db.healthpatch.yml up -d
      log_success "Servicios levantados. Accede a http://localhost:8080"
      ;;
    3)
      manual_deployment
      ;;
    4)
      log_info "Instalación preparada. Puedes desplegar más tarde con:"
      echo -e "  ${CYAN}cd $INSTALL_DIR${NC}"
      echo -e "  ${CYAN}bash scripts/init.sh${NC}"
      echo ""
      exit 0
      ;;
    *)
      log_error "Opción no válida"
      deployment_menu
      ;;
  esac
}

# ============================================
# Despliegue manual paso a paso
# ============================================
manual_deployment() {
  log_info "Despliegue manual paso a paso"
  echo ""
  
  # Paso 1: .env
  if [ ! -f ".env" ]; then
    log_info "Paso 1: Configuración de variables de entorno"
    if ask_yes_no "¿Deseas crear .env desde la plantilla?" "y"; then
      cp .env.example .env
      log_success ".env creado"
      echo ""
      if ask_yes_no "¿Deseas editar las credenciales ahora?" "n"; then
        ${EDITOR:-nano} .env
      fi
    fi
  fi
  
  echo ""
  
  # Paso 2: Levantar servicios
  log_info "Paso 2: Levantar servicios Docker"
  if ask_yes_no "¿Deseas levantar los servicios ahora?" "y"; then
    echo ""
    docker compose -f docker-compose.yml -f compose.db.healthpatch.yml up -d
    log_success "Servicios levantados"
  fi
  
  echo ""
  
  # Paso 3: Configuración educativa
  log_info "Paso 3: Configuración del entorno educativo"
  if ask_yes_no "¿Deseas ejecutar la configuración educativa?" "y"; then
    echo ""
    bash scripts/cole_setup.sh
  fi
  
  echo ""
  
  # Paso 4: Usuarios demo
  log_info "Paso 4: Creación de usuarios de demostración"
  if ask_yes_no "¿Deseas crear usuarios de demo?" "y"; then
    echo ""
    bash scripts/alta_colegio_basica.sh
  fi
  
  echo ""
  
  # Paso 5: Evidencias
  log_info "Paso 5: Generación de evidencias técnicas"
  if ask_yes_no "¿Deseas generar evidencias?" "y"; then
    echo ""
    bash scripts/evidencias.sh
  fi
  
  echo ""
  log_success "Despliegue manual completado"
}

# ============================================
# Resumen final
# ============================================
show_final_summary() {
  echo ""
  log_title "╔════════════════════════════════════════════════════════════╗"
  log_title "║         INSTALACIÓN COMPLETADA EXITOSAMENTE               ║"
  log_title "╚════════════════════════════════════════════════════════════╝"
  echo ""
  
  log_success "Proyecto instalado en: ${CYAN}$INSTALL_DIR${NC}"
  echo ""
  
  log_info "Servicios disponibles:"
  echo -e "  → Nextcloud:    ${CYAN}http://localhost:8080${NC}"
  echo -e "  → Uptime Kuma:  ${CYAN}http://localhost:3001${NC}"
  echo ""
  
  log_info "Comandos útiles:"
  echo -e "  ${CYAN}cd $INSTALL_DIR${NC}"
  echo -e "  ${CYAN}docker compose ps${NC}                    # Ver estado"
  echo -e "  ${CYAN}docker compose logs -f app${NC}           # Ver logs"
  echo -e "  ${CYAN}docker compose down${NC}                  # Detener"
  echo -e "  ${CYAN}bash scripts/backup.sh${NC}               # Backup"
  echo -e "  ${CYAN}bash scripts/evidencias.sh${NC}           # Evidencias"
  echo ""
  
  log_success "¡Disfruta de tu intranet escolar con Nextcloud!"
  echo ""
}

# ============================================
# MAIN - Flujo principal
# ============================================
main() {
  show_menu
  check_requirements
  configure_install_dir
  get_source_code
  check_docker_images
  setup_permissions
  deployment_menu
  show_final_summary
}

main
