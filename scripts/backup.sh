#!/usr/bin/env bash
set -Eeuo pipefail

if [ -f .env ]; then
  set -a
  export $(grep -v '^#' .env | xargs -d '\n' || true)
  set +a
fi

TS="$(date +%Y%m%d_%H%M%S)"
DEST="backups/$TS"
mkdir -p "$DEST"

echo "[*] Backup BD..."
docker compose exec -T db mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" > "$DEST/db.sql"

echo "[*] Backup ficheros Nextcloud..."
docker compose exec -T app bash -c 'tar czf - /var/www/html' > "$DEST/nextcloud_files.tgz"

echo "[✓] Backup completo en: $DEST"
