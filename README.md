# Drupal-on-Docker — Development Tools Final Project

Afeka College of Engineering · Development Tools course · Semester B, 5786
Lecturers: Mr. Tom Cohen, Mr. Lior Rotberg

This repository contains a complete, scripted setup that runs a **Drupal**
content-management site backed by a **MySQL** database, entirely on **Docker**,
together with scripts to back up, restore and clean up the whole environment.

---

## a. Who we are (Team)

| Name (English) | Name (Hebrew) |
| -------------- | ------------- |
| Ori Ohayon     | אורי אוחיון   |
| Avy Kalifa     | אבי כליפה     |
| Ido David      | עידו דוד      |

Site name configured inside Drupal:
**"האתר של אורי אוחיון, אבי כליפה ועידו דוד"**

---

## b. What we were required to do

Build a Drupal blog/CMS site and run it with Docker, storing its content in a
PostgreSQL **or** MySQL database. In detail:

1. Create a Docker **network** so the containers can talk to each other.
2. Run a **database** container (latest image, default port exposed, root
   password `my-secret-pw`).
3. Run a **Drupal** container, exposing host port **8080 → 80** in the container.
4. Configure Drupal through the browser: language, database connection, site
   name (with the team members' names), an admin account
   (`demoadmin` / `secretpass`) and a user account per team member.
5. Add content to the site from the course glossary ("מילון המושגים").
6. **Back up** the database (and the site files/design).
7. **Restore** the backup on another machine and verify it, then **clean up**.
8. Automate all of the above with four scripts: `setup.sh`, `backup.sh`,
   `restore.sh`, `cleanup.sh`.
9. Store everything (scripts, compose file, backups, this README) in a shared
   **Git** repository with all team members added.

---

## c. What we did

* Wrote a shared **`config.sh`** that holds every name, port and credential in
  one place, and is sourced by all four scripts so they stay consistent.
* **`setup.sh`** — creates the `drupal-net` network, pulls the latest `mysql`
  and `drupal` images, starts both containers on that network with the required
  ports, environment variables and persistent volumes, waits for MySQL to be
  ready, and prints the exact values to type into the Drupal installer.
* **`backup.sh`** — dumps the MySQL database to `backups/my-drupal.backup.sql.gz`
  and archives the Drupal `sites` volume (uploaded files / design) to
  `backups/drupal-sites.tar.gz`.
* **`restore.sh`** — loads those two files back into a freshly-started
  environment and restarts Drupal so the change takes effect.
* **`cleanup.sh`** — removes the containers, images, volumes and network,
  leaving the machine exactly as it was before we started.
* Added an optional **`docker-compose.yml`** that describes the same stack
  declaratively, as a convenience alternative to the scripts.
* Chose **MySQL** as the database (its default super-user is `root` and its
  documented example password is exactly the `my-secret-pw` required by the
  assignment).

---

## d. Technologies used

* **Docker** — containers, networks and volumes (Docker Engine / Docker Desktop).
* **Docker Compose** — optional declarative stack definition.
* **MySQL** (latest image) — the database that stores all Drupal content.
* **Drupal** (latest image, PHP/Apache) — the content-management system.
* **Bash** — the four automation scripts.
* **mysqldump / gzip / tar** — database and file backups.
* **Git & GitHub** — shared version control for the team.

---

## Repository structure

```
drupal-devtools-final/
├── config.sh            # shared names, ports and credentials
├── setup.sh             # build the network + containers
├── backup.sh            # back up the database + site files
├── restore.sh           # restore a backup into the environment
├── cleanup.sh           # remove everything
├── docker-compose.yml   # optional alternative to the scripts
├── .gitignore
├── .gitattributes       # forces LF endings so the scripts run on Linux
├── backups/             # backup artifacts live here (committed to Git)
└── README.md            # this file
```

---

## Prerequisites

* A Linux machine (or Docker Desktop) with **Docker** installed and running.
* **Git**, to clone this repository.

---

## e. Step-by-step guide (clone → run → back up → restore → clean up)

### 1. Clone the repository

```bash
git clone <your repository address>
cd drupal-devtools-final
chmod +x *.sh          # make the scripts executable (first time only)
```

### 2. Build the environment

```bash
./setup.sh
```

This creates the network, downloads the images and starts both containers.
When it finishes it prints the values you will need in the next step.

### 3. Configure Drupal in the browser (first-time install)

Open **http://localhost:8080** and follow the Drupal installer:

1. **Choose language** — English (Hebrew is equally acceptable).
2. **Choose profile** — *Standard*.
3. **Database configuration** — enter:
   * Database type: **MySQL, MariaDB, Percona Server, or equivalent**
   * Database name: `drupal`
   * Database username: `drupal`
   * Database password: `drupalpass`
   * Under **Advanced options**:
     * Host: `drupal-mysql`  (the database container's name)
     * Port: `3306`
4. **Configure site**:
   * Site name: `האתר של אורי אוחיון, אבי כליפה ועידו דוד`
   * Administrator account — Username: `demoadmin`, Password: `secretpass`
5. Finish the installer, then log in as `demoadmin`.
6. **People → Add user**: create one account for each team member
   (`ori_ohayon`, `avy_kalifa`, `ido_david`).
7. **Content → Add content**: add the terms from the course glossary
   ("מילון המושגים") on the Moodle site.

> If you restyle the site, remember its files live in the `drupal-sites`
> volume and are captured by `backup.sh` — see below.

### 4. Back up the database and files

```bash
./backup.sh
```

Creates `backups/my-drupal.backup.sql.gz` and `backups/drupal-sites.tar.gz`,
then push them to Git:

```bash
git add backups
git commit -m "Add database and site-files backup"
git push
```

### 5. Restore on another machine

On a second machine, clone the repo and bring up a fresh, empty environment,
then load the backup into it:

```bash
git clone <your repository address>
cd drupal-devtools-final
chmod +x *.sh
./setup.sh        # fresh, empty containers
./restore.sh      # load the database + site files from ./backups
```

Open **http://localhost:8080** and confirm all the content and users are there.

### 6. Clean up (remove everything)

```bash
./cleanup.sh
```

Removes the containers, images, volumes and network. The backup files in
`backups/` stay in Git.

---

## Credentials & settings (quick reference)

| Item                     | Value                          |
| ------------------------ | ------------------------------ |
| Docker network           | `drupal-net`                   |
| Database container       | `drupal-mysql` (`mysql:latest`)|
| Database host / port     | `drupal-mysql` / `3306`        |
| Database name            | `drupal`                       |
| DB app user / password   | `drupal` / `drupalpass`        |
| DB **root** password     | `my-secret-pw`                 |
| Drupal container         | `drupal-app` (`drupal:latest`) |
| Drupal URL               | http://localhost:8080          |
| Drupal admin             | `demoadmin` / `secretpass`     |

---

## f. Additional notes

* **First-run timing:** MySQL takes ~20–30 s to initialise the first time.
  `setup.sh` waits for it automatically before finishing, so the Drupal
  installer will not fail to connect.
* **Why MySQL and not Postgres:** both are allowed; MySQL's native super-user
  is `root` and its documented example password is the exact `my-secret-pw`
  the assignment requires, which keeps the backup/restore commands identical to
  the ones in the brief.
* **Line endings:** `.gitattributes` forces `*.sh` to LF so the scripts run on
  Linux even though they were authored on Windows.
* **Optional Compose path:** instead of `setup.sh` / `cleanup.sh` you can run
  `docker compose up -d` and `docker compose down -v --rmi all`.
* **Manually installing the MySQL client (from the brief):** the backup runs
  `mysqldump` *inside* the container, so no host client is needed; if you want
  one anyway: `sudo apt update && sudo apt install mysql-client-core-8.0`.
