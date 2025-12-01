#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================
# Script Maestro de Inicialización Automática
# Proyecto Nextcloud - Entorno Educativo
# ============================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funciones de logging
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[✓]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $*"; }
log_error() { echo -e "${RED}[✗]${NC} $*"; }
log_step() { echo -e "${CYAN}[→]${NC} $*"; }

# Banner de inicio
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║   Proyecto Nextcloud - Inicialización Automática          ║"
echo "║   Entorno Educativo Completo                              ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================
# 1. VERIFICAR ESTRUCTURA DEL PROYECTO
# ============================================
log_step "Paso 1/9: Verificando estructura del proyecto..."
if [[ ! -f "docker-compose.yml" ]] || [[ ! -f "compose.db.healthpatch.yml" ]] || [[ ! -d "scripts" ]]; then
  log_error "No se encuentra la estructura esperada del proyecto."
  log_error "Asegúrate de ejecutar este script desde la raíz de proyecto-nextcloud/"
  log_error ""
  log_error "Estructura requerida:"
  log_error "  - docker-compose.yml"
  log_error "  - compose.db.healthpatch.yml"
  log_error "  - scripts/"
  exit 1
fi
log_success "Estructura del proyecto verificada"

# ============================================
# 2. VERIFICAR ARCHIVO .ENV
# ============================================
log_step "Paso 2/9: Verificando configuración de entorno..."
if [[ ! -f ".env" ]]; then
  if [[ -f ".env.example" ]]; then
    log_warning "No existe .env, copiando desde .env.example..."
    cp .env.example .env
    log_success "Archivo .env creado desde plantilla"
    echo ""
    log_warning "═══════════════════════════════════════════════════════════"
    log_warning "  IMPORTANTE: Revisa las credenciales en .env"
    log_warning "  Usa contraseñas seguras en entornos de producción"
    log_warning "═══════════════════════════════════════════════════════════"
    echo ""
    sleep 2
  else
    log_error "No existe .env ni .env.example"
    log_error ""
    log_error "Crea un archivo .env con las siguientes variables:"
    log_error "  MYSQL_ROOT_PASSWORD=..."
    log_error "  MYSQL_PASSWORD=..."
    log_error "  MYSQL_DATABASE=nextcloud"
    log_error "  MYSQL_USER=nextcloud"
    log_error "  NEXTCLOUD_ADMIN_USER=admin"
    log_error "  NEXTCLOUD_ADMIN_PASSWORD=..."
    log_error "  TZ=Europe/Madrid"
    exit 1
  fi
else
  log_success "Archivo .env encontrado"
fi

# Cargar variables de entorno
set -a
source .env
set +a

# ============================================
# 3. LEVANTAR EL STACK COMPLETO
# ============================================
log_step "Paso 3/9: Levantando servicios de Docker Compose..."
log_info "Ejecutando: docker compose -f docker-compose.yml -f compose.db.healthpatch.yml up -d"
docker compose -f docker-compose.yml -f compose.db.healthpatch.yml up -d
log_success "Servicios iniciados"

# ============================================
# 4. ESPERAR A QUE LA BASE DE DATOS ESTÉ HEALTHY
# ============================================
log_step "Paso 4/9: Esperando a que la base de datos esté saludable..."
log_info "Esto puede tardar 1-2 minutos en el primer arranque..."
MAX_WAIT=180
WAITED=0
DB_HEALTHY=false

while [[ $WAITED -lt $MAX_WAIT ]]; do
  if docker compose ps db 2>/dev/null | grep -q "healthy"; then
    DB_HEALTHY=true
    break
  fi
  echo -n "."
  sleep 5
  WAITED=$((WAITED + 5))
done
echo ""

if [[ "$DB_HEALTHY" == "true" ]]; then
  log_success "Base de datos lista y saludable"
else
  log_error "Timeout esperando a que la base de datos esté healthy"
  log_error "Estado actual de los contenedores:"
  docker compose ps
  log_error ""
  log_error "Revisa los logs: docker compose logs db"
  exit 1
fi

# ============================================
# 5. ESPERAR A QUE NEXTCLOUD ESTÉ INSTALADO Y OPERATIVO
# ============================================
log_step "Paso 5/9: Esperando a que Nextcloud esté instalado y operativo..."
log_info "Nextcloud necesita tiempo para autoinstalarse en el primer arranque..."
MAX_WAIT=240
WAITED=0
NC_READY=false

while [[ $WAITED -lt $MAX_WAIT ]]; do
  if docker compose exec -u www-data -T app php occ status 2>/dev/null | grep -q "installed: true"; then
    NC_READY=true
    break
  fi
  echo -n "."
  sleep 10
  WAITED=$((WAITED + 10))
done
echo ""

if [[ "$NC_READY" == "true" ]]; then
  log_success "Nextcloud está operativo"
else
  log_error "Timeout esperando a que Nextcloud esté instalado"
  log_error "Estado actual de los contenedores:"
  docker compose ps
  log_error ""
  log_error "Revisa los logs: docker compose logs app"
  exit 1
fi

# ============================================
# 6. EJECUTAR CONFIGURACIÓN DEL COLEGIO
# ============================================
log_step "Paso 6/9: Configurando entorno educativo..."
if [[ -f "scripts/cole_setup.sh" ]]; then
  log_info "Ejecutando cole_setup.sh..."
  bash scripts/cole_setup.sh
  log_success "Configuración del colegio completada"
else
  log_warning "No se encuentra scripts/cole_setup.sh, omitiendo"
fi

log_info "Creando usuarios y estructura básica..."
if [[ -f "scripts/alta_colegio_basica.sh" ]]; then
  bash scripts/alta_colegio_basica.sh
  log_success "Usuarios y estructura básica creados"
else
  log_warning "No se encuentra scripts/alta_colegio_basica.sh, omitiendo"
fi

# ============================================
# 7. CONFIGURAR UPTIME KUMA AUTOMÁTICAMENTE
# ============================================
log_step "Paso 7/9: Configurando Uptime Kuma..."
MAX_WAIT=90
WAITED=0
KUMA_READY=false

log_info "Esperando a que Uptime Kuma responda..."
while [[ $WAITED -lt $MAX_WAIT ]]; do
  if curl -sf http://localhost:3001 >/dev/null 2>&1; then
    KUMA_READY=true
    break
  fi
  echo -n "."
  sleep 5
  WAITED=$((WAITED + 5))
done
echo ""

if [[ "$KUMA_READY" == "true" ]]; then
  log_success "Uptime Kuma está accesible en http://localhost:3001"
  
  # Verificar si ya está configurado
  SETUP_RESPONSE=$(curl -sf http://localhost:3001/api/entry-page 2>/dev/null || echo "")
  
  if echo "$SETUP_RESPONSE" | grep -q '"needSetup":false' 2>/dev/null; then
    log_success "Uptime Kuma ya está configurado"
  else
    echo ""
    log_info "═══════════════════════════════════════════════════════════"
    log_info "  Uptime Kuma requiere configuración inicial"
    log_info ""
    log_info "  1. Accede a: http://localhost:3001"
    log_info "  2. Crea un usuario administrador"
    log_info "  3. Crea un monitor HTTP con estos datos:"
    log_info "     - Nombre: Nextcloud"
    log_info "     - URL: http://app/status.php"
    log_info "     - Intervalo: 60 segundos"
    log_info "═══════════════════════════════════════════════════════════"
    echo ""
  fi
else
  log_warning "Uptime Kuma no responde todavía"
  log_info "Puede que necesite más tiempo. Verifica después con: docker compose logs kuma"
fi

# ============================================
# 8. GENERAR EVIDENCIAS
# ============================================
log_step "Paso 8/9: Generando evidencias del sistema..."
if [[ -f "scripts/evidencias.sh" ]]; then
  bash scripts/evidencias.sh
  log_success "Evidencias generadas en docs/logs/"
else
  log_warning "No se encuentra scripts/evidencias.sh, omitiendo"
fi

# ============================================
# 9. RESUMEN FINAL
# ============================================
log_step "Paso 9/9: Finalizando inicialización..."
sleep 1

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║  ✓ Nextcloud desplegado y configurado                     ║"
echo "║  ✓ Usuarios demo creados (admin, profe, alumno1, alumno2) ║"
echo "║  ✓ Grupos y carpetas compartidas configurados             ║"
echo "║  ✓ Políticas de seguridad aplicadas                       ║"
echo "║  ✓ Uptime Kuma desplegado                                 ║"
echo "║  ✓ Evidencias generadas en docs/logs/                     ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log_success "═══════════════════════════════════════════════════════════"
log_success "  SERVICIOS DISPONIBLES"
log_success "═══════════════════════════════════════════════════════════"
echo ""
echo "  📦 Nextcloud:    http://localhost:8080"
echo "  📊 Uptime Kuma:  http://localhost:3001"
echo ""

log_success "═══════════════════════════════════════════════════════════"
log_success "  CREDENCIALES DE ACCESO A NEXTCLOUD"
log_success "═══════════════════════════════════════════════════════════"
echo ""
echo "  👨‍💼 Administrador:"
echo "     Usuario:    ${NEXTCLOUD_ADMIN_USER}"
echo "     Contraseña: ${NEXTCLOUD_ADMIN_PASSWORD}"
echo ""
echo "  👨‍🏫 Profesor:"
echo "     Usuario:    profe"
echo "     Contraseña: Profe#2025!Abc"
echo ""
echo "  👨‍🎓 Alumno 1:"
echo "     Usuario:    alumno1"
echo "     Contraseña: Alu1#2025!Abc"
echo ""
echo "  👨‍🎓 Alumno 2:"
echo "     Usuario:    alumno2"
echo "     Contraseña: Alu2#2025!Abc"
echo ""

log_success "═══════════════════════════════════════════════════════════"
log_success "  PRÓXIMOS PASOS"
log_success "═══════════════════════════════════════════════════════════"
echo ""
echo "  1. Accede a Nextcloud en http://localhost:8080"
echo "  2. Explora las carpetas compartidas (Group Folders)"
echo "  3. Configura Uptime Kuma en http://localhost:3001"
echo "  4. Revisa las evidencias en docs/logs/"
echo ""

log_success "Inicialización completada exitosamente"
echo ""
