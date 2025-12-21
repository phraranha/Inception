# Inception

*This project has been created as part of the 42 curriculum by paranha.*

## Description

Inception is a Docker infrastructure project that sets up a complete web hosting environment using containerization. The infrastructure consists of NGINX, WordPress, and MariaDB services running in isolated Docker containers with persistent data storage.

### What This Project Does

- **Runs a WordPress website** accessible via HTTPS on `paranha.42.fr`
- **Encrypts all traffic** with TLS 1.2/1.3 (self-signed certificate)
- **Stores data persistently** in Docker volumes that survive container restarts
- **Isolates services** in separate containers communicating through a Docker network
- **Automates deployment** through a Makefile and Docker Compose

### Architecture

```
Browser (HTTPS:443)
       ↓
   [NGINX Container]
       ↓ (FastCGI:9000)
   [WordPress + PHP-FPM Container]
       ↓ (MySQL:3306)
   [MariaDB Container]
       ↓
   [Persistent Volumes]
```

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Linux/Unix system or VM
- Sudo privileges

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd inception
   ```

2. **Verify the .env file exists**:
   ```bash
   ls srcs/.env
   ```

   If missing, create it with proper credentials (see [Configuration](#configuration) below).

3. **Build and launch**:
   ```bash
   make
   ```

4. **Access the website**:
   - Open browser: `https://paranha.42.fr`
   - Accept the self-signed certificate warning
   - You should see the WordPress site

### Management

```bash
make          # Build and start everything
make up       # Start containers
make stop     # Stop containers
make start    # Restart stopped containers
make clean_all # Complete cleanup (deletes all data!)
make re_all   # Rebuild from scratch
```

## Configuration

### Environment Variables (srcs/.env)

The `.env` file contains all sensitive configuration. **This file is git-ignored for security.**

Required variables:
```env
# Database
DB_NAME='inception_database'
DB_USER='paranha_db'
DB_PW='your_strong_password_here'
DB_ROOT_PW='root_password_here'
DB_HOST=mariadb

# Domain
DOMAIN='paranha.42.fr'
TITLE="Inception - paranha"

# WordPress User
WP_USER='paranha_user'
WP_PW='user_password_here'
WP_MAIL='paranha@student.42.fr'

# WordPress Admin (username CANNOT contain 'admin' or 'Administrator')
WP_ADM='paranha_chief'
WP_ADM_PW='admin_password_here'
WP_ADM_MAIL='paranha_chief@student.42.fr'
```

**Security Notes**:
- Use strong passwords (mix of uppercase, lowercase, numbers, symbols)
- Admin username must NOT contain: `admin`, `Admin`, `administrator`, or `Administrator`
- Never commit the `.env` file to Git

## Project Structure

```
.
├── Makefile                     # Build automation
├── README.md                    # This file
├── USER_DOC.md                  # User guide
├── DEV_DOC.md                   # Developer documentation
└── srcs/
    ├── .env                    # Configuration (git-ignored)
    ├── docker-compose.yml      # Container orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile      # Custom MariaDB image
        │   └── tools/          # Setup scripts
        ├── nginx/
        │   ├── Dockerfile      # Custom NGINX image
        │   ├── conf/           # NGINX & SSL config
        │   └── tools/          # SSL certificate generation
        └── wordpress/
            ├── Dockerfile      # Custom WordPress image
            ├── conf/           # PHP-FPM config
            └── tools/          # WordPress setup
```

## Services

### NGINX
- **Purpose**: Web server and reverse proxy
- **Port**: 443 (HTTPS only)
- **Features**: TLS 1.2/1.3, self-signed certificate, FastCGI proxy to WordPress

### WordPress + PHP-FPM
- **Purpose**: Content management system
- **Port**: 9000 (internal FastCGI)
- **Features**: WP-CLI, two users (admin + regular), custom content

### MariaDB
- **Purpose**: Database server
- **Port**: 3306 (internal only)
- **Features**: Persistent storage, dedicated database and users

## Technical Details

### Docker Implementation

**Custom Images**: All Docker images are built from custom Dockerfiles (no pre-made images from DockerHub)

**Base Images**: Debian oldstable (penultimate stable version)

**Network**: Custom bridge network (`inception-network`) for inter-container communication

**Volumes**: Bind-mounted to `/home/paranha/data/` for persistent storage:
- `/home/paranha/data/database-volume` - MariaDB data
- `/home/paranha/data/wordpress-volume` - WordPress files

**Security**:
- Only port 443 exposed to host
- HTTP (port 80) connections are dropped
- TLS 1.2/1.3 with strong cipher suites
- Environment variables for sensitive data
- No hardcoded credentials

### Design Choices

#### Why Docker over VMs?
- **Lightweight**: Containers share the host kernel (less overhead)
- **Fast startup**: Containers start in seconds vs minutes for VMs
- **Efficient**: Better resource utilization
- **Portable**: Easy to move and replicate environments

#### Why Docker Volumes?
- **Persistence**: Data survives container removal
- **Performance**: Better I/O performance than bind mounts on some systems
- **Management**: Docker manages backup and migration
- **Isolation**: Separates data from container lifecycle

#### Why Docker Networks?
- **Isolation**: Containers not exposed to host network
- **DNS Resolution**: Containers communicate via service names
- **Security**: Only necessary ports exposed
- **Flexibility**: Easy to add/remove services

#### Environment Variables vs Secrets
This project uses environment variables (`.env` file) for simplicity. For production:
- **Docker Secrets** would be better (encrypted at rest)
- **Secrets** are never logged or visible in `docker inspect`
- **Secrets** require Docker Swarm mode
- **Environment variables** are easier for development/education

## Common Tasks

### Accessing WordPress Admin Panel

1. Navigate to: `https://paranha.42.fr/wp-admin`
2. Login with credentials from `srcs/.env`:
   - Username: `WP_ADM` value
   - Password: `WP_ADM_PW` value

### Checking Service Status

```bash
# View running containers
docker ps

# View logs
docker logs nginx
docker logs wordpress
docker logs mariadb

# Follow logs in real-time
docker logs -f wordpress

# Check all services
docker compose -f srcs/docker-compose.yml ps
```

### Verifying Data Persistence

```bash
# Check volume directories
ls -la /home/paranha/data/database-volume/
ls -la /home/paranha/data/wordpress-volume/

# Test persistence
# 1. Create a post in WordPress
# 2. Run: make stop
# 3. Run: make up
# 4. Post should still exist
```

### Accessing Container Shells

```bash
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```

### Database Access

```bash
# Using environment variables from .env
docker exec -it mariadb mysql -uroot -p${DB_ROOT_PW}

# Then in MySQL:
SHOW DATABASES;
USE inception_database;
SHOW TABLES;
```

## Troubleshooting

### Cannot access https://paranha.42.fr

**Solution**: Check if domain is in `/etc/hosts`:
```bash
grep paranha.42.fr /etc/hosts
```
If missing, run `make` again or manually add:
```bash
sudo sh -c "echo '127.0.0.1 paranha.42.fr' >> /etc/hosts"
```

### Containers not starting

**Solution**: Check logs:
```bash
docker compose -f srcs/docker-compose.yml logs
```

Common issues:
- Port 443 already in use: `sudo netstat -tlnp | grep 443`
- Missing `.env` file: `ls srcs/.env`
- Permission issues: `sudo chown -R $USER:$USER /home/paranha/data/`

### WordPress shows installation page

**Solution**: Database might not be ready. Wait 30 seconds and refresh, or restart:
```bash
docker restart wordpress
```

### Permission denied on volumes

**Solution**: Fix directory ownership:
```bash
sudo chown -R $USER:$USER /home/paranha/data/
sudo chmod -R 755 /home/paranha/data/
```

## Testing the Infrastructure

### Before Defense/Evaluation

1. **Clean environment**:
   ```bash
   docker stop $(docker ps -qa)
   docker rm $(docker ps -qa)
   docker rmi -f $(docker images -qa)
   docker volume rm $(docker volume ls -q)
   docker network rm $(docker network ls -q) 2>/dev/null
   ```

2. **Fresh build**:
   ```bash
   make
   ```

3. **Verify**:
   - 3 containers running: `docker ps`
   - NGINX accessible: `https://paranha.42.fr`
   - HTTP blocked: `curl http://paranha.42.fr` (should fail)
   - TLS 1.2/1.3 only (check browser dev tools)
   - WordPress admin login works
   - Database contains data
   - Volumes persist after `make stop && make up`

### Key Checkpoints

- **No pre-made images**: All built from custom Dockerfiles
- **No latest tag**: Using `debian:oldstable`
- **No forbidden commands**: No `tail -f`, `sleep infinity`, `bash` in entrypoints
- **No `--link` or `network: host`**: Using Docker network
- **Network present**: `docker network ls` shows `inception-network`
- **NGINX only entrypoint**: Only port 443 exposed
- **Two WordPress users**: Admin + regular user
- **Admin username valid**: Doesn't contain "admin" or "administrator"
- **Volumes in /home/login/data**: Using `/home/paranha/data/`
- **Domain configured**: `paranha.42.fr`
- **No credentials in Git**: `.env` is git-ignored

## Resources

### Documentation
- [Docker Docs](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [NGINX](https://nginx.org/en/docs/)
- [WordPress](https://wordpress.org/support/)
- [MariaDB](https://mariadb.com/kb/en/)

### Best Practices
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Security](https://docs.docker.com/engine/security/)
- [NGINX Security](https://docs.nginx.com/nginx/admin-guide/security-controls/)

### AI Usage in This Project

AI tools assisted with:
- **Documentation structure** and README templates
- **Configuration review** for NGINX, PHP-FPM, and MariaDB
- **Dockerfile optimization** suggestions
- **Bash script debugging** and validation
- **Security analysis** for password policies

All AI suggestions were reviewed, tested, and modified to ensure correctness and compliance with project requirements.

## Additional Documentation

For more detailed information:
- **[USER_DOC.md](USER_DOC.md)**: Complete user guide with step-by-step instructions
- **[DEV_DOC.md](DEV_DOC.md)**: Developer documentation with technical details

## License

Part of the 42 School curriculum.

## Author

**paranha** - 42 Student

---

**Pro tip for evaluation**: Run `make clean_all && make` before your defense to demonstrate a fresh build from scratch. This shows that everything works correctly without cached data.
