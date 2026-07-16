#!/usr/bin/env bash
# =============================================================================
# cleanup.sh  (Part 5.5 + Part 6.5)
# Removes everything this project created and returns the machine to the exact
# state it was in before setup.sh was run:
#   - the Drupal container
#   - the database container
#   - the downloaded images
#   - the created volumes
#   - the internal network
#
# The backup files in ./backups are NOT touched (they belong in Git).
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo ">> Removing containers..."
docker rm -f "$DRUPAL_CONTAINER" "$DB_CONTAINER" >/dev/null 2>&1 || true

echo ">> Removing volumes..."
docker volume rm \
  "$DB_VOLUME" \
  "$DRUPAL_VOL_MODULES" "$DRUPAL_VOL_PROFILES" \
  "$DRUPAL_VOL_THEMES" "$DRUPAL_VOL_SITES" >/dev/null 2>&1 || true

echo ">> Removing images..."
docker rmi "$DRUPAL_IMAGE" "$DB_IMAGE" >/dev/null 2>&1 || true

echo ">> Removing network..."
docker network rm "$NETWORK_NAME" >/dev/null 2>&1 || true

echo ">> Cleanup complete. The environment is back to how it was before setup.sh."
