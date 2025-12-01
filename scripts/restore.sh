#!/usr/bin/env bash
set -Eeuo pipefail

if [ -z "${1:-}" ]; then
  echo "Uso: scripts/restore.sh <carpeta_backup>"
  exit 1
fi

BACKUP_DIR="$1"
DB_SQL="$BACKUP_DIR/db.sql"
FILES_TGZ="$BACKUP_DIR/nextcloud_files.tgz"

if [ ! -f "$DB_SQL" ] || [ ! -f "$FILES_TGZ" ]; then
  echo "No se encuentran $DB_SQL o $FILES_TGZ"
  exit 1
fi

# Cargar .env
if [ -f .env ]; then
  set -a
  export $(grep -v '^#' .env | xargs -d '\n' || true)
  set +a
fi

echo "[*] Deteniendo servicios y subiendo base..."
docker compose down
docker compose up -d app db
sleep 10

echo "[*] Restaurando ficheros Nextcloud..."
docker compose exec -T app bash -c "rm -rf /var/www/html/*"
cat "$FILES_TGZ" | docker compose exec -T app bash -c "tar xzf - -C /"

echo "[*] Restaurando base de datos..."
cat "$DB_SQL" | docker compose exec -T db mysql -u root -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"

echo "[*] Reiniciando todo..."
docker compose up -d
echo "[✓] Restauración completada"
