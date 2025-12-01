# Proyecto Nextcloud - Entorno Educativo Automatizado

Despliegue completamente automatizado de Nextcloud con Docker Compose para entornos educativos.

## 🚀 Inicio Rápido (Nuevo Usuario)

Para desplegar el entorno completo en cualquier PC nuevo:

```bash
# 1. Clonar el repositorio
git clone <url-del-repositorio>
cd proyecto-nextcloud

# 2. Configurar variables de entorno (opcional, se copia automáticamente)
cp .env.example .env
nano .env  # Ajusta las credenciales si lo deseas

# 3. Iniciar todo automáticamente
bash scripts/init.sh
```

**¡Eso es todo!** El script `init.sh` se encarga de:

- ✅ Verificar la estructura del proyecto
- ✅ Configurar el archivo `.env` (si no existe)
- ✅ Levantar todos los servicios (Nextcloud, MariaDB, Cron, Uptime Kuma)
- ✅ Esperar a que la base de datos esté saludable
- ✅ Esperar a que Nextcloud esté instalado
- ✅ Configurar el entorno educativo (grupos, usuarios, carpetas compartidas)
- ✅ Aplicar políticas de seguridad y personalización
- ✅ Generar evidencias y logs del sistema

### Acceso a los Servicios

Tras ejecutar `init.sh`, accede a:

- **Nextcloud**: http://localhost:8080
- **Uptime Kuma**: http://localhost:3001

### Credenciales de Acceso

**Nextcloud:**

| Usuario | Contraseña | Rol |
|---------|------------|-----|
| `admin` | `Admin#2025!Cole` | Administrador |
| `profe` | `Profe#2025!Abc` | Profesor |
| `alumno1` | `Alu1#2025!Abc` | Alumno |
| `alumno2` | `Alu2#2025!Abc` | Alumno |

**Uptime Kuma:** Configurar en el primer acceso (se pedirá crear usuario administrador).

---

## 📂 Estructura del Proyecto

```
proyecto-nextcloud/
├── docker-compose.yml              # Configuración base de servicios
├── compose.db.healthpatch.yml      # Healthcheck mejorado para MariaDB
├── .env                            # Variables de entorno (NO incluir en Git)
├── .env.example                    # Plantilla de variables de entorno
├── scripts/
│   ├── init.sh                     # ⭐ Script maestro de inicialización
│   ├── cole_setup.sh               # Configuración del entorno educativo
│   ├── alta_colegio_basica.sh      # Creación de usuarios y estructura
│   ├── alta_usuarios.sh            # Alta individual de usuarios
│   ├── backup.sh                   # Copia de seguridad completa
│   ├── restore.sh                  # Restauración desde backup
│   └── evidencias.sh               # Generación de logs y evidencias
├── backups/                        # Copias de seguridad (generadas por backup.sh)
├── docs/
│   └── logs/                       # Logs del sistema y evidencias
└── kuma/                           # Datos de Uptime Kuma
```

---

## 🛠️ Requisitos

- **Docker** (versión 20.10 o superior)
- **Docker Compose** (versión 2.0 o superior)
- **Sistema operativo**: Linux (Ubuntu/Debian recomendado) o WSL2

---

## 📖 Uso Detallado

### Configuración de Variables de Entorno

El archivo `.env.example` contiene las variables necesarias:

```dotenv
# Base de datos
MYSQL_ROOT_PASSWORD=Root#2025!Fuerte
MYSQL_PASSWORD=App#2025!Fuerte
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud

# Admin Nextcloud
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=Admin#2025!Cole

# Zona horaria
TZ=Europe/Madrid
```

**Importante:** Usa contraseñas seguras en entornos de producción.

### Script Maestro: init.sh

El script `scripts/init.sh` es el punto de entrada principal. Ejecuta todo el proceso de inicialización de forma automatizada e idempotente.

**Características:**

- ✅ Validación de estructura del proyecto
- ✅ Configuración automática del `.env`
- ✅ Despliegue orquestado de servicios
- ✅ Espera inteligente de healthchecks
- ✅ Configuración del entorno educativo
- ✅ Generación automática de evidencias
- ✅ Mensajes informativos con colores
- ✅ Manejo de errores robusto

### Operaciones Manuales (Opcional)

Si prefieres control manual sobre cada paso:

```bash
# Levantar servicios
docker compose -f docker-compose.yml -f compose.db.healthpatch.yml up -d

# Verificar estado
docker compose ps

# Configurar entorno educativo
bash scripts/cole_setup.sh
bash scripts/alta_colegio_basica.sh

# Generar evidencias
bash scripts/evidencias.sh
```

### Copias de Seguridad

**Crear backup:**

```bash
bash scripts/backup.sh
```

Genera un directorio `backups/AAAAMMDD_HHMMSS` con:
- Dump de la base de datos (`db.sql`)
- Archivos de Nextcloud (`nextcloud_files.tgz`)

**Restaurar desde backup:**

```bash
bash scripts/restore.sh backups/AAAAMMDD_HHMMSS
```

### Ver Logs

```bash
# Todos los servicios
docker compose logs -f

# Servicio específico
docker compose logs -f app     # Nextcloud
docker compose logs -f db      # MariaDB
docker compose logs -f kuma    # Uptime Kuma
```

### Detener Servicios

```bash
# Detener contenedores (mantiene datos)
docker compose down

# Detener y eliminar volúmenes (PRECAUCIÓN: elimina datos)
docker compose down -v
```

---

## 🎓 Configuración Educativa

El script `scripts/cole_setup.sh` configura:

### Grupos Creados

**Perfiles:**
- `profesorado`
- `alumnado`
- `direccion`
- `secretaria`
- `tic`
- `orientacion`

**Cursos:**
- `1ESO`, `2ESO`, `3ESO`, `4ESO`
- `1BACH`, `2BACH`
- `FP1`, `FP2`

### Carpetas Compartidas (Group Folders)

| Carpeta | Grupos con Acceso | Permisos |
|---------|-------------------|----------|
| `Claustro - Profesorado` | profesorado | Lectura/Escritura |
| `Secretaría` | secretaria | Lectura/Escritura |
| `Dirección` | direccion (RW), profesorado (R) | Mixtos |
| `Comunicados Alumnado` | profesorado (RW), alumnado (R) | Mixtos |
| `Curso 1ESO - Material` | profesorado (RW), 1ESO (R) | Mixtos |
| *(otros cursos similar)* | ... | ... |

### Políticas de Seguridad

- ✅ Enlaces públicos con expiración obligatoria (30 días)
- ✅ Contraseña obligatoria en enlaces públicos
- ✅ Compartir solo con miembros del grupo
- ✅ Subida pública deshabilitada
- ✅ Cuotas configuradas (2 GB por defecto)

### Personalización (Theming)

- Nombre: "Intranet Colegio San Example"
- Slogan: "Aprender · Compartir · Colaborar"
- Color corporativo: `#0b5ed7` (azul)
- Idioma: Español (ES)

---

## 📊 Monitorización con Uptime Kuma

Uptime Kuma se despliega automáticamente en http://localhost:3001

**Configuración recomendada:**

1. En el primer acceso, crea un usuario administrador
2. Crea un monitor HTTP:
   - **Nombre**: Nextcloud
   - **URL**: `http://app/status.php` (red interna de Docker)
   - **Intervalo**: 60 segundos
   - **Tipo**: HTTP

---

## 🔧 Troubleshooting

### La base de datos no arranca

```bash
# Ver logs
docker compose logs db

# Verificar healthcheck
docker compose ps db
```

La base de datos puede tardar hasta 2 minutos en reportar estado "healthy".

### Nextcloud muestra error de configuración

```bash
# Reiniciar servicios
docker compose down
bash scripts/init.sh
```

### Los scripts fallan

```bash
# Verificar que el contenedor app está corriendo
docker compose ps app

# Probar comando occ directamente
docker compose exec -u www-data app php occ status
```

### Permisos de scripts

Si hay errores de permisos:

```bash
chmod +x scripts/*.sh
```

---

## 📝 Variables de Entorno

Todas las variables configurables en `.env`:

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `MYSQL_ROOT_PASSWORD` | Contraseña root de MariaDB | `Root#2025!Fuerte` |
| `MYSQL_PASSWORD` | Contraseña de aplicación MySQL | `App#2025!Fuerte` |
| `MYSQL_DATABASE` | Nombre de la base de datos | `nextcloud` |
| `MYSQL_USER` | Usuario de la base de datos | `nextcloud` |
| `NEXTCLOUD_ADMIN_USER` | Usuario administrador | `admin` |
| `NEXTCLOUD_ADMIN_PASSWORD` | Contraseña del admin | `Admin#2025!Cole` |
| `TZ` | Zona horaria | `Europe/Madrid` |

---

## 📚 Documentación Adicional

- [Documentación oficial de Nextcloud](https://docs.nextcloud.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)

---

## 🤝 Contribuciones

Este proyecto es de código abierto. Consulta con el administrador del repositorio para más información sobre cómo contribuir.

---

## 📄 Licencia

Consulta con el administrador del repositorio para información sobre la licencia.

---

## ⚡ Resumen de Comandos

```bash
# Despliegue inicial completo
bash scripts/init.sh

# Backup
bash scripts/backup.sh

# Restaurar
bash scripts/restore.sh backups/AAAAMMDD_HHMMSS

# Ver estado
docker compose ps

# Ver logs
docker compose logs -f

# Detener
docker compose down

# Reiniciar
docker compose restart

# Generar evidencias
bash scripts/evidencias.sh
```
