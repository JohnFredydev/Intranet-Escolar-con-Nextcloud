#!/usr/bin/env bash
set -euo pipefail

# === Paths de salida (ajusta si tu repo tiene otra estructura)
OUT_DIR="docs/logs"
mkdir -p "$OUT_DIR"

# === Alias OCC (no interactivo, como www-data en el contenedor app)
OCC='docker compose exec -u www-data -T app php occ'

echo "[*] Generando $OUT_DIR/..."; date

# 1) Ficha del sistema
{
  echo "=== FECHA ==="; date
  echo; echo "=== UNAME ==="; uname -a || true
  echo; echo "=== /etc/os-release ==="; cat /etc/os-release 2>/dev/null || true
  echo; echo "=== Docker version ==="; docker --version || true
  echo; echo "=== Docker Compose version ==="; docker compose version || true
} | tee "$OUT_DIR/sistema.txt" >/dev/null

# 2) Contenedores
docker compose ps | tee "$OUT_DIR/docker_ps.txt" >/dev/null

# 3) Compose "renderizado"
docker compose config > "$OUT_DIR/compose_merged.yml"

# 4) Salud de MariaDB (ping)
docker compose exec -T db sh -lc 'mariadb-admin ping -h 127.0.0.1 -uroot -p"$MYSQL_ROOT_PASSWORD"' \
  | tee "$OUT_DIR/db_ping.txt" >/dev/null

# 5) Logs de la BD (últimas 120 líneas)
docker compose logs --tail=120 db | tee "$OUT_DIR/db_logs.txt" >/dev/null

# 6) Nextcloud - status / apps / usuarios / grupos / groupfolders
$OCC status              | tee "$OUT_DIR/occ_status.txt" >/dev/null
$OCC app:list            | tee "$OUT_DIR/occ_apps.txt" >/dev/null
$OCC user:list           | tee "$OUT_DIR/occ_users.txt" >/dev/null
$OCC group:list          | tee "$OUT_DIR/occ_groups.txt" >/dev/null
$OCC groupfolders:list   | tee "$OUT_DIR/occ_groupfolders.txt" >/dev/null

# 7) Cabeceras HTTP de la app (localhost:8080)
#    Si no accedes por localhost, cambia la URL
{
  echo "=== curl -I http://localhost:8080/ ==="
  curl -I -sS http://localhost:8080/ || true
} | tee "$OUT_DIR/http_headers_app.txt" >/dev/null

echo "[✓] Evidencias generadas en $OUT_DIR/"
