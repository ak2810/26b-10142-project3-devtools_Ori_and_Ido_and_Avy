#!/usr/bin/env bash
# =============================================================================
# backup.sh  (Part 4 + Part 6.3)
# Backs up:
#   1. the MySQL database (gzip-compressed SQL dump)
#   2. the Drupal "sites" volume (uploaded files, settings, custom design)
# and stores both files under ./backups so they can be committed to Git.
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

mkdir -p "$BACKUP_DIR"

for c in "$DB_CONTAINER" "$DRUPAL_CONTAINER"; do
  if ! docker ps --format '{{.Names}}' | grep -qx "$c"; then
    echo "ERROR: container '$c' is not running. Start the environment first with ./setup.sh" >&2
    exit 1
  fi
done

echo ">> [1/2] Backing up the MySQL database from container '$DB_CONTAINER'..."
# Run mysqldump inside the container and compress it
docker exec "$DB_CONTAINER" sh -c \
  'exec mysqldump --all-databases --single-transaction --set-gtid-purged=OFF -uroot -p"$MYSQL_ROOT_PASSWORD"' \
  | gzip > "$DB_BACKUP_FILE"
echo "         -> $DB_BACKUP_FILE"

echo ">> [2/2] Backing up the Drupal site files (volume '$DRUPAL_VOL_SITES')..."
# Backup Drupal site files from the volume
docker exec "$DRUPAL_CONTAINER" sh -c 'cd /var/www/html/sites && tar czf - .' > "$FILES_BACKUP_FILE"
echo "         -> $FILES_BACKUP_FILE"

echo ">> Backup finished. Files created:"
ls -lh "$DB_BACKUP_FILE" "$FILES_BACKUP_FILE"
echo ">> Commit them to Git with:  git add backups && git commit -m 'Add backup' && git push"
