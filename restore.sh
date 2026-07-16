#!/usr/bin/env bash
# =============================================================================
# restore.sh  (Part 5 + Part 6.4)
# Restores a backup created by backup.sh into a running environment:
#   1. loads the SQL dump back into the MySQL container
#   2. restores the Drupal "sites" volume (files / settings / design)
#   3. restarts Drupal so the changes take effect
#
# Run ./setup.sh first (e.g. on a fresh machine) so the network and the
# containers exist, then run ./restore.sh to load the data into them.
#
# Tip (Part 6.4): the backup files can also be fetched from Git before
# restoring, e.g.:   git pull   (they live in the ./backups folder).
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

for c in "$DB_CONTAINER" "$DRUPAL_CONTAINER"; do
  if ! docker ps --format '{{.Names}}' | grep -qx "$c"; then
    echo "ERROR: container '$c' is not running. Run ./setup.sh first, then ./restore.sh" >&2
    exit 1
  fi
done

if [ ! -f "$DB_BACKUP_FILE" ]; then
  echo "ERROR: backup file not found: $DB_BACKUP_FILE" >&2
  echo "       Make sure you cloned/pulled the repository (the backup lives in ./backups)." >&2
  exit 1
fi

echo ">> [1/3] Restoring the MySQL database into container '$DB_CONTAINER'..."
# Import the SQL dump into MySQL
docker exec "$DB_CONTAINER" sh -c \
  'exec mysqladmin -uroot -p"$MYSQL_ROOT_PASSWORD" --force create '"$DB_NAME" \
  >/dev/null 2>&1 || echo "         (database '$DB_NAME' already exists - continuing)"
gunzip < "$DB_BACKUP_FILE" | docker exec -i "$DB_CONTAINER" sh -c \
  'exec mysql -h 127.0.0.1 -uroot -p"$MYSQL_ROOT_PASSWORD" --force'
echo "         Database restored."

# The dump also carries the cache_* tables from the machine the backup was made
# on (cache_container encodes machine-specific paths). Empty them so Drupal
# rebuilds its caches for THIS machine, otherwise pages fail with an error.
echo "         Clearing caches carried over in the dump..."
docker exec "$DB_CONTAINER" sh -c \
  'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -N -e "SELECT CONCAT(\"TRUNCATE TABLE \",table_schema,\".\",table_name,\";\") FROM information_schema.tables WHERE table_schema=\"'"$DB_NAME"'\" AND table_name LIKE \"cache_%\";"' \
  | docker exec -i "$DB_CONTAINER" sh -c 'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD"'

if [ -f "$FILES_BACKUP_FILE" ]; then
  echo ">> [2/3] Restoring the Drupal site files into volume '$DRUPAL_VOL_SITES'..."
  docker exec -i "$DRUPAL_CONTAINER" sh -c 'cd /var/www/html/sites && tar xzf -' < "$FILES_BACKUP_FILE"
  # the restored files must be owned by the webserver user, otherwise Drupal
  # cannot write its compiled templates and pages fail with an error
  docker exec "$DRUPAL_CONTAINER" sh -c 'chown -R www-data:www-data /var/www/html/sites'
  echo "         Site files restored."
else
  echo ">> [2/3] No site-files backup found - skipping (database only)."
fi

echo ">> [3/3] Restarting the Drupal container so the changes take effect..."
docker restart "$DRUPAL_CONTAINER" >/dev/null 2>&1 \
  || echo "         (Drupal container is not running - start it with ./setup.sh)"

echo ">> Restore finished. Open http://localhost:${DRUPAL_HTTP_PORT} and verify the data."
