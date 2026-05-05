# Jambo Support Portal — Znuny 7.3.2 (Docker)

Dockerised Znuny 7.3.2 helpdesk on Ubuntu 22.04 + Apache (mod_perl) with a MariaDB 10.11 backend. Both services are defined in [docker-compose.yml](docker-compose.yml) and can run alongside other Znuny instances on the same host.

## Stack

| Service | Container | Image | Host port |
|---|---|---|---|
| App (Apache + mod_perl + Znuny) | `Support_V7-App-portal` | built from [DockerFile](DockerFile) | `8082 → 80` |
| Database (MariaDB) | `Support_V7-DB-portal` | `mariadb:10.11` | `3311 → 3306` |

Persistent data is bind-mounted from the project directory:
- `./app-data` → `/opt/app/var` (Znuny runtime: sessions, articles, logs, uploads)
- `./db-data` → `/var/lib/mysql` (MariaDB data files)

## Access

After completing the installer, the running instance is reachable at:

| Interface | URL |
|---|---|
| Start page (agent login) | http://localhost:8082/znuny/index.pl |
| Customer portal | http://localhost:8082/znuny/customer.pl |
| Installer (only before setup) | http://localhost:8082/znuny/installer.pl |

### Default admin credentials

| Field | Value |
|---|---|
| User | `root@localhost` |
| Password | `KWQF5UxkPoc9bRo0` |
|Admin User| `Njuguna` | Password: `Njuguna` |

> Change this password on first login (Personal Preferences → Change Password). Treat the value above as a bootstrap secret — do not reuse it in production.

## Prerequisites

- Docker Engine with the Compose v2 plugin (`docker compose ...`)
- The Znuny source archive `znuny-7.3.2.tar.gz` placed at the project root (referenced by [DockerFile](DockerFile))
- Host ports `8082` and `3311` free

## First-time setup

1. Copy the env template and fill in values:
   ```bash
   cp .env.example .env
   ```
   The `DB_PASSWORD` value **must match** the password baked into Znuny's `Kernel/Config.pm` by [DockerFile](DockerFile) (currently `znuny_pass`). If you change one, change both.

2. Build and start:
   ```bash
   docker compose up -d --build
   ```

3. Open the installer at http://localhost:8082/znuny/installer.pl and walk through the wizard. Use these DB connection settings when prompted:

   | Field | Value |
   |---|---|
   | Database host | `db` |
   | Database user | `znuny` |
   | Database password | `znuny_pass` |
   | Database name | `znuny` |

4. After the installer finishes, log in at http://localhost:8082/znuny/index.pl with the credentials above.

## Common operations

```bash
# Tail logs
docker compose logs -f app
docker compose logs -f db

# Stop / start without removing
docker compose stop
docker compose start

# Stop and remove containers (data volumes preserved)
docker compose down

# Rebuild the app image after editing DockerFile
docker compose build --no-cache app && docker compose up -d

# Open a shell inside the app container
docker exec -it Support_V7-App-portal bash

# MariaDB shell
docker exec -it Support_V7-DB-portal mariadb -uznuny -pznuny_pass znuny
```

## Wiping for a clean reinstall

`app-data/` and `db-data/` are owned by container UIDs, so remove them via a throwaway root container rather than `sudo rm`:

```bash
docker compose down
docker run --rm \
  -v "$(pwd)/app-data:/x" -v "$(pwd)/db-data:/y" \
  alpine sh -c 'rm -rf /x/* /x/.[!.]* /y/* /y/.[!.]*'
docker compose up -d --build
```

Then re-run the installer.

## Configuration notes

- **Znuny URL prefix is `/znuny/`** (not `/otrs/`) — set by `ScriptAlias` in `/etc/apache2/conf-available/znuny.conf`, generated from Znuny's `apache2-httpd.include.conf` during the build.
- **MariaDB tuning** for Znuny lives in [50-znuny_config.cnf](50-znuny_config.cnf) (`max_allowed_packet=256M`, `innodb_log_file_size=256M`).
- **`var/` first-run hydration** — the image ships a `/opt/app/var.dist` snapshot; the container's `CMD` copies it into the empty `app-data/` bind mount on first start so Znuny has its expected runtime tree.
- **Coexisting with other Znuny instances** — container names (`Support_V7-App-portal`, `Support_V7-DB-portal`) and host ports (`8082`, `3311`) are deliberately distinct from the sibling project at `~/Documents/Otrs-Docker/v7docker` and the standalone `znuny-app` container on `8081`.

## Files

| Path | Purpose |
|---|---|
| [docker-compose.yml](docker-compose.yml) | Service, network, port, and volume definitions |
| [DockerFile](DockerFile) | App image: Ubuntu 22.04 + Perl deps + Znuny 7.3.2 + Apache |
| [.env.example](.env.example) | Template for required environment variables |
| [50-znuny_config.cnf](50-znuny_config.cnf) | MariaDB overrides mounted into the DB container |
| `znuny-7.3.2.tar.gz` | Znuny source archive (gitignored, copied into the image) |
| `app-data/`, `db-data/` | Persistent runtime data (gitignored) |
