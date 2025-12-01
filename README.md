# Intranet Escolar con Nextcloud

**Proyecto Final - Administración de Sistemas Informáticos en Red (ASIR)**

Despliegue completamente automatizado de una intranet escolar basada en Nextcloud, utilizando Docker Compose y MariaDB, orientada a centros educativos (ESO, Bachillerato, FP).

---

## Índice

1. [Descripción del Proyecto](#1-descripción-del-proyecto)
2. [Requisitos del Sistema](#2-requisitos-del-sistema)
3. [Despliegue Rápido](#3-despliegue-rápido)
4. [Estructura del Proyecto](#4-estructura-del-proyecto)
5. [Variables de Entorno](#5-variables-de-entorno)
6. [Servicios Desplegados](#6-servicios-desplegados)
7. [Credenciales de Acceso](#7-credenciales-de-acceso)
8. [Scripts Disponibles](#8-scripts-disponibles)
9. [Aprovisionamiento Offline de Imágenes Docker](#9-aprovisionamiento-offline-de-imágenes-docker)
10. [Operación Básica](#10-operación-básica)
11. [Backup y Restauración](#11-backup-y-restauración)
12. [Consideraciones de Seguridad](#12-consideraciones-de-seguridad)
13. [Licencia y Uso Educativo](#13-licencia-y-uso-educativo)

---

## 1. Descripción del Proyecto

Este proyecto implementa una **intranet escolar completa** utilizando Nextcloud como plataforma principal, diseñada específicamente para centros educativos. Incluye:

- **Nextcloud 29** con Apache como servidor web
- **MariaDB 11** como base de datos relacional
- **Contenedor de cron** dedicado para tareas programadas
- **Uptime Kuma** para monitorización de disponibilidad
- **Scripts de automatización** para configuración educativa completa
- **Sistema de backup y restauración** automático
- **Generación de evidencias** técnicas para memoria del proyecto

### Características educativas implementadas

- Grupos por perfiles (profesorado, alumnado, dirección, secretaría, TIC, orientación)
- Grupos por cursos (1ESO, 2ESO, 3ESO, 4ESO, 1BACH, 2BACH, FP1, FP2)
- Carpetas compartidas (Group Folders) con permisos diferenciados
- Políticas de compartición seguras
- Theming personalizado del centro
- Usuarios de demostración preconfigurados
- Cuotas de almacenamiento por perfiles

---

## 2. Requisitos del Sistema

### Sistema Operativo

- **Linux** (Ubuntu 20.04+ / Debian 11+ recomendados)
- **WSL2** en Windows 10/11 (también compatible)

### Software Necesario

| Software | Versión Mínima | Comando de Verificación |
|----------|----------------|------------------------|
| Docker | 20.10+ | `docker --version` |
| Docker Compose | 2.0+ (plugin) | `docker compose version` |
| Git | 2.20+ | `git --version` |
| Curl | 7.0+ | `curl --version` |
| Bash | 4.0+ | `bash --version` |

### Instalación de Requisitos en Ubuntu/Debian

```bash
# Actualizar repositorios
sudo apt update

# Instalar Docker y dependencias
sudo apt install -y docker.io docker-compose-plugin git curl

# Añadir usuario al grupo docker
sudo usermod -aG docker $USER

# Aplicar cambios de grupo
newgrp docker
```

### Recursos Recomendados

- **CPU**: 2 cores o más
- **RAM**: 4 GB mínimo (8 GB recomendado)
- **Almacenamiento**: 20 GB libres mínimo
- **Red**: Conexión a Internet para descargas iniciales

---

## 3. Despliegue Rápido

### 3.1. Instalación Remota (Recomendado)

Instalación automatizada desde GitHub con un solo comando:

```bash
bash <(curl -fsSL "https://raw.githubusercontent.com/JohnFredydev/Intranet-Escolar-con-Nextcloud/main/install.sh")
```

Este método:
- Verifica automáticamente los requisitos del sistema
- Clona o actualiza el repositorio
- Configura permisos de ejecución
- Ejecuta el script de inicialización completa
- Muestra credenciales y URLs al finalizar

**Personalizar directorio de instalación:**

```bash
INSTALL_DIR="$HOME/mi-intranet" bash <(curl -fsSL "https://raw.githubusercontent.com/JohnFredydev/Intranet-Escolar-con-Nextcloud/main/install.sh")
```

### 3.2. Despliegue Clásico (Recomendado para Desarrollo)

Método tradicional con control completo:

```bash
# 1. Clonar el repositorio
git clone https://github.com/JohnFredydev/Intranet-Escolar-con-Nextcloud.git
cd Intranet-Escolar-con-Nextcloud

# 2. Copiar plantilla de variables de entorno
cp .env.example .env

# 3. (Opcional) Editar credenciales
nano .env

# 4. Ejecutar inicialización completa
bash scripts/init.sh
```

El script `init.sh` realiza automáticamente:
1. Verificación de estructura del proyecto
2. Creación de archivo `.env` si no existe
3. Levantamiento del stack Docker Compose
4. Espera a que la base de datos esté healthy
5. Verificación de instalación de Nextcloud
6. Configuración del entorno educativo completo
7. Creación de usuarios de demostración
8. Generación de evidencias técnicas

**Tiempo estimado**: 3-5 minutos en el primer despliegue.

---

## 4. Estructura del Proyecto

```
Intranet-Escolar-con-Nextcloud/
├── docker-compose.yml                  # Definición principal de servicios
├── compose.db.healthpatch.yml          # Healthcheck mejorado para MariaDB
├── .env                                # Variables de entorno (creado al iniciar)
├── .env.example                        # Plantilla de configuración
├── .gitignore                          # Archivos excluidos de Git
├── install.sh                          # Instalador remoto
├── README.md                           # Este archivo
│
├── scripts/                            # Scripts de automatización
│   ├── init.sh                         # Script maestro de inicialización
│   ├── cole_setup.sh                   # Configuración del entorno educativo
│   ├── alta_colegio_basica.sh          # Alta de usuarios demo
│   ├── alta_usuarios.sh                # Alta de usuarios adicionales
│   ├── backup.sh                       # Sistema de backup completo
│   ├── restore.sh                      # Restauración desde backup
│   ├── evidencias.sh                   # Generación de evidencias técnicas
│   ├── provision_images.sh             # Verificación/descarga de imágenes Docker
│   ├── export_images.sh                # Exportación para uso offline
│   └── import_images.sh                # Importación de imágenes exportadas
│
├── docs/                               # Documentación y evidencias
│   └── logs/                           # Logs generados automáticamente
│       ├── sistema.txt                 # Información del sistema
│       ├── docker_ps.txt               # Estado de contenedores
│       ├── compose_merged.yml          # Configuración combinada
│       ├── db_logs.txt                 # Logs de base de datos
│       ├── occ_status.txt              # Estado de Nextcloud
│       ├── occ_users.txt               # Listado de usuarios
│       ├── occ_groups.txt              # Listado de grupos
│       └── occ_groupfolders.txt        # Configuración de carpetas compartidas
│
├── backups/                            # Copias de seguridad (generadas)
│   └── AAAAMMDD_HHMMSS/                # Backup con timestamp
│       ├── db.sql                      # Dump de base de datos
│       └── nextcloud_files.tgz         # Archivos de Nextcloud
│
├── docker-images-offline/              # Imágenes exportadas (opcional)
│   └── AAAAMMDD_HHMMSS/                # Exportación con timestamp
│       ├── mariadb_11.tar
│       ├── nextcloud_29-apache.tar
│       ├── louislam_uptime-kuma_1.tar
│       ├── import.sh                   # Script de importación
│       └── README.txt                  # Instrucciones
│
└── kuma/                               # Datos persistentes de Uptime Kuma
```

---

## 5. Variables de Entorno

El archivo `.env` contiene la configuración completa del proyecto. Se crea automáticamente desde `.env.example` al ejecutar `init.sh`.

### Tabla de Variables

| Variable | Descripción | Valor por Defecto | Notas |
|----------|-------------|-------------------|-------|
| `MYSQL_ROOT_PASSWORD` | Contraseña root de MariaDB | `Root#2025!Fuerte` | Cambiar en producción |
| `MYSQL_PASSWORD` | Contraseña del usuario de aplicación | `App#2025!Fuerte` | Cambiar en producción |
| `MYSQL_DATABASE` | Nombre de la base de datos | `nextcloud` | No cambiar |
| `MYSQL_USER` | Usuario de la base de datos | `nextcloud` | No cambiar |
| `NEXTCLOUD_ADMIN_USER` | Usuario administrador de Nextcloud | `admin` | Personalizable |
| `NEXTCLOUD_ADMIN_PASSWORD` | Contraseña del administrador | `Admin#2025!Cole` | Cambiar en producción |
| `TZ` | Zona horaria del sistema | `Europe/Madrid` | Formato IANA |

### Configuración Manual

```bash
# Copiar plantilla
cp .env.example .env

# Editar con tu editor preferido
nano .env
# o
vim .env
```

**Importante**: Nunca subas el archivo `.env` a repositorios públicos. Ya está incluido en `.gitignore`.

---

## 6. Servicios Desplegados

### 6.1. Nextcloud (app)

**Imagen**: `nextcloud:29-apache`

- **Puerto**: 8080 (host) → 80 (contenedor)
- **URL**: http://localhost:8080
- **Función**: Plataforma principal de intranet escolar
- **Volumen persistente**: `nextcloud`

### 6.2. MariaDB (db)

**Imagen**: `mariadb:11`

- **Puerto**: No expuesto (solo red interna)
- **Función**: Base de datos relacional para Nextcloud
- **Volumen persistente**: `db`
- **Healthcheck**: Verificación cada 10s con `mysqladmin ping`

### 6.3. Cron (cron)

**Imagen**: `nextcloud:29-apache`

- **Función**: Ejecuta tareas programadas de Nextcloud (`cron.php`)
- **Ventajas**: Desvincula ejecución de cron del tráfico web, mejora rendimiento
- **Comparte volumen**: `nextcloud` (con app)

### 6.4. Uptime Kuma (kuma)

**Imagen**: `louislam/uptime-kuma:1`

- **Puerto**: 3001 (host) → 3001 (contenedor)
- **URL**: http://localhost:3001
- **Función**: Monitorización de disponibilidad de Nextcloud
- **Volumen persistente**: `kuma`

---

## 7. Credenciales de Acceso

### 7.1. Nextcloud

Credenciales creadas automáticamente para demostración:

| Usuario | Contraseña | Rol | Grupo(s) | Cuota |
|---------|------------|-----|----------|-------|
| `admin` | `Admin#2025!Cole` | Administrador | admin | Ilimitada |
| `profe` | `Profe#2025!Abc` | Profesor | profesorado, 1ESO | 5 GB |
| `alumno1` | `Alu1#2025!Abc` | Alumno | alumnado, 1ESO, clase | 1 GB |
| `alumno2` | `Alu2#2025!Abc` | Alumno | alumnado, 1ESO, clase | 1 GB |

**Acceso**: http://localhost:8080

### 7.2. Uptime Kuma

- **Primera configuración**: Al acceder por primera vez a http://localhost:3001, se solicita crear un usuario administrador
- **No hay credenciales predefinidas**: El usuario debe configurarlas manualmente

**Configuración recomendada de monitor**:
- **Tipo**: HTTP(s)
- **URL**: `http://app/status.php` (usando nombre de servicio Docker)
- **Intervalo**: 60 segundos
- **Nombre**: Nextcloud Intranet

### 7.3. Base de Datos MariaDB

**Acceso interno** (solo desde contenedor app):

- **Host**: `db`
- **Usuario**: `nextcloud` (o variable `MYSQL_USER`)
- **Contraseña**: Valor de `MYSQL_PASSWORD` en `.env`
- **Base de datos**: `nextcloud`

**Acceso root** (para mantenimiento):

```bash
docker compose exec db mysql -u root -p
# Introducir MYSQL_ROOT_PASSWORD
```

---

## 8. Scripts Disponibles

### 8.1. init.sh - Inicialización Completa

Script maestro que orquesta todo el despliegue:

```bash
bash scripts/init.sh
```

**Funciones**:
1. Verifica estructura del proyecto
2. Crea `.env` si no existe
3. Levanta servicios Docker Compose
4. Espera a que la base de datos esté healthy (max 180s)
5. Verifica que Nextcloud esté instalado (max 240s)
6. Ejecuta `cole_setup.sh`
7. Ejecuta `alta_colegio_basica.sh`
8. Ejecuta `evidencias.sh`
9. Muestra resumen con URLs y credenciales

**Idempotencia**: Puede ejecutarse múltiples veces sin causar problemas.

### 8.2. cole_setup.sh - Configuración Educativa

Configura el entorno específico del centro educativo:

```bash
bash scripts/cole_setup.sh
```

**Configuraciones aplicadas**:

- **Apps habilitadas**: theming, groupfolders, calendar, contacts, tasks, spreed, viewer, files_pdfviewer
- **Theming**: Nombre, slogan, URL y color corporativo del centro
- **Configuración regional**: Idioma español (ES), zona horaria
- **Políticas de compartición**:
  - Enlaces con expiración obligatoria (30 días)
  - Contraseña obligatoria en enlaces
  - Compartición solo entre miembros del grupo
  - Carga pública deshabilitada
- **Grupos creados**:
  - Perfiles: profesorado, alumnado, direccion, secretaria, tic, orientacion
  - Cursos: 1ESO, 2ESO, 3ESO, 4ESO, 1BACH, 2BACH, FP1, FP2
- **Carpetas de grupo (Group Folders)**:
  - Claustro - Profesorado (solo profesorado, RW)
  - Secretaría (solo secretaria, RW)
  - Dirección (dirección RW, profesorado R)
  - Comunicados Alumnado (profesorado RW, alumnado R)
  - Curso [X] - Material (profesorado RW, curso específico R)
- **Skeleton directory**: Estructura de carpetas para nuevos usuarios

### 8.3. alta_colegio_basica.sh - Usuarios de Demostración

Crea los usuarios básicos para demostración:

```bash
bash scripts/alta_colegio_basica.sh
```

**Usuarios creados**: `profe`, `alumno1`, `alumno2` (ver sección 7.1).

### 8.4. alta_usuarios.sh - Alta de Usuarios Adicionales

Script base para crear usuarios adicionales. Puede adaptarse para:

- Cargar usuarios desde CSV
- Crear usuarios masivamente
- Integración con sistemas externos (LDAP, AD)

```bash
bash scripts/alta_usuarios.sh
```

### 8.5. backup.sh - Copia de Seguridad

Realiza backup completo del sistema:

```bash
bash scripts/backup.sh
```

**Contenido del backup**:
- Dump completo de la base de datos MariaDB (`db.sql`)
- Tarball comprimido con archivos de Nextcloud (`nextcloud_files.tgz`)
- Almacenamiento en `backups/AAAAMMDD_HHMMSS/`

**Uso recomendado**: Automatizar con cron para backups periódicos.

```bash
# Ejemplo: backup diario a las 02:00
0 2 * * * cd /ruta/al/proyecto && bash scripts/backup.sh
```

### 8.6. restore.sh - Restauración desde Backup

Restaura un backup previamente creado:

```bash
bash scripts/restore.sh backups/20251201_143022
```

**Proceso**:
1. Detiene los servicios
2. Restaura archivos de Nextcloud
3. Importa base de datos
4. Reinicia servicios

**Precaución**: Sobrescribe datos actuales. Usar solo cuando sea necesario.

### 8.7. evidencias.sh - Generación de Evidencias

Genera evidencias técnicas para la memoria del proyecto:

```bash
bash scripts/evidencias.sh
```

**Archivos generados en `docs/logs/`**:
- `sistema.txt`: Información del sistema host
- `docker_ps.txt`: Estado de contenedores
- `compose_merged.yml`: Configuración combinada de Compose
- `db_logs.txt`: Logs recientes de MariaDB
- `db_ping.txt`: Test de conectividad a base de datos
- `http_headers_app.txt`: Headers HTTP de Nextcloud
- `occ_status.txt`: Estado de Nextcloud (occ status)
- `occ_users.txt`: Listado completo de usuarios
- `occ_groups.txt`: Listado de grupos
- `occ_groupfolders.txt`: Configuración de Group Folders
- `occ_apps.txt`: Aplicaciones instaladas y habilitadas

---

## 9. Aprovisionamiento Offline de Imágenes Docker

Sistema completo para preparar demos sin conexión a Internet.

### 9.1. provision_images.sh - Verificación y Descarga

Verifica imágenes locales y ofrece descargarlas:

```bash
bash scripts/provision_images.sh
```

**Funcionalidad**:
- Lista imágenes necesarias: `mariadb:11`, `nextcloud:29-apache`, `louislam/uptime-kuma:1`
- Verifica cuáles están disponibles localmente
- Muestra tamaños de imágenes existentes
- Ofrece descargar las faltantes interactivamente

**Uso típico**: Ejecutar antes de exportar imágenes o en preparación de demo.

### 9.2. export_images.sh - Exportación para Offline

Exporta todas las imágenes necesarias a archivos `.tar`:

```bash
bash scripts/export_images.sh
```

**Resultado**:
- Directorio `docker-images-offline/AAAAMMDD_HHMMSS/`
- Archivos `.tar` para cada imagen:
  - `mariadb_11.tar`
  - `nextcloud_29-apache.tar`
  - `louislam_uptime-kuma_1.tar`
- Script `import.sh` generado automáticamente
- Archivo `README.txt` con instrucciones

**Uso típico**: Crear paquete offline para demos en otros equipos o USB.

### 9.3. import_images.sh - Importación de Imágenes

Importa imágenes desde directorio con archivos `.tar`:

```bash
bash scripts/import_images.sh docker-images-offline/20251201_143022
```

**Proceso**:
1. Verifica existencia del directorio
2. Busca todos los archivos `.tar`
3. Ejecuta `docker load -i` para cada archivo
4. Muestra resumen de importación
5. Lista imágenes disponibles

**Alternativa**: Usar el script `import.sh` generado dentro del directorio exportado:

```bash
cd docker-images-offline/20251201_143022
bash import.sh
```

### Flujo de Trabajo Offline Completo

**En equipo con Internet**:
```bash
# 1. Descargar imágenes
bash scripts/provision_images.sh

# 2. Exportar para offline
bash scripts/export_images.sh

# 3. Copiar directorio a USB
cp -r docker-images-offline/20251201_143022 /mnt/usb/
```

**En equipo sin Internet**:
```bash
# 1. Copiar directorio desde USB
cp -r /mnt/usb/20251201_143022 ~/

# 2. Importar imágenes
cd ~/20251201_143022
bash import.sh

# 3. Clonar proyecto (desde USB o Git local)
git clone /mnt/usb/Intranet-Escolar-con-Nextcloud.git
cd Intranet-Escolar-con-Nextcloud

# 4. Desplegar
bash scripts/init.sh
```

---

## 10. Operación Básica

### 10.1. Ver Estado de Servicios

```bash
# Estado de contenedores
docker compose ps

# Estado detallado (salud, puertos, tiempos)
docker compose ps -a

# Solo contenedores en ejecución
docker ps
```

### 10.2. Logs de Servicios

```bash
# Todos los servicios (seguimiento en tiempo real)
docker compose logs -f

# Servicio específico
docker compose logs -f app         # Nextcloud
docker compose logs -f db          # MariaDB
docker compose logs -f cron        # Cron de Nextcloud
docker compose logs -f kuma        # Uptime Kuma

# Últimas 100 líneas sin seguimiento
docker compose logs --tail=100 app

# Logs desde una fecha
docker compose logs --since 2025-12-01T10:00:00 app
```

### 10.3. Gestión de Contenedores

```bash
# Reiniciar todos los servicios
docker compose restart

# Reiniciar servicio específico
docker compose restart app

# Detener servicios (mantiene volúmenes)
docker compose down

# Detener y eliminar volúmenes (CUIDADO: borra datos)
docker compose down -v

# Levantar servicios
docker compose -f docker-compose.yml -f compose.db.healthpatch.yml up -d

# Reconstruir imágenes (si hay cambios)
docker compose build --no-cache
docker compose up -d
```

### 10.4. Comandos OCC de Nextcloud

OCC es la interfaz de línea de comandos de Nextcloud:

```bash
# Ejecutar comando occ
docker compose exec -u www-data -T app php occ <comando>

# Ejemplos útiles:

# Estado de Nextcloud
docker compose exec -u www-data -T app php occ status

# Listado de usuarios
docker compose exec -u www-data -T app php occ user:list

# Información de usuario específico
docker compose exec -u www-data -T app php occ user:info admin

# Listado de grupos
docker compose exec -u www-data -T app php occ group:list

# Aplicaciones instaladas
docker compose exec -u www-data -T app php occ app:list

# Crear usuario
docker compose exec -u www-data -T app php occ user:add <username>

# Resetear contraseña
docker compose exec -u www-data -T app php occ user:resetpassword <username>

# Mantenimiento
docker compose exec -u www-data -T app php occ maintenance:mode --on
docker compose exec -u www-data -T app php occ maintenance:mode --off

# Escanear archivos
docker compose exec -u www-data -T app php occ files:scan --all
```

### 10.5. Acceso a Shells de Contenedores

```bash
# Shell en contenedor de Nextcloud
docker compose exec app bash

# Shell como www-data (usuario de Nextcloud)
docker compose exec -u www-data app bash

# Shell en MariaDB
docker compose exec db bash

# Cliente MySQL directo
docker compose exec db mysql -u root -p
```

---

## 11. Backup y Restauración

### 11.1. Realizar Backup

```bash
bash scripts/backup.sh
```

**Salida**: `backups/AAAAMMDD_HHMMSS/`

**Contenido**:
- `db.sql`: Dump de base de datos
- `nextcloud_files.tgz`: Archivos de Nextcloud

### 11.2. Restaurar Backup

```bash
# Listar backups disponibles
ls -lh backups/

# Restaurar backup específico
bash scripts/restore.sh backups/20251201_143022
```

### 11.3. Automatización de Backups

**Cron en host**:

```bash
# Editar crontab
crontab -e

# Añadir línea (backup diario a las 02:00)
0 2 * * * cd /home/usuario/Intranet-Escolar-con-Nextcloud && bash scripts/backup.sh >> logs/backup.log 2>&1
```

**Systemd timer** (método alternativo):

```bash
# Crear servicio en /etc/systemd/system/nextcloud-backup.service
[Unit]
Description=Nextcloud Backup Service
After=docker.service

[Service]
Type=oneshot
WorkingDirectory=/home/usuario/Intranet-Escolar-con-Nextcloud
ExecStart=/usr/bin/bash scripts/backup.sh
User=usuario

# Crear timer en /etc/systemd/system/nextcloud-backup.timer
[Unit]
Description=Nextcloud Backup Timer

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target

# Activar
sudo systemctl enable --now nextcloud-backup.timer
```

### 11.4. Almacenamiento Externo de Backups

**Ejemplo con rsync a servidor remoto**:

```bash
# En scripts/backup.sh, añadir al final:
rsync -avz --delete backups/ usuario@servidor:/ruta/backups-nextcloud/
```

**Ejemplo con Rclone a almacenamiento en la nube**:

```bash
# Instalar rclone y configurar remoto
rclone sync backups/ remote:nextcloud-backups/
```

---

## 12. Consideraciones de Seguridad

### 12.1. Credenciales

**Cambio obligatorio en producción**:

```bash
# Editar .env ANTES del primer despliegue
nano .env
```

Modificar:
- `MYSQL_ROOT_PASSWORD`: Contraseña robusta (16+ caracteres)
- `MYSQL_PASSWORD`: Diferente a la de root
- `NEXTCLOUD_ADMIN_PASSWORD`: Contraseña compleja para administrador

**Criterios de contraseñas robustas**:
- Mínimo 16 caracteres
- Mayúsculas, minúsculas, números y símbolos
- No usar palabras del diccionario
- Diferente para cada servicio

### 12.2. HTTPS y Proxy Inverso

**Este proyecto usa HTTP** para demostraciones locales. En producción, **siempre usar HTTPS**.

**Opciones recomendadas**:

1. **Nginx Proxy Manager** (recomendado para principiantes)
2. **Traefik** (automático con Let's Encrypt)
3. **Nginx** manual con Certbot
4. **Caddy** (HTTPS automático)

**Ejemplo con Nginx**:

```nginx
server {
    listen 443 ssl http2;
    server_name intranet.micentro.edu;

    ssl_certificate /etc/letsencrypt/live/intranet.micentro.edu/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/intranet.micentro.edu/privkey.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 512M;
    }
}
```

### 12.3. Firewall

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP (redirigir a HTTPS)
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable

# Bloquear acceso directo a puerto 8080 desde Internet
sudo ufw deny 8080/tcp
```

### 12.4. Actualización de Imágenes

```bash
# Actualizar imágenes a últimas versiones
docker compose pull

# Reiniciar con nuevas imágenes
docker compose -f docker-compose.yml -f compose.db.healthpatch.yml up -d

# Limpiar imágenes antiguas
docker image prune
```

### 12.5. Escaneo de Vulnerabilidades

```bash
# Escanear imágenes con Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image nextcloud:29-apache

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image mariadb:11
```

### 12.6. RGPD y Protección de Datos

En entornos educativos con datos de menores:

- **Realizar EIPD** (Evaluación de Impacto de Protección de Datos)
- **Designar DPD** (Delegado de Protección de Datos) si procede
- **Informar a usuarios** mediante políticas de privacidad
- **Obtener consentimientos** cuando sea necesario
- **Limitar accesos** mediante políticas de compartición
- **Realizar auditorías** periódicas de accesos
- **Backup cifrado** en ubicación segura
- **Formación** a profesorado y alumnado sobre uso seguro

### 12.7. Auditoría y Logs

```bash
# Logs de Nextcloud
docker compose exec app tail -f /var/www/html/data/nextcloud.log

# Logs de autenticación
docker compose exec app grep -i "login" /var/www/html/data/nextcloud.log

# Activar log detallado (debugging)
docker compose exec -u www-data app php occ log:manage --level 0
```

---

## 13. Licencia y Uso Educativo

### 13.1. Licencia del Proyecto

Este proyecto se publica como **material educativo** para el proyecto final de ASIR.

**Componentes de terceros**:
- **Nextcloud**: AGPLv3
- **MariaDB**: GPLv2
- **Uptime Kuma**: MIT License
- **Docker**: Apache License 2.0

### 13.2. Uso en Producción

Antes de usar en producción:

1. **Revisión legal**: Consultar implicaciones RGPD
2. **Auditoría de seguridad**: Cambiar todas las credenciales
3. **Configurar HTTPS**: Obligatorio para datos sensibles
4. **Backup automatizado**: Con almacenamiento externo cifrado
5. **Plan de recuperación**: Documentar procedimientos de desastre
6. **Formación**: Al personal que administrará el sistema

### 13.3. Contribuciones

Las contribuciones son bienvenidas mediante:

- **Issues**: Reportar bugs o sugerir mejoras
- **Pull Requests**: Proponer cambios de código
- **Documentación**: Mejorar README o añadir guías

**Repositorio**: https://github.com/JohnFredydev/Intranet-Escolar-con-Nextcloud

### 13.4. Soporte

Este es un proyecto educativo sin soporte oficial. Para consultas:

- **Documentación oficial de Nextcloud**: https://docs.nextcloud.com
- **Foro de Nextcloud**: https://help.nextcloud.com
- **Documentación de Docker**: https://docs.docker.com

---

## Resumen de Comandos Rápidos

```bash
# Instalación remota
bash <(curl -fsSL "https://raw.githubusercontent.com/JohnFredydev/Intranet-Escolar-con-Nextcloud/main/install.sh")

# Instalación clásica
git clone https://github.com/JohnFredydev/Intranet-Escolar-con-Nextcloud.git
cd Intranet-Escolar-con-Nextcloud
bash scripts/init.sh

# Operación
docker compose ps                      # Estado
docker compose logs -f app             # Logs de Nextcloud
docker compose restart                 # Reiniciar
docker compose down                    # Detener

# Backup y restauración
bash scripts/backup.sh                 # Crear backup
bash scripts/restore.sh backups/...    # Restaurar

# Aprovisionamiento offline
bash scripts/provision_images.sh       # Verificar imágenes
bash scripts/export_images.sh          # Exportar para offline
bash scripts/import_images.sh <dir>    # Importar imágenes

# Evidencias
bash scripts/evidencias.sh             # Generar evidencias técnicas

# URLs de acceso
# Nextcloud:    http://localhost:8080
# Uptime Kuma:  http://localhost:3001
```

---

## Autor

**Proyecto Final ASIR**
- **Repositorio**: https://github.com/JohnFredydev/Intranet-Escolar-con-Nextcloud
- **Año**: 2025

---

**Nota**: Este README forma parte de la documentación técnica del proyecto final de ASIR y está diseñado para ser anexado a la memoria del proyecto.
