# Configuración de Uptime Kuma - Monitorización de Nextcloud

## Objetivo

Configurar Uptime Kuma para monitorizar el estado de Nextcloud mediante el endpoint `/status.php`, evitando errores 400 (Trusted domain) y asegurando monitorización estable.

## Problema Resuelto

**Antes de los cambios**:
- Uptime Kuma generaba errores 400 al intentar acceder a `http://localhost:8080/status.php`
- El error era causado porque `localhost:8080` no estaba en `trusted_domains` de Nextcloud
- Generaba eventos DOWN falsos y alertas innecesarias

**Después de los cambios**:
- El dominio `app` (nombre del servicio Docker) se configura automáticamente en `trusted_domains`
- Uptime Kuma accede internamente a `http://app/status.php` sin salir de la red Docker
- Monitorización estable con código 200 - OK

## Cambios Aplicados

### 1. Configuración Automática de Trusted Domains

**Archivo modificado**: `scripts/cole_setup.sh`

**Cambio**: Se añadió una sección al inicio del script (después de verificar la instalación de Nextcloud) que:
- Obtiene los `trusted_domains` actuales
- Configura `localhost` en el índice 0 (ya suele estar por defecto)
- Añade `app` en el índice 1 (nombre del servicio Docker)
- Verifica y muestra la configuración final

**Código añadido**:
```bash
# ============================================
# CONFIGURAR TRUSTED DOMAINS (CRÍTICO PARA UPTIME KUMA)
# ============================================
log_info "Configurando trusted domains..."
CURRENT_DOMAINS=$(occ config:system:get trusted_domains 2>/dev/null || echo "")

occ config:system:set trusted_domains 0 --value="localhost" 2>/dev/null || true
if ! echo "$CURRENT_DOMAINS" | grep -q "app"; then
  occ config:system:set trusted_domains 1 --value="app" 2>/dev/null || true
  log_success "Dominio 'app' añadido a trusted_domains (acceso interno)"
else
  log_info "Dominio 'app' ya está en trusted_domains"
fi

log_info "Trusted domains configurados:"
occ config:system:get trusted_domains 2>/dev/null || true
```

### 2. Nuevo Script de Verificación

**Archivo creado**: `scripts/setup_kuma.sh`

Script dedicado que:
- Espera a que Uptime Kuma esté accesible (max 120s)
- Verifica el estado de configuración inicial
- Valida que `http://app/status.php` responde con 200 OK desde el contenedor kuma
- Detecta errores comunes (400, 503, 000) y sugiere soluciones
- Muestra instrucciones detalladas para configurar el monitor manualmente

**Uso**:
```bash
bash scripts/setup_kuma.sh
```

### 3. Mejora en init.sh

**Archivo modificado**: `scripts/init.sh`

**Cambio**: Se mejoró la función `configure_uptime_kuma()` para:
- Verificar el endpoint `/status.php` desde el contenedor kuma
- Mostrar el código HTTP devuelto
- Proporcionar diagnóstico automático de errores
- Mostrar instrucciones más detalladas con parámetros específicos

**Instrucciones actualizadas**:
- Monitor Type: HTTP(s)
- Friendly Name: Nextcloud
- URL: `http://app/status.php` (⚠️ importante)
- Heartbeat Interval: 20 seconds
- Retries: 2
- Request Timeout: 8 seconds
- Accepted Status Codes: 200-299
- Method: GET
- Body: (vacío, sin JSON)

## Verificación del Despliegue

### Paso 1: Verificar Trusted Domains

Después de ejecutar el despliegue, verifica que `app` está configurado:

```bash
docker compose exec -u www-data app php occ config:system:get trusted_domains
```

**Salida esperada**:
```
0: localhost
1: app
```

### Paso 2: Verificar Endpoint desde Kuma

Verifica que el contenedor kuma puede acceder al endpoint:

```bash
docker compose exec kuma curl -s -o /dev/null -w "%{http_code}" http://app/status.php
```

**Salida esperada**: `200`

### Paso 3: Ver Respuesta del Endpoint

```bash
docker compose exec kuma curl -s http://app/status.php
```

**Salida esperada** (JSON):
```json
{
  "installed": true,
  "maintenance": false,
  "needsDbUpgrade": false,
  "version": "29.0.x.x",
  "versionstring": "29.0.x",
  "edition": "",
  "productname": "Nextcloud",
  "extendedSupport": false
}
```

### Paso 4: Configurar Monitor en Uptime Kuma

1. Accede a http://localhost:3001
2. Si es la primera vez, crea un usuario administrador
3. Añade un nuevo monitor con los parámetros especificados arriba
4. Guarda y espera al primer heartbeat

**Resultado esperado**: Monitor en estado UP con código 200 - OK

## Troubleshooting

### Error 400 - Bad Request (Trusted Domain)

**Causa**: El dominio desde el que se accede no está en `trusted_domains`.

**Solución**:
```bash
# Verificar trusted_domains actuales
docker compose exec -u www-data app php occ config:system:get trusted_domains

# Añadir 'app' manualmente si falta
docker compose exec -u www-data app php occ config:system:set trusted_domains 1 --value=app

# O re-ejecutar el script completo
bash scripts/cole_setup.sh
```

### Error 503 - Service Unavailable

**Causa**: Nextcloud está en modo mantenimiento.

**Solución**:
```bash
docker compose exec -u www-data app php occ maintenance:mode --off
```

### Error 000 - No Connection

**Causa**: Problema de red entre contenedores.

**Solución**:
```bash
# Verificar conectividad
docker compose exec kuma ping -c 2 app

# Verificar que todos los servicios están up
docker compose ps

# Reiniciar servicios si es necesario
docker compose restart
```

### Monitor Siempre en DOWN

**Causas posibles**:
1. URL incorrecta (usando localhost:8080 en vez de app)
2. Timeout muy corto (< 5s)
3. Nextcloud realmente caído

**Verificaciones**:
```bash
# Ver logs de Nextcloud
docker compose logs app | tail -50

# Ver logs de Uptime Kuma
docker compose logs kuma | tail -50

# Verificar estado de Nextcloud
docker compose exec -u www-data app php occ status
```

## Idempotencia

Los scripts son idempotentes:
- `cole_setup.sh` puede ejecutarse múltiples veces sin duplicar configuraciones
- La verificación `if ! echo "$CURRENT_DOMAINS" | grep -q "app"` previene duplicados
- Los comandos `occ` con `|| true` no fallan si la configuración ya existe

## Especificaciones según Memoria (P7)

Según la documentación del proyecto (docs/memoria.tex), la configuración de Uptime Kuma debe cumplir:

- ✅ Monitorizar `http://app/status.php` (URL interna)
- ✅ Intervalo de verificación: 20 segundos
- ✅ Reintentos: 2
- ✅ Timeout: 8 segundos
- ✅ Códigos aceptados: 200-299
- ✅ Método: GET (sin cuerpo)
- ✅ Sin errores 400 (Trusted domain configurado)
- ✅ Estado estable: UP con 200 - OK

## Resumen de Comandos Útiles

```bash
# Despliegue completo (automático e idempotente)
bash scripts/init.sh

# Solo configuración educativa (incluye trusted_domains)
bash scripts/cole_setup.sh

# Solo verificación de Uptime Kuma
bash scripts/setup_kuma.sh

# Verificar trusted_domains
docker compose exec -u www-data app php occ config:system:get trusted_domains

# Probar endpoint manualmente
docker compose exec kuma curl -v http://app/status.php

# Ver estado de todos los servicios
docker compose ps

# Ver logs en tiempo real
docker compose logs -f app kuma
```

## Notas Finales

- La configuración es completamente automática tras ejecutar `bash scripts/init.sh`
- No se requiere intervención manual para configurar `trusted_domains`
- El único paso manual es crear el usuario de Uptime Kuma y configurar el monitor
- La configuración es estable y no genera eventos DOWN falsos
- El sistema es 100% reproducible y alineado con la memoria del proyecto
