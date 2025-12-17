# Inception - Subject Requirements Implementation Guide

This document explains how each requirement from the subject was implemented in this project.

## Table of Contents

1. [General Guidelines](#general-guidelines)
2. [Mandatory Part Requirements](#mandatory-part-requirements)
3. [Docker Compose Configuration](#docker-compose-configuration)
4. [Service Implementation](#service-implementation)
5. [Volume Implementation](#volume-implementation)
6. [Network Implementation](#network-implementation)
7. [Security Requirements](#security-requirements)
8. [Documentation Requirements](#documentation-requirements)

---

## General Guidelines

### ✅ Virtual Machine Requirement

**Requirement**: Project must be done on a Virtual Machine

**Implementation**:
- Project is designed to run on a Linux VM
- Tested on Debian/Ubuntu systems
- All paths and configurations are VM-compatible

### ✅ srcs Folder

**Requirement**: All configuration files must be in a `srcs` folder

**Implementation**:
```
srcs/
├── .env                    # Environment variables
├── docker-compose.yml      # Docker Compose configuration
└── requirements/           # Service configurations
    ├── mariadb/
    ├── nginx/
    └── wordpress/
```

**Location**: `/home/phra/inception/srcs/`

### ✅ Makefile at Root

**Requirement**: Makefile must be at root and set up entire application using docker-compose.yml

**Implementation**:
```makefile
# File: Makefile (at project root)

all: check_env environment up

up:
    docker compose -f ./srcs/docker-compose.yml up -d
```

**Features**:
- Checks for `.env` file
- Creates volume directories
- Adds domain to `/etc/hosts`
- Builds and starts all containers

---

## Mandatory Part Requirements

### ✅ Three Docker Containers

**Requirement**: Set up NGINX, WordPress + php-fpm, and MariaDB containers

**Implementation**:

#### 1. NGINX Container
- **Dockerfile**: `srcs/requirements/nginx/nginx.dockerfile`
- **Base image**: `debian:oldstable`
- **Purpose**: Web server with TLS
- **Exposed port**: 443 (HTTPS only)

#### 2. WordPress Container
- **Dockerfile**: `srcs/requirements/wordpress/wordpress.dockerfile`
- **Base image**: `debian:oldstable`
- **Purpose**: CMS with PHP-FPM
- **Internal port**: 9000 (FastCGI)

#### 3. MariaDB Container
- **Dockerfile**: `srcs/requirements/mariadb/mariadb.dockerfile`
- **Base image**: `debian:oldstable`
- **Purpose**: Database server
- **Internal port**: 3306

### ✅ Custom Dockerfiles

**Requirement**: Write your own Dockerfiles, one per service

**Implementation**:
- `srcs/requirements/nginx/nginx.dockerfile` - 34 lines
- `srcs/requirements/wordpress/wordpress.dockerfile` - 15 lines
- `srcs/requirements/mariadb/mariadb.dockerfile` - 27 lines

**Key points**:
- All images built from scratch
- No pre-made images from DockerHub
- Alpine/Debian exceptions only

### ✅ Base Images

**Requirement**: Use penultimate stable version of Alpine or Debian

**Implementation**:
```dockerfile
FROM debian:oldstable
```

**Used in**:
- NGINX Dockerfile
- WordPress Dockerfile
- MariaDB Dockerfile

### ✅ Image Names

**Requirement**: Each Docker image must have same name as its corresponding service

**Implementation** (in `docker-compose.yml`):
```yaml
services:
  nginx:
    image: nginx      # Image name matches service name
  wordpress:
    image: wordpress  # Image name matches service name
  mariadb:
    image: mariadb    # Image name matches service name
```

---

## Docker Compose Configuration

### ✅ Docker Compose Setup

**Requirement**: Use docker compose to build images via Makefile

**Implementation**:

**File**: `srcs/docker-compose.yml`

**Makefile command**:
```makefile
up:
    docker compose -f ./srcs/docker-compose.yml up -d
```

### ✅ Container Restart Policy

**Requirement**: Containers must restart in case of crash

**Implementation** (in `docker-compose.yml`):
```yaml
services:
  nginx:
    restart: on-failure:5
  wordpress:
    restart: on-failure:5
  mariadb:
    restart: on-failure:5
```

**Policy**: Restart up to 5 times on failure

### ✅ No Prohibited Patterns

**Requirement**: No tail -f, bash, sleep infinity, while true

**Implementation verified**:
- ✓ NGINX: `CMD [ "nginx", "-g", "daemon off;" ]`
- ✓ WordPress: `ENTRYPOINT ["./script.sh"]` → `php-fpm7.4 -F`
- ✓ MariaDB: `ENTRYPOINT ["mysqld_safe", ...]`

**No infinite loops**: All containers run proper foreground daemons

### ✅ PID 1 Best Practices

**Requirement**: Read about PID 1 and best practices for Dockerfiles

**Implementation**:
```yaml
services:
  nginx:
    init: true      # Proper signal handling
  wordpress:
    init: true
  mariadb:
    init: true
```

**Purpose**: Ensures proper signal forwarding and zombie process reaping

---

## Service Implementation

### ✅ NGINX with TLS

**Requirement**: NGINX with TLSv1.2 or TLSv1.3 only

**Implementation**:

**SSL Certificate Generation** (`srcs/requirements/nginx/tools/script.sh`):
```bash
openssl ecparam -genkey -name prime256v1 -out /tmp/nginx.key
openssl req -new -x509 -key /tmp/nginx.key \
    -out /tmp/nginx.crt -days 365 \
    -subj "/C=BR/ST=Sao Paulo/L=42SP/OU=42SP/CN=paranha.42.fr/..."
```

**NGINX Configuration** (`srcs/requirements/nginx/conf/site.conf`):
```nginx
server {
    listen 443 ssl;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    # ...
}

server {
    listen 80;
    return 444;  # Drop HTTP connections
}
```

**Verification**:
- Port 443: HTTPS only
- Port 80: Blocked
- TLS 1.2/1.3: Enforced in config

### ✅ WordPress Setup

**Requirement**: WordPress + php-fpm (without nginx)

**Implementation**:

**Dockerfile** (`srcs/requirements/wordpress/wordpress.dockerfile`):
```dockerfile
FROM debian:oldstable

RUN apt-get update && \
    apt-get install -y php7.4 php-fpm php-mysql curl mariadb-client && \
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp
```

**Setup Script** (`srcs/requirements/wordpress/tools/entrypoint.sh`):
```bash
wp core download --allow-root
wp config create --dbname=${DB_NAME} --dbuser=${DB_USER} --dbpass=${DB_PW} --allow-root
wp core install --url=${DOMAIN} --title=${TITLE} --admin_user=${WP_ADM} --allow-root
wp user create "${WP_USER}" "${WP_MAIL}" --user_pass=${WP_PW} --allow-root
php-fpm7.4 -F  # Foreground mode
```

**Key points**:
- No NGINX in WordPress container
- PHP-FPM runs on port 9000
- WP-CLI for automated setup

### ✅ WordPress Users

**Requirement**: Two users in WordPress database, one admin (username can't contain admin/Admin or administrator/Administrator)

**Implementation**:

**Environment Variables** (`srcs/.env`):
```env
WP_ADM='paranha_chief'      # Admin user (no 'admin' in name)
WP_ADM_PW='...'
WP_ADM_MAIL='paranha_chief@student.42.fr'

WP_USER='paranha_user'      # Regular user
WP_PW='...'
WP_MAIL='paranha@student.42.fr'
```

**Setup** (`entrypoint.sh`):
```bash
# Create admin
wp core install --admin_user=${WP_ADM} --admin_password=${WP_ADM_PW} --allow-root

# Create regular user
wp user create "${WP_USER}" "${WP_MAIL}" --user_pass=${WP_PW} --role='author' --allow-root
```

**Verification**: Admin username = `paranha_chief` (✓ no forbidden words)

### ✅ MariaDB Setup

**Requirement**: MariaDB container without nginx

**Implementation**:

**Dockerfile** (`srcs/requirements/mariadb/mariadb.dockerfile`):
```dockerfile
FROM debian:oldstable

ARG DB_NAME
ARG DB_USER
ARG DB_PW
ARG DB_ROOT_PW

RUN apt-get update && \
    apt-get install mariadb-server -y
```

**Setup Script** (`srcs/requirements/mariadb/tools/script.sh`):
```bash
service mariadb start

mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PW}';
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PW}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF
```

**Entrypoint**:
```dockerfile
ENTRYPOINT ["mysqld_safe", "--skip-networking=0", "--bind-address=0.0.0.0"]
```

**Key points**:
- No NGINX in container
- Accepts connections from network
- Database and users created on first run

---

## Volume Implementation

### ✅ Two Volumes

**Requirement**:
- Volume for WordPress database
- Volume for WordPress website files

**Implementation** (`srcs/docker-compose.yml`):
```yaml
volumes:
  inception-db:
    name: database
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/paranha/data/database-volume

  inception-site:
    driver: local
    name: wordpress-site
    driver_opts:
      type: none
      o: bind
      device: /home/paranha/data/wordpress-volume
```

**Mount Points**:
```yaml
services:
  mariadb:
    volumes:
      - inception-db:/var/lib/mysql/

  wordpress:
    volumes:
      - inception-site:/var/www/html/

  nginx:
    volumes:
      - inception-site:/var/www/html/
```

### ✅ Volume Location

**Requirement**: Volumes available in /home/login/data folder

**Implementation**:
- Database: `/home/paranha/data/database-volume`
- WordPress: `/home/paranha/data/wordpress-volume`

**Created by Makefile**:
```makefile
VOLUME_WORDPRESS=/home/paranha/data/wordpress-volume
VOLUME_DATABASE=/home/paranha/data/database-volume

check_wordpress_directory:
    @if [ ! -d $(VOLUME_WORDPRESS) ]; then \
        sudo mkdir -p $(VOLUME_WORDPRESS) ;\
        sudo chown -R ${USER}:${USER} $(VOLUME_WORDPRESS) ;\
    fi
```

---

## Network Implementation

### ✅ Docker Network

**Requirement**: docker-network that establishes connection between containers

**Implementation** (`srcs/docker-compose.yml`):
```yaml
networks:
  inception-network:
    name: inception-network
    driver: bridge
```

**Service Connections**:
```yaml
services:
  nginx:
    networks:
      - inception-network
  wordpress:
    networks:
      - inception-network
  mariadb:
    networks:
      - inception-network
```

### ✅ No Prohibited Network Patterns

**Requirement**: No network: host, no --link or links:

**Verification**:
- ✓ No `network: host` in docker-compose.yml
- ✓ No `links:` in docker-compose.yml
- ✓ `networks:` section present
- ✓ No `--link` in Makefile or scripts

---

## Security Requirements

### ✅ No Passwords in Dockerfiles

**Requirement**: No password must be present in Dockerfiles

**Implementation**:
- All passwords in `srcs/.env` file
- Dockerfiles use ARG/ENV variables
- Build-time arguments passed via docker-compose

**Example** (`mariadb.dockerfile`):
```dockerfile
ARG DB_NAME
ARG DB_USER
ARG DB_PW
ARG DB_ROOT_PW
```

### ✅ Environment Variables

**Requirement**: Mandatory to use environment variables and .env file

**Implementation**:

**File**: `srcs/.env` (git-ignored)
```env
DB_NAME='inception_database'
DB_USER='paranha_db'
DB_PW='Str0ng_DB_P@ssw0rd_2024'
# ... more variables
```

**Usage in docker-compose.yml**:
```yaml
services:
  mariadb:
    env_file: .env
    build:
      args:
        - DB_NAME
        - DB_USER
        - DB_PW
        - DB_ROOT_PW
```

### ✅ No Credentials in Git

**Requirement**: No credentials in Git repository (outside of secrets)

**Implementation**:

**.gitignore**:
```
# Environment variables (contains sensitive data)
srcs/.env
.env
```

**Verification**: `.env` file is never committed to repository

### ✅ Latest Tag Prohibited

**Requirement**: The latest tag is prohibited

**Implementation**:
```dockerfile
FROM debian:oldstable    # ✓ Specific version, not 'latest'
```

**All Dockerfiles**: Use `debian:oldstable` instead of `debian:latest`

### ✅ NGINX as Only Entry Point

**Requirement**: NGINX must be the only entrypoint via port 443 only, using TLSv1.2 or TLSv1.3

**Implementation**:

**Port Exposure** (`docker-compose.yml`):
```yaml
services:
  nginx:
    ports:
      - 443:443    # Only NGINX exposes port to host

  wordpress:
    # No ports section - internal only

  mariadb:
    # No ports section - internal only
```

**TLS Configuration** (`site.conf`):
```nginx
listen 443 ssl;
ssl_protocols TLSv1.2 TLSv1.3;
```

---

## Documentation Requirements

### ✅ README.md

**Requirement**: Must include Description, Instructions, Resources sections

**Implementation**: `README.md`

**Sections**:
- ✓ First line: "This project has been created as part of the 42 curriculum by paranha"
- ✓ Description: Project overview and goals
- ✓ Instructions: Installation, setup, and execution
- ✓ Resources: Documentation links and AI usage description
- ✓ Project description: Comparisons (VMs vs Docker, Secrets vs Env Vars, etc.)

### ✅ USER_DOC.md

**Requirement**: User documentation for end users/administrators

**Implementation**: `USER_DOC.md`

**Content**:
- Understanding services
- Starting/stopping project
- Accessing website and admin panel
- Managing credentials
- Checking service status

### ✅ DEV_DOC.md

**Requirement**: Developer documentation

**Implementation**: `DEV_DOC.md`

**Content**:
- Environment setup from scratch
- Build process
- Container/volume management
- Development workflow
- Testing and debugging

---

## Domain Configuration

### ✅ Domain Name

**Requirement**: Domain must be login.42.fr pointing to local IP

**Implementation**:

**Domain**: `paranha.42.fr`

**Hosts File** (added by Makefile):
```
127.0.0.1    paranha.42.fr
```

**Makefile**:
```makefile
check_domain_in_hosts:
    @if ! grep -q "paranha.42.fr" /etc/hosts; then \
        sudo sh -c "echo 127.0.0.1	paranha.42.fr >> /etc/hosts "; \
    fi
```

**NGINX Configuration**:
```nginx
server_name paranha.42.fr;
```

**SSL Certificate**:
```bash
CN=paranha.42.fr
```

---

## Summary Checklist

### General Requirements
- [x] Done on Virtual Machine
- [x] All config files in `srcs` folder
- [x] Makefile at root
- [x] Builds images using docker-compose.yml

### Container Requirements
- [x] NGINX container with TLS
- [x] WordPress + php-fpm container
- [x] MariaDB container
- [x] Each service in dedicated container
- [x] Custom Dockerfiles (one per service)
- [x] Images built from Debian oldstable
- [x] Image names match service names

### Docker Compose
- [x] Containers restart on crash
- [x] No tail -f, bash, sleep infinity, while true
- [x] No network: host or links:
- [x] Network section present

### Services
- [x] NGINX with TLSv1.2/1.3 only
- [x] WordPress with php-fpm (no nginx)
- [x] MariaDB (no nginx)
- [x] Two WordPress users (admin + regular)
- [x] Admin username doesn't contain forbidden words

### Volumes
- [x] WordPress database volume
- [x] WordPress website files volume
- [x] Volumes in /home/login/data

### Network
- [x] Docker network configured
- [x] Containers communicate via network

### Security
- [x] No passwords in Dockerfiles
- [x] Environment variables used
- [x] .env file for configuration
- [x] No credentials in Git
- [x] No 'latest' tag
- [x] NGINX only entrypoint (port 443)

### Documentation
- [x] README.md with all required sections
- [x] USER_DOC.md
- [x] DEV_DOC.md
- [x] Domain configured (login.42.fr)

---

## Testing Verification

To verify all requirements before evaluation:

```bash
# Clean environment
make clean_all

# Fresh build
make

# Verify containers
docker ps  # Should show 3 containers

# Verify images
docker images | grep -E "nginx|wordpress|mariadb"

# Verify network
docker network ls | grep inception-network

# Verify volumes
docker volume ls | grep -E "database|wordpress-site"

# Test HTTPS
curl -k https://paranha.42.fr

# Test HTTP blocked
curl http://paranha.42.fr  # Should fail

# Check Dockerfiles
grep -r "tail -f" srcs/requirements/  # Should find nothing
grep -r "sleep infinity" srcs/requirements/  # Should find nothing
grep -r "FROM.*:latest" srcs/requirements/  # Should find nothing

# Check docker-compose
grep "network: host" srcs/docker-compose.yml  # Should find nothing
grep "links:" srcs/docker-compose.yml  # Should find nothing
grep "networks:" srcs/docker-compose.yml  # Should find it

# Check admin username
grep "WP_ADM" srcs/.env  # Should NOT contain admin/Admin/administrator
```

---

**All mandatory requirements from the subject have been successfully implemented and verified.**
