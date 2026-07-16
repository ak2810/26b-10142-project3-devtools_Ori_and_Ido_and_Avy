#!/usr/bin/env bash
# =============================================================================
# setup.sh  (Part 6.2)
# Builds the whole Docker infrastructure:
#   a. creates an internal network so the containers can find each other
#   b. downloads and runs the MySQL container and the Drupal container
#   c. prints friendly messages telling the user what to do next
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo ">> [1/4] Creating the internal Docker network '$NETWORK_NAME'..."
if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
  echo "         Network already exists - skipping."
else
  docker network create "$NETWORK_NAME"
  echo "         Network created."
fi

echo ">> [2/4] Pulling the latest images from Docker Hub..."
docker pull "$DB_IMAGE"
docker pull "$DRUPAL_IMAGE"

echo ">> [3/4] Starting the MySQL database container '$DB_CONTAINER'..."
if docker ps -a --format '{{.Names}}' | grep -qx "$DB_CONTAINER"; then
  echo "         Container already exists - (re)starting it."
  docker start "$DB_CONTAINER" >/dev/null
else
  docker run -d \
    --name "$DB_CONTAINER" \
    --network "$NETWORK_NAME" \
    -e MYSQL_ROOT_PASSWORD="$DB_ROOT_PASSWORD" \
    -e MYSQL_DATABASE="$DB_NAME" \
    -e MYSQL_USER="$DB_USER" \
    -e MYSQL_PASSWORD="$DB_PASSWORD" \
    -p "${DB_PORT}:3306" \
    -v "${DB_VOLUME}:/var/lib/mysql" \
    "$DB_IMAGE" >/dev/null
fi

# MySQL needs a few seconds to initialise the first time before Drupal can
# connect to it. Wait until it answers, so the site install does not fail.
echo "         Waiting for MySQL to accept connections..."
for _ in $(seq 1 30); do
  if docker exec "$DB_CONTAINER" mysqladmin ping -h 127.0.0.1 \
        -uroot -p"$DB_ROOT_PASSWORD" --silent >/dev/null 2>&1; then
    echo "         MySQL is ready."
    break
  fi
  printf '.'
  sleep 2
done

echo ">> [4/4] Starting the Drupal container '$DRUPAL_CONTAINER'..."
if docker ps -a --format '{{.Names}}' | grep -qx "$DRUPAL_CONTAINER"; then
  echo "         Container already exists - (re)starting it."
  docker start "$DRUPAL_CONTAINER" >/dev/null
else
  docker run -d \
    --name "$DRUPAL_CONTAINER" \
    --network "$NETWORK_NAME" \
    -p "${DRUPAL_HTTP_PORT}:80" \
    -v "${DRUPAL_VOL_MODULES}:/var/www/html/modules" \
    -v "${DRUPAL_VOL_PROFILES}:/var/www/html/profiles" \
    -v "${DRUPAL_VOL_THEMES}:/var/www/html/themes" \
    -v "${DRUPAL_VOL_SITES}:/var/www/html/sites" \
    "$DRUPAL_IMAGE" >/dev/null
fi

cat <<EOF

==================================================================
 The environment is up and running.

 Open Drupal in your browser:   http://localhost:${DRUPAL_HTTP_PORT}

 On the "Database configuration" step of the Drupal installer enter:
   Database type : MySQL, MariaDB, Percona Server, or equivalent
   Database name : ${DB_NAME}
   Database user : ${DB_USER}
   Password      : ${DB_PASSWORD}
   Advanced options -> Host : ${DB_CONTAINER}
   Advanced options -> Port : 3306

 Create the site administrator account with:
   Username : demoadmin
   Password : secretpass
==================================================================
EOF
