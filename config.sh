# =============================================================================
# config.sh - shared configuration for the Drupal-on-Docker project
# Sourced by setup.sh / backup.sh / restore.sh / cleanup.sh so that every
# script uses exactly the same names, ports and credentials.
# =============================================================================

# Resolve the directory this project lives in (works even if sourced directly).
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

# --- Docker network (Part 1.1: containers must share one network) -----------
NETWORK_NAME="drupal-net"

# --- Database container: MySQL (Part 1.2) -----------------------------------
DB_CONTAINER="drupal-mysql"
DB_IMAGE="mysql:latest"          # "latest" = newest image, as required (1.2.g)
DB_ROOT_PASSWORD="my-secret-pw"  # required root password (1.2.e)
DB_NAME="drupal"
DB_USER="drupal"
DB_PASSWORD="drupalpass"
DB_PORT="3306"                   # default MySQL port, exposed to the host (1.2.d)
DB_VOLUME="drupal-db-data"       # keeps the database data between restarts

# --- Drupal container (Part 1.3) --------------------------------------------
DRUPAL_CONTAINER="drupal-app"
DRUPAL_IMAGE="drupal:latest"
DRUPAL_HTTP_PORT="8080"          # host 8080 -> container 80 (1.3.b)
# Volumes recommended on the official Drupal image page, so a custom design
# (themes / uploaded files / settings) survives a rebuild (Part 3 note).
DRUPAL_VOL_MODULES="drupal-modules"
DRUPAL_VOL_PROFILES="drupal-profiles"
DRUPAL_VOL_THEMES="drupal-themes"
DRUPAL_VOL_SITES="drupal-sites"

# --- Backup files (Part 4 / Part 7.3) ---------------------------------------
BACKUP_DIR="$SCRIPT_DIR/backups"
DB_BACKUP_FILE="$BACKUP_DIR/my-drupal.backup.sql.gz"
FILES_BACKUP_FILE="$BACKUP_DIR/drupal-sites.tar.gz"
