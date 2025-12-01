#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Script Maestro de Inicialización Interactiva
# Proyecto Nextcloud - Entorno Educativo
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
  local default="${2:-y}"
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

show_banner() {
  echo ""
  log_title "╔════════════════════════════════════════════════════════════╗"
  log_title "║                                                            ║"
  log_title "║   Intranet Escolar con Nextcloud                           ║"
  log_title "║   Inicialización Interactiva - Proyecto Final ASIR        ║"
  log_title "║                                                            ║"
  log_title "╚════════════════════════════════════════════════════════════╝"
  echo ""
}

# ============================================
# 1. VERIFICAR ESTRUCTURA
# ============================================
verify_structure() {
  log_step "Verificando estructura del proyecto..."
  
  local missing=()
  
  [[ ! -f "docker-compose.yml" ]] && missing+=("docker-compose.yml")
  [[ ! -f "compose.db.healthpatch.yml" ]] && missing+=("compose.db.healthpatch.yml")
  [[ ! -d "scripts" ]] && missing+=("scripts/")
  [[ ! -f ".env.example" ]] && missing+=(".env.example")
  
  if [ ${#missing[@]} -gt 0 ]; then
    log_error "Estructura del proyecto incompleta. Faltan:"
    for item in "${missing[@]}"; do
      echo "  - $item"
    done
    echo ""
    log_error "Ejecuta este script desde la raíz del proyecto"
    exit 1
  fi
  
  log_success "Estructura verificada correctamente"
  echo ""
}

# ============================================
# 2. CONFIGURAR .ENV
# ============================================
configure_env() {
  log_step "Configurando variables de entorno..."
  echo ""
  
  if [[ -f ".env" ]]; then
    log_success "Archivo .env encontrado"
    echo ""
    
    if ask_yes_no "¿Deseas revisar/editar las credenciales en .env?" "n"; then
      echo ""
      log_info "Abriendo editor..."
      ${EDITOR:-nano} .env
      echo ""
    fi
  else
    log_warning "No existe archivo .env"
    echo ""
    
    if [[ -f ".env.example" ]]; then
      log_info "Plantilla .env.example disponible"
      echo ""
      
      if ask_yes_no "¿Deseas crear .env desde la plantilla?" "y"; then
        cp .env.example .env
        log_success "Archivo .env creado"
        echo ""
        
        log_warning "═══════════════════════════════════════════════════════════"
        log_warning "  IMPORTANTE: Revisa las credenciales antes de producción"
        log_warning "  Credenciales actuales son solo para demostración"
        log_warning "═══════════════════════════════════════════════════════════"
        echo ""
        
        if ask_yes_no "¿Deseas editar las credenciales ahora?" "n"; then
          echo ""
          ${EDITOR:-nano} .env
          echo ""
        fi
      else
        log_error "No se puede continuar sin archivo .env"
        exit 1
      fi
    else
      log_error "No existe .env.example. No se puede continuar."
      exit 1
    fi
  fi
  
  # Cargar variables
  set -a
  source .env
  set +a
  
  log_success "Variables de entorno cargadas"
  echo ""
}

# ============================================
# 3. MENÚ DE MODO DE DESPLIEGUE
# ============================================
deployment_mode_menu() {
  log_title "╔════════════════════════════════════════════════════════════╗"
  log_title "║           SELECCIÓN DE MODO DE DESPLIEGUE                 ║"
  log_title "╚════════════════════════════════════════════════════════════╝"
  echo ""
  echo "  ${BOLD}1.${NC} Modo Automático (Recomendado)"
  echo "     → Despliegue completo sin preguntas adicionales"
  echo "     → Ideal para primera instalación o demos"
  echo ""
  echo "  ${BOLD}2.${NC} Modo Interactivo"
  echo "     → Pregunta antes de cada paso importante"
  echo "     → Control total del proceso"
  echo ""
  echo "  ${BOLD}3.${NC} Modo Rápido (Solo servicios)"
  echo "     → Solo levanta Docker Compose"
  echo "     → Sin configuración educativa"
  echo ""
  
  read -p "$(echo -e "${YELLOW}[?]${NC} Selecciona modo [1-3]: ")" -n 1 -r mode
  echo ""
  echo ""
  
  case "$mode" in
    1) DEPLOY_MODE="auto" ;;
    2) DEPLOY_MODE="interactive" ;;
    3) DEPLOY_MODE="fast" ;;
    *) 
      log_warning "Opción no válida, usando modo automático"
      DEPLOY_MODE="auto"
      ;;
  esac
  
  log_success "Modo seleccionado: $DEPLOY_MODE"
  echo ""
}

# ============================================
# 4. LEVANTAR SERVICIOS DOCKER
# ============================================
start_services() {
  local skip=false
  
  if [[ "$DEPLOY_MODE" == "interactive" ]]; then
    if ! ask_yes_no "¿Deseas levantar los servicios Docker ahora?" "y"; then
      skip=true
    fi
    echo ""
  fi
  
  if [[ "$skip" == "false" ]]; then
    log_step "Levantando servicios Docker Compose..."
    log_info "Comando: docker compose -f docker-compose.yml -f compose.db.healthpatch.yml up -d"
    echo ""
    
    if docker compose -f docker-compose.yml -f compose.db.healthpatch.yml up -d; then
      log_success "Servicios iniciados correctamente"
    else
      log_error "Error al iniciar servicios"
      exit 1
    fi
    echo ""
  fi
}

# ============================================
# 5. ESPERAR BASE DE DATOS
# ============================================
wait_database() {
  local skip=false
  
  if [[ "$DEPLOY_MODE" == "fast" ]]; then
    log_info "Modo rápido: omitiendo espera de base de datos"
    return 0
  fi
  
  if [[ "$DEPLOY_MODE" == "interactive" ]]; then
    if ! ask_yes_no "¿Deseas esperar a que la base de datos esté lista?" "y"; then
      skip=true
    fi
    echo ""
  fi
  
  if [[ "$skip" == "false" ]]; then
    log_step "Esperando a que la base de datos esté lista..."
    log_info "Esto puede tardar 1-2 minutos en el primer arranque"
    echo ""
    
    local max_wait=180
    local waited=0
    local db_ready=false
    
    while [[ $waited -lt $max_wait ]]; do
      if docker compose ps db 2>/dev/null | grep -q "healthy"; then
        db_ready=true
        break
      fi
      echo -n "."
      sleep 5
      waited=$((waited + 5))
    done
    echo ""
    
    if [[ "$db_ready" == "true" ]]; then
      log_success "Base de datos lista y saludable"
    else
      log_error "Timeout esperando base de datos (${max_wait}s)"
      log_info "Estado de contenedores:"
      docker compose ps
      echo ""
      
      if [[ "$DEPLOY_MODE" == "interactive" ]]; then
        if ask_yes_no "¿Deseas continuar de todos modos?" "n"; then
          log_warning "Continuando sin verificar base de datos..."
        else
          exit 1
        fi
      else
        exit 1
      fi
    fi
    echo ""
  fi
}

# ============================================
# 6. ESPERAR NEXTCLOUD
# ============================================
wait_nextcloud() {
  local skip=false
  
  if [[ "$DEPLOY_MODE" == "fast" ]]; then
    log_info "Modo rápido: omitiendo espera de Nextcloud"
    return 0
  fi
  
  if [[ "$DEPLOY_MODE" == "interactive" ]]; then
    if ! ask_yes_no "¿Deseas esperar a que Nextcloud esté instalado?" "y"; then
      skip=true
    fi
    echo ""
  fi
  
  if [[ "$skip" == "false" ]]; then
    log_step "Esperando a que Nextcloud esté instalado..."
    log_info "Primera instalación puede tardar 2-4 minutos"
    echo ""
    
    local max_wait=240
    local waited=0
    local nc_ready=false
    
    while [[ $waited -lt $max_wait ]]; do
      if docker compose exec -u www-data -T app php occ status 2>/dev/null | grep -q "installed: true"; then
        nc_ready=true
        break
      fi
      echo -n "."
      sleep 10
      waited=$((waited + 10))
    done
    echo ""
    
    if [[ "$nc_ready" == "true" ]]; then
      log_success "Nextcloud instalado y operativo"
    else
      log_error "Timeout esperando instalación de Nextcloud (${max_wait}s)"
      log_info "Estado de contenedores:"
      docker compose ps
      echo ""
      
      if [[ "$DEPLOY_MODE" == "interactive" ]]; then
        if ask_yes_no "¿Deseas continuar de todos modos?" "n"; then
          log_warning "Continuando sin verificar Nextcloud..."
        else
          exit 1
        fi
      else
        exit 1
      fi
    fi
    echo ""
  fi
}

# ============================================
# 7. CONFIGURACIÓN EDUCATIVA
# ============================================
run_educational_setup() {
  local skip=false
  
  if [[ "$DEPLOY_MODE" == "fast" ]]; then
    log_info "Modo rápido: omitiendo configuración educativa"
    return 0
  fi
  
  if [[ "$DEPLOY_MODE" == "interactive" ]]; then
    echo ""
    log_info "Configuración educativa incluye:"
    echo "  - Grupos de profesorado y alumnado"
    echo "  - Grupos por cursos (ESO, Bachillerato, FP)"
    echo "  - Carpetas compartidas (Group Folders)"
    echo "  - Políticas de seguridad"
    echo "  - Theming personalizado"
    echo ""
    
    if ! ask_yes_no "¿Deseas ejecutar la configuración educativa?" "y"; then
      skip=true
    fi
    echo ""
  fi
  
  if [[ "$skip" == "false" ]]; then
    log_step "Ejecutando configuración educativa..."
    echo ""
    
    if [[ -f "scripts/cole_setup.sh" ]]; then
      bash scripts/cole_setup.sh
      log_success "Configuración educativa completada"
    else
      log_warning "No se encuentra scripts/cole_setup.sh"
    fi
    echo ""
  fi
}

# ============================================
# 8. USUARIOS DE DEMOSTRACIÓN
# ============================================
create_demo_users() {
  local skip=false
  
  if [[ "$DEPLOY_MODE" == "fast" ]]; then
    log_info "Modo rápido: omitiendo creación de usuarios demo"
    return 0
  fi
  
  if [[ "$DEPLOY_MODE" == "interactive" ]]; then
    echo ""
    log_info "Usuarios de demostración a crear:"
    echo "  - profe (Profesor/a, 5 GB)"
    echo "  - alumno1 (Alumno 1ESO, 1 GB)"
    echo "  - alumno2 (Alumno 1ESO, 1 GB)"
    echo ""
    
    if ! ask_yes_no "¿Deseas crear usuarios de demostración?" "y"; then
      skip=true
    fi
    echo ""
  fi
  
  if [[ "$skip" == "false" ]]; then
    log_step "Creando usuarios de demostración..."
    echo ""
    
    if [[ -f "scripts/alta_colegio_basica.sh" ]]; then
      bash scripts/alta_colegio_basica.sh
      log_success "Usuarios de demostración creados"
    else
      log_warning "No se encuentra scripts/alta_colegio_basica.sh"
    fi
    echo ""
  fi
}

# ============================================
# 9. CONFIGURAR UPTIME KUMA
# ============================================
configure_uptime_kuma() {
  local skip=false
  
  if [[ "$DEPLOY_MODE" == "fast" ]]; then
    return 0
  fi
  
  log_step "Verificando Uptime Kuma..."
  
  local max_wait=60
  local waited=0
  local kuma_ready=false
  
  while [[ $waited -lt $max_wait ]]; do
    if curl -sf http://localhost:3001 >/dev/null 2>&1; then
      kuma_ready=true
      break
    fi
    sleep 5
    waited=$((waited + 5))
  done
  
  if [[ "$kuma_ready" == "true" ]]; then
    log_success "Uptime Kuma accesible en http://localhost:3001"
    echo ""
    log_info "═══════════════════════════════════════════════════════════"
    log_info "  Configuración de Uptime Kuma (manual):"
    log_info "  1. Accede a http://localhost:3001"
    log_info "  2. Crea un usuario administrador"
    log_info "  3. Añade monitor HTTP: http://app/status.php"
    log_info "═══════════════════════════════════════════════════════════"
  else
    log_warning "Uptime Kuma no responde aún"
    log_info "Puede tardar unos minutos más. Verifica: docker compose logs kuma"
  fi
  
  echo ""
}

# ============================================
# 10. GENERAR EVIDENCIAS
# ============================================
generate_evidence() {
  local skip=false
  
  if [[ "$DEPLOY_MODE" == "fast" ]]; then
    return 0
  fi
  
  if [[ "$DEPLOY_MODE" == "interactive" ]]; then
    if ! ask_yes_no "¿Deseas generar evidencias técnicas?" "y"; then
      skip=true
    fi
    echo ""
  fi
  
  if [[ "$skip" == "false" ]]; then
    log_step "Generando evidencias técnicas..."
    echo ""
    
    if [[ -f "scripts/evidencias.sh" ]]; then
      bash scripts/evidencias.sh
      log_success "Evidencias generadas en docs/logs/"
    else
      log_warning "No se encuentra scripts/evidencias.sh"
    fi
    echo ""
  fi
}

# ============================================
# 11. RESUMEN FINAL
# ============================================
show_summary() {
  echo ""
  log_title "╔════════════════════════════════════════════════════════════╗"
  log_title "║         INICIALIZACIÓN COMPLETADA EXITOSAMENTE            ║"
  log_title "╚════════════════════════════════════════════════════════════╝"
  echo ""
  
  log_success "Servicios desplegados correctamente"
  echo ""
  
  log_info "Servicios disponibles:"
  echo "  → Nextcloud:    ${CYAN}http://localhost:8080${NC}"
  echo "  → Uptime Kuma:  ${CYAN}http://localhost:3001${NC}"
  echo ""
  
  log_info "Credenciales de acceso (demo):"
  echo ""
  echo "  ${BOLD}Administrador:${NC}"
  echo "    Usuario:    ${CYAN}${NEXTCLOUD_ADMIN_USER:-admin}${NC}"
  echo "    Contraseña: ${CYAN}${NEXTCLOUD_ADMIN_PASSWORD:-Admin#2025!Cole}${NC}"
  echo ""
  echo "  ${BOLD}Profesor:${NC}"
  echo "    Usuario:    ${CYAN}profe${NC}"
  echo "    Contraseña: ${CYAN}Profe#2025!Abc${NC}"
  echo ""
  echo "  ${BOLD}Alumnos:${NC}"
  echo "    Usuario:    ${CYAN}alumno1${NC} / ${CYAN}alumno2${NC}"
  echo "    Contraseña: ${CYAN}Alu1#2025!Abc${NC} / ${CYAN}Alu2#2025!Abc${NC}"
  echo ""
  
  log_info "Próximos pasos:"
  echo "  1. Accede a Nextcloud en ${CYAN}http://localhost:8080${NC}"
  echo "  2. Explora las carpetas compartidas (Group Folders)"
  echo "  3. Configura Uptime Kuma en ${CYAN}http://localhost:3001${NC}"
  echo "  4. Revisa las evidencias en ${CYAN}docs/logs/${NC}"
  echo ""
  
  log_info "Comandos útiles:"
  echo "  ${CYAN}docker compose ps${NC}                    # Ver estado"
  echo "  ${CYAN}docker compose logs -f app${NC}           # Ver logs"
  echo "  ${CYAN}docker compose down${NC}                  # Detener"
  echo "  ${CYAN}bash scripts/backup.sh${NC}               # Crear backup"
  echo "  ${CYAN}bash scripts/evidencias.sh${NC}           # Evidencias"
  echo ""
  
  log_success "¡Disfruta de tu intranet escolar con Nextcloud!"
  echo ""
}

# ============================================
# MAIN - Flujo principal
# ============================================
main() {
  show_banner
  verify_structure
  configure_env
  deployment_mode_menu
  start_services
  wait_database
  wait_nextcloud
  run_educational_setup
  create_demo_users
  configure_uptime_kuma
  generate_evidence
  show_summary
}

main
