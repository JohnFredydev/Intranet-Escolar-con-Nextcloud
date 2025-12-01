# Configuración de Uptime Kuma - Monitorización de Nextcloud

## Despliegue Automático

Tras ejecutar `bash install.sh`, Uptime Kuma queda configurado automáticamente para poder monitorizar Nextcloud sin errores.

## Configuración Automática Aplicada

### 1. Trusted Domains

El script `scripts/cole_setup.sh` configura automáticamente:

```bash
trusted_domains 0: localhost
trusted_domains 1: app
```

Esto permite que Uptime Kuma acceda internamente a `http://app/status.php` (nombre del servicio Docker) sin recibir error 400.

### 2. Verificación del Endpoint

Puedes comprobar que el endpoint funciona correctamente desde dentro del contenedor de Kuma:

```bash
docker compose exec kuma curl -s -o /dev/null -w "%{http_code}" http://app/status.php
```

**Resultado esperado**: `200`

Si obtienes otro código:
- `400`: trusted_domains no está bien configurado
- `503`: Nextcloud está en modo mantenimiento
- `000`: Error de red/contenedor

## Configuración Manual del Monitor (Una Sola Vez)

Uptime Kuma requiere configuración manual inicial en su interfaz web:

### Paso 1: Acceder a Uptime Kuma

1. Abre en el navegador: `http://localhost:3001`
2. Primera vez: crear usuario administrador
   - Usuario: `admin`
   - Contraseña: (elige una segura)

### Paso 2: Crear Monitor para Nextcloud

Clic en **"Add New Monitor"** y configura:

| Campo | Valor |
|-------|-------|
| Monitor Type | HTTP(s) |
| Friendly Name | Nextcloud |
| URL | `http://app/status.php` |
| Heartbeat Interval | 20 seconds |
| Retries | 2 |
| Accepted Status Codes | 200-299 |
| Method | GET |
| Body | (vacío) |

**IMPORTANTE**: Usa `http://app/status.php` (nombre del servicio Docker), NO `http://localhost:8080/status.php`.

### Paso 3: Guardar

Clic en **"Save"**. El monitor debería mostrar estado **UP** inmediatamente.

## Verificaciones Post-Instalación

### 1. Verificar Trusted Domains

```bash
docker compose exec -T -u www-data app php occ config:system:get trusted_domains
```

Debe mostrar:
```
0: localhost
1: app
```

### 2. Verificar Estado de Nextcloud

```bash
docker compose exec -T -u www-data app php occ status
```

Debe mostrar:
```
installed: true
maintenance: false
needsDbUpgrade: false
```

### 3. Verificar Acceso Interno desde Kuma

```bash
docker compose exec kuma curl -s http://app/status.php | jq
```

Debe devolver JSON con información de la instalación.

## Solución de Problemas

### Monitor muestra DOWN con error 400

**Causa**: URL incorrecta o trusted_domains mal configurado.

**Solución**:
1. Verifica que estás usando `http://app/status.php` (no localhost)
2. Ejecuta: `bash scripts/cole_setup.sh` para reconfigurar trusted_domains

### Monitor muestra DOWN con error 503

**Causa**: Nextcloud en modo mantenimiento.

**Solución**:
```bash
docker compose exec -T -u www-data app php occ maintenance:mode --off
```

### No puedo acceder a Uptime Kuma

**Causa**: Contenedor no iniciado o puerto ocupado.

**Solución**:
```bash
docker compose ps kuma
docker compose restart kuma
```

## Comandos Útiles

### Ver logs de Uptime Kuma
```bash
docker compose logs -f kuma
```

### Reiniciar Uptime Kuma
```bash
docker compose restart kuma
```

### Ver todos los servicios
```bash
docker compose ps
```

## Automatización Futura

Actualmente, la creación del usuario admin y del monitor en Uptime Kuma requiere intervención manual a través de su interfaz web, ya que:

1. Uptime Kuma no expone API pública para configuración inicial
2. La seguridad del primer usuario requiere interacción humana
3. Es una configuración que se hace una sola vez

Para instalaciones masivas en entornos de producción, considera:
- Usar Ansible con expect para automatizar la UI
- Montar volumen con base de datos SQLite preconfigurada
- Usar Terraform con provider de Uptime Kuma (experimental)

## Referencias

- [Documentación Uptime Kuma](https://github.com/louislam/uptime-kuma)
- [Nextcloud Status.php API](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/status.html)
- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
