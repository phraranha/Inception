# Developer Documentation - Inception Project

This document describes how to set up, build, and manage the Inception project infrastructure from a developer perspective.

## Table of Contents

1. [Environment Setup](#environment-setup)
2. [Configuration Files](#configuration-files)
3. [Building the Project](#building-the-project)
4. [Container Management](#container-management)
5. [Volume Management](#volume-management)
6. [Network Architecture](#network-architecture)
7. [Service Details](#service-details)
8. [Development Workflow](#development-workflow)
9. [Testing](#testing)
10. [Debugging](#debugging)

---

## Environment Setup

### Prerequisites

Before you begin, ensure you have the following installed:

- **Docker Engine** (version 20.10+)
  ```bash
  docker --version
  ```

- **Docker Compose** (version 2.0+)
  ```bash
  docker compose version
  ```

- **Make**
  ```bash
  make --version
  ```

- **Sudo privileges** (for creating volume directories)

### Installing Docker (if not installed)

#### On Debian/Ubuntu:
```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-v2
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
```

**Note**: Log out and back in for group changes to take effect.

#### Verify Installation:
```bash
docker run hello-world
```

---

## Configuration Files

### Environment Variables (srcs/.env)

Create the `srcs/.env` file with the following structure:

```env
# Database Configuration
DB_NAME='inception_database'
DB_USER='your_database_user'
DB_PW='strong_database_password'
DB_ROOT_PW='strong_root_password'
DB_HOST=mariadb

# Domain Configuration
DOMAIN='paranha.42.fr'
TITLE="Your Site Title"

# WordPress User
WP_USER='wordpress_author'
WP_PW='user_password'
WP_MAIL='user@example.com'

# WordPress Administrator
WP_ADM='site_administrator'
WP_ADM_PW='admin_password'
WP_ADM_MAIL='admin@example.com'
```

**Security Requirements**:
- Administrator username MUST NOT contain: `admin`, `Admin`, `administrator`, or `Administrator`
- Use strong passwords (mix of uppercase, lowercase, numbers, symbols)
- Never commit this file to version control (it's in `.gitignore`)

### Docker Compose (srcs/docker-compose.yml)

The compose file orchestrates three services:

```yaml
services:
  nginx:      # Web server (entry point)
  wordpress:  # CMS + PHP-FPM
  mariadb:    # Database

networks:
  inception-network:  # Bridge network for inter-container communication

volumes:
  inception-db:       # Database persistent storage
  inception-site:     # WordPress files persistent storage
```

**Key Points**:
- `pull_policy: never` - Forces local image builds
- `init: true` - Proper PID 1 handling for signals
- `restart: on-failure:5` - Auto-restart on crashes
- `depends_on` - Container start order

---

## Building the Project

### From Scratch Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd inception
   ```

2. **Create the .env file**:
   ```bash
   cp srcs/.env.example srcs/.env  # If example exists
   # OR
   nano srcs/.env  # Create manually
   ```

3. **Build and launch**:
   ```bash
   make
   ```

### What `make` Does

The Makefile executes the following steps:

1. **Environment Checks**:
   ```bash
   make check_env          # Verifies .env exists
   make environment        # Sets up directories and hosts file
   ```

2. **Directory Creation**:
   ```bash
   make check_data_directory
   make check_database_directory
   make check_wordpress_directory
   ```
   Creates:
   - `/home/paranha/data/`
   - `/home/paranha/data/database-volume/`
   - `/home/paranha/data/wordpress-volume/`

3. **Hosts File Configuration**:
   ```bash
   make check_domain_in_hosts
   ```
   Adds `127.0.0.1 paranha.42.fr` to `/etc/hosts`

4. **Docker Compose**:
   ```bash
   make up  # Executes: docker compose -f ./srcs/docker-compose.yml up -d
   ```

### Build Process Details

#### Image Build Order

1. **MariaDB** (independent)
   - Base: Debian oldstable
   - Installs MariaDB server
   - Runs initialization script
   - Creates database and users

2. **WordPress** (depends on MariaDB)
   - Base: Debian oldstable
   - Installs PHP 7.4, PHP-FPM, WP-CLI
   - Downloads WordPress core
   - Configures database connection
   - Creates admin and regular users

3. **NGINX** (depends on WordPress)
   - Base: Debian oldstable (builder stage)
   - Generates SSL certificates
   - Installs NGINX
   - Configures reverse proxy to WordPress

#### Dockerfile Best Practices Used

- **Multi-stage builds** (NGINX): Separate build and runtime stages
- **Layer optimization**: Combined RUN commands to reduce layers
- **Cleanup**: Removed apt lists and temporary files
- **No latest tags**: Specific Debian version (`oldstable`)
- **Minimal attack surface**: Only necessary packages installed

---

## Container Management

### Makefile Commands

| Command | Description | Docker Equivalent |
|---------|-------------|-------------------|
| `make` | Complete setup and launch | Setup + build + up |
| `make up` | Start containers | `docker compose up -d` |
| `make start` | Start stopped containers | `docker start <names>` |
| `make stop` | Stop containers | `docker stop $(docker ps -aq)` |
| `make clean_all` | Complete cleanup | Multiple commands |
| `make re_all` | Rebuild everything | `clean_all` + `all` |

### Direct Docker Commands

#### Container Operations

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# Start specific container
docker start mariadb

# Stop specific container
docker stop mariadb

# Restart container
docker restart wordpress

# View container details
docker inspect nginx

# Execute command in container
docker exec -it mariadb bash
docker exec wordpress wp --info --allow-root
```

#### Log Management

```bash
# View logs
docker logs nginx
docker logs wordpress
docker logs mariadb

# Follow logs in real-time
docker logs -f wordpress

# Last 100 lines
docker logs --tail 100 nginx

# With timestamps
docker logs -t mariadb
```

#### Resource Usage

```bash
# Container stats
docker stats

# Disk usage
docker system df

# Detailed disk usage
docker system df -v
```

---

## Volume Management

### Volume Structure

```
/home/paranha/data/
├── database-volume/       # MariaDB data
│   ├── mysql/             # System databases
│   ├── inception_database/  # WordPress database
│   └── ...
└── wordpress-volume/      # WordPress installation
    ├── wp-admin/
    ├── wp-content/
    │   ├── themes/
    │   ├── plugins/
    │   └── uploads/       # User-uploaded media
    ├── wp-includes/
    └── wp-config.php      # WordPress configuration
```

### Volume Commands

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect database
docker volume inspect wordpress-site

# View volume data on host
ls -la /home/paranha/data/database-volume/
ls -la /home/paranha/data/wordpress-volume/

# Backup database volume
sudo tar -czf db-backup.tar.gz -C /home/paranha/data/database-volume/ .

# Backup WordPress volume
sudo tar -czf wp-backup.tar.gz -C /home/paranha/data/wordpress-volume/ .

# Remove volumes (WARNING: Deletes data!)
docker volume rm database wordpress-site
```

### Data Persistence

Data persists across container restarts because:
- Volumes use bind mounts to host directories
- `driver_opts` specify exact host paths
- Host directories survive container removal

**Testing Persistence**:
```bash
# Create a post in WordPress
# Stop and remove containers
make stop
docker rm nginx wordpress mariadb

# Restart
make up

# Post should still exist
```

---

## Network Architecture

### Network Configuration

```yaml
networks:
  inception-network:
    name: inception-network
    driver: bridge
```

### Network Details

```bash
# List networks
docker network ls

# Inspect network
docker network inspect inception-network

# View connected containers
docker network inspect inception-network | grep -A 3 "Containers"
```

### Service Communication

Containers communicate using service names as hostnames:

- **NGINX → WordPress**: `wordpress:9000` (PHP-FPM)
- **WordPress → MariaDB**: `mariadb:3306` (MySQL)

**DNS Resolution**: Docker's embedded DNS server resolves service names to container IPs.

### Port Mapping

| Service | Internal Port | External Port | Protocol |
|---------|---------------|---------------|----------|
| NGINX | 443 | 443 | HTTPS |
| WordPress | 9000 | - | FastCGI (internal only) |
| MariaDB | 3306 | - | MySQL (internal only) |

**Security**: Only NGINX port 443 is exposed to the host.

---

## Service Details

### NGINX

**Dockerfile**: `srcs/requirements/nginx/nginx.dockerfile`

**Build Stages**:
1. **Builder**: Generate SSL certificates with OpenSSL
2. **Runtime**: Install NGINX, copy certificates and config

**Key Files**:
- `conf/nginx.conf` - Main NGINX configuration
- `conf/site.conf` - Virtual host configuration
- `tools/script.sh` - SSL certificate generation

**SSL Certificate**:
```bash
# Algorithm: ECDSA with prime256v1 curve
# Validity: 365 days
# Subject: CN=paranha.42.fr
```

**NGINX Configuration Highlights**:
```nginx
# TLS only
ssl_protocols TLSv1.2 TLSv1.3;

# Strong ciphers
ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;

# PHP-FPM proxy
location ~ \.php$ {
    fastcgi_pass wordpress:9000;
}

# Block HTTP
server {
    listen 80;
    return 444;  # Drop connection
}
```

### WordPress

**Dockerfile**: `srcs/requirements/wordpress/wordpress.dockerfile`

**Installed Packages**:
- `php7.4` - PHP runtime
- `php-fpm` - FastCGI Process Manager
- `php-mysql` - MySQL extension for PHP
- `wp-cli` - WordPress command-line tool

**Entrypoint Script**: `tools/entrypoint.sh`

**WordPress Setup Steps**:
1. Download WordPress core
2. Create `wp-config.php` with database credentials
3. Install WordPress (create database tables)
4. Activate theme
5. Create administrator user
6. Create regular user
7. Update default posts/pages
8. Start PHP-FPM

**PHP-FPM Configuration**: `conf/www.conf`
```ini
listen = wordpress:9000
pm = ondemand            # Process manager mode
pm.max_children = 10     # Max processes
user = www-data
group = www-data
clear_env = no           # Pass environment variables
```

### MariaDB

**Dockerfile**: `srcs/requirements/mariadb/mariadb.dockerfile`

**Build Arguments**:
- `DB_NAME` - Database name
- `DB_USER` - Application user
- `DB_PW` - User password
- `DB_ROOT_PW` - Root password

**Initialization Script**: `tools/script.sh`

**Database Setup**:
```sql
-- Change root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PW}';

-- Create database
CREATE DATABASE IF NOT EXISTS ${DB_NAME};

-- Create user
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PW}';

-- Grant privileges
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
```

**MariaDB Configuration**:
```bash
# Entrypoint
mysqld_safe --skip-networking=0 --bind-address=0.0.0.0

# Listen on all interfaces for container network
# Data directory: /var/lib/mysql/
```

---

## Development Workflow

### Making Changes to Services

#### Modifying NGINX Configuration

1. Edit configuration files:
   ```bash
   nano srcs/requirements/nginx/conf/site.conf
   ```

2. Rebuild and restart:
   ```bash
   docker compose -f srcs/docker-compose.yml build nginx
   docker compose -f srcs/docker-compose.yml up -d nginx
   ```

3. Test configuration:
   ```bash
   docker exec nginx nginx -t  # Test config syntax
   docker logs nginx           # Check for errors
   ```

#### Modifying WordPress Setup

1. Edit entrypoint script:
   ```bash
   nano srcs/requirements/wordpress/tools/entrypoint.sh
   ```

2. Remove WordPress container and volume:
   ```bash
   docker stop wordpress
   docker rm wordpress
   sudo rm -rf /home/paranha/data/wordpress-volume/*
   ```

3. Rebuild and restart:
   ```bash
   docker compose -f srcs/docker-compose.yml build wordpress
   docker compose -f srcs/docker-compose.yml up -d wordpress
   ```

#### Modifying Database

1. Edit initialization script:
   ```bash
   nano srcs/requirements/mariadb/tools/script.sh
   ```

2. Complete rebuild required:
   ```bash
   make clean_all
   make
   ```

### Testing Changes Locally

```bash
# 1. Stop current environment
make stop

# 2. Make your changes

# 3. Rebuild specific service
docker compose -f srcs/docker-compose.yml build <service>

# 4. Restart everything
make up

# 5. Check logs
docker compose -f srcs/docker-compose.yml logs -f
```

---

## Testing

### Manual Testing Checklist

#### NGINX Tests

- [ ] HTTPS accessible on port 443
- [ ] HTTP (port 80) is blocked/drops connection
- [ ] SSL certificate is valid (self-signed)
- [ ] TLS 1.2/1.3 only (check with browser dev tools)
- [ ] PHP files are processed (not downloaded)

```bash
# Test HTTPS
curl -k https://paranha.42.fr

# Test HTTP (should fail)
curl http://paranha.42.fr

# Test TLS version
openssl s_client -connect paranha.42.fr:443 -tls1_2
```

#### WordPress Tests

- [ ] WordPress site loads
- [ ] Can log in to admin panel
- [ ] Can create new post
- [ ] Can upload media
- [ ] Regular user account works
- [ ] Database connection functional

```bash
# Test WordPress CLI
docker exec wordpress wp --info --allow-root

# List users
docker exec wordpress wp user list --allow-root

# Check database connection
docker exec wordpress wp db check --allow-root
```

#### MariaDB Tests

- [ ] Database container running
- [ ] WordPress database exists
- [ ] Users have correct permissions
- [ ] Data persists after restart

```bash
# Connect to database
docker exec -it mariadb mysql -uroot -p${DB_ROOT_PW}

# Show databases
SHOW DATABASES;

# Show tables in WordPress database
USE inception_database;
SHOW TABLES;

# Test user permissions
mysql -h mariadb -u${DB_USER} -p${DB_PW} ${DB_NAME} -e "SHOW TABLES;"
```

#### Volume Persistence Tests

```bash
# 1. Create content in WordPress
# 2. Stop containers
make stop

# 3. Start containers
make up

# 4. Verify content still exists
```

### Automated Tests

Create a test script `tests/test.sh`:

```bash
#!/bin/bash

echo "Testing Inception Infrastructure..."

# Test HTTPS
echo "Testing HTTPS..."
if curl -k -s https://paranha.42.fr | grep -q "WordPress"; then
    echo "✓ HTTPS working"
else
    echo "✗ HTTPS failed"
    exit 1
fi

# Test containers running
echo "Testing containers..."
if [ $(docker ps -q | wc -l) -eq 3 ]; then
    echo "✓ All containers running"
else
    echo "✗ Not all containers running"
    exit 1
fi

# Test volumes exist
echo "Testing volumes..."
if docker volume inspect database >/dev/null 2>&1; then
    echo "✓ Database volume exists"
else
    echo "✗ Database volume missing"
    exit 1
fi

echo "All tests passed!"
```

---

## Debugging

### Common Issues and Solutions

#### Container Fails to Start

```bash
# Check logs
docker logs <container-name>

# Check if port is in use
sudo netstat -tlnp | grep :443

# Check container status
docker ps -a

# Inspect container
docker inspect <container-name>
```

#### Network Issues

```bash
# Ping between containers
docker exec nginx ping wordpress
docker exec wordpress ping mariadb

# Check network
docker network inspect inception-network

# Verify DNS resolution
docker exec nginx nslookup wordpress
```

#### Volume Issues

```bash
# Check permissions
ls -la /home/paranha/data/

# Fix permissions
sudo chown -R $USER:$USER /home/paranha/data/
sudo chmod -R 755 /home/paranha/data/

# Check volume mounts
docker inspect mariadb | grep -A 10 Mounts
```

#### Database Connection Issues

```bash
# Check if MariaDB is ready
docker exec mariadb mysqladmin ping -h localhost

# Test connection from WordPress
docker exec wordpress mysql -h mariadb -u${DB_USER} -p${DB_PW} -e "SELECT 1;"

# Check MariaDB logs
docker logs mariadb | grep ERROR
```

### Debugging Tools

#### Access Container Shell

```bash
# Bash shell
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash

# Run commands
docker exec nginx ls -la /etc/nginx/
docker exec wordpress ls -la /var/www/html/
docker exec mariadb ls -la /var/lib/mysql/
```

#### Check Process Status

```bash
# Inside container
docker exec nginx ps aux
docker exec wordpress ps aux | grep php-fpm
docker exec mariadb ps aux | grep mysql
```

#### Network Debugging

```bash
# Install tools in container (temporary)
docker exec -it nginx bash
apt-get update && apt-get install -y curl netcat

# Test WordPress PHP-FPM
nc -zv wordpress 9000

# Test MariaDB
nc -zv mariadb 3306
```

#### File System Debugging

```bash
# Check WordPress files
docker exec wordpress ls -la /var/www/html/

# Check wp-config.php
docker exec wordpress cat /var/www/html/wp-config.php

# Check NGINX config
docker exec nginx cat /etc/nginx/sites-available/site.conf

# Check PHP-FPM config
docker exec wordpress cat /etc/php/7.4/fpm/pool.d/www.conf
```

### Performance Monitoring

```bash
# Real-time container stats
docker stats

# Check container resource usage
docker stats --no-stream

# Check disk usage
docker system df -v
```

---

## Advanced Operations

### Backup and Restore

#### Backup Database

```bash
# Dump database
docker exec mariadb mysqldump -u root -p${DB_ROOT_PW} ${DB_NAME} > backup.sql

# Or using volume
sudo tar -czf database-backup.tar.gz /home/paranha/data/database-volume/
```

#### Restore Database

```bash
# From SQL dump
docker exec -i mariadb mysql -u root -p${DB_ROOT_PW} ${DB_NAME} < backup.sql

# From volume backup
sudo tar -xzf database-backup.tar.gz -C /home/paranha/data/database-volume/
```

### Updating Components

#### Update WordPress Core

```bash
docker exec wordpress wp core update --allow-root
docker exec wordpress wp core update-db --allow-root
```

#### Update Plugins

```bash
docker exec wordpress wp plugin update --all --allow-root
```

### Security Hardening

```bash
# Check for vulnerabilities
docker exec wordpress wp plugin list --allow-root

# Update all components
docker exec wordpress wp core update --allow-root
docker exec wordpress wp plugin update --all --allow-root
docker exec wordpress wp theme update --all --allow-root
```

---

## Project Structure Reference

```
inception/
├── Makefile                              # Build automation
├── README.md                             # Project overview
├── USER_DOC.md                           # User documentation
├── DEV_DOC.md                            # This file
├── .gitignore                            # Git ignore rules
└── srcs/
    ├── .env                              # Environment variables (git-ignored)
    ├── docker-compose.yml                # Container orchestration
    └── requirements/
        ├── mariadb/
        │   ├── mariadb.dockerfile        # MariaDB image
        │   ├── conf/                     # Config files (if any)
        │   └── tools/
        │       └── script.sh             # Database initialization
        ├── nginx/
        │   ├── nginx.dockerfile          # NGINX image
        │   ├── conf/
        │   │   ├── nginx.conf            # Main config
        │   │   └── site.conf             # Virtual host config
        │   └── tools/
        │       └── script.sh             # SSL certificate generation
        └── wordpress/
            ├── wordpress.dockerfile      # WordPress image
            ├── conf/
            │   └── www.conf              # PHP-FPM config
            └── tools/
                └── entrypoint.sh         # WordPress setup script
```

---

## Additional Resources

### Docker Documentation
- [Dockerfile best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Docker networking](https://docs.docker.com/network/)
- [Docker volumes](https://docs.docker.com/storage/volumes/)

### Service-Specific Documentation
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Knowledge Base](https://mariadb.com/kb/en/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [WP-CLI Commands](https://developer.wordpress.org/cli/commands/)

---

**Document Version**: 1.0
**Last Updated**: December 2024
**Maintained by**: paranha
