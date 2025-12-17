# Inception - Defense Study Guide

This guide will help you prepare for your Inception project defense. Study these concepts and be ready to explain them clearly and confidently.

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Questions You Should Be Able to Answer](#questions-you-should-be-able-to-answer)
3. [Common Defense Scenarios](#common-defense-scenarios)
4. [Technical Deep Dives](#technical-deep-dives)
5. [Troubleshooting Knowledge](#troubleshooting-knowledge)
6. [Defense Day Checklist](#defense-day-checklist)

---

## Core Concepts

### Docker Fundamentals

#### What is Docker?
**Answer**: Docker is a containerization platform that packages applications and their dependencies into isolated containers that share the host OS kernel but run in isolated user spaces.

**Key points to mention**:
- Lightweight virtualization
- Container vs Image distinction
- Shares host kernel (unlike VMs)
- Portable and consistent environments

#### Docker vs Virtual Machines

| Aspect | Docker Containers | Virtual Machines |
|--------|------------------|------------------|
| **Virtualization** | OS-level | Hardware-level |
| **Size** | MBs (shares kernel) | GBs (full OS) |
| **Startup** | Seconds | Minutes |
| **Performance** | Near-native | Overhead from hypervisor |
| **Isolation** | Process-level | Complete OS isolation |
| **Use case** | Microservices, apps | Different OS, complete isolation |

**Be ready to explain**: Why you chose Docker for this project (requirements + efficiency)

#### Container Lifecycle

```
docker build   → Create image from Dockerfile
docker run     → Create and start container from image
docker stop    → Stop running container
docker start   → Start stopped container
docker rm      → Remove container
docker rmi     → Remove image
```

**Know**: The difference between container and image
- **Image**: Template, read-only
- **Container**: Running instance of an image

### Docker Compose

#### What is Docker Compose?
**Answer**: Docker Compose is a tool for defining and running multi-container Docker applications using a YAML file (`docker-compose.yml`).

**Why use it?**
- Define multiple services in one file
- Start all services with one command
- Manage networks and volumes easily
- Define dependencies between services

#### Key docker-compose.yml Sections

```yaml
services:      # Define containers
networks:      # Define networks
volumes:       # Define volumes
```

**Be ready to explain**: Each section in your docker-compose.yml file

### Dockerfile

#### What is a Dockerfile?
**Answer**: A Dockerfile is a text file containing instructions to build a Docker image.

#### Common Instructions

| Instruction | Purpose | Example |
|------------|---------|---------|
| `FROM` | Base image | `FROM debian:oldstable` |
| `RUN` | Execute commands | `RUN apt-get update` |
| `COPY` | Copy files | `COPY conf/nginx.conf /etc/nginx/` |
| `CMD` | Default command | `CMD ["nginx", "-g", "daemon off;"]` |
| `ENTRYPOINT` | Main executable | `ENTRYPOINT ["mysqld_safe"]` |
| `EXPOSE` | Document ports | `EXPOSE 443` |
| `ENV` | Set environment vars | `ENV PATH=/usr/local/bin:$PATH` |
| `ARG` | Build-time variables | `ARG DB_NAME` |

**Be ready to explain**: Every line in your Dockerfiles

---

## Questions You Should Be Able to Answer

### Project Overview Questions

**Q1: What does this project do?**
> This project sets up a complete web hosting infrastructure using Docker. It runs a WordPress website with NGINX as a web server and MariaDB as a database, all in isolated containers with persistent storage and encrypted HTTPS connections.

**Q2: Why Docker instead of installing everything directly on the system?**
> Docker provides:
> - Isolation (each service in its own container)
> - Portability (works on any system with Docker)
> - Reproducibility (same environment everywhere)
> - Easy cleanup (containers can be removed without affecting host)
> - Version control (infrastructure as code)

**Q3: What are the three services and what does each do?**
> 1. **NGINX**: Web server that handles HTTPS requests, serves static files, and proxies PHP requests to WordPress
> 2. **WordPress + PHP-FPM**: Content Management System that generates dynamic web pages
> 3. **MariaDB**: Database server that stores all WordPress data (posts, users, settings)

### Docker-Specific Questions

**Q4: How do containers communicate with each other?**
> Through a Docker bridge network (`inception-network`). Docker provides built-in DNS resolution, so containers can reach each other using service names:
> - NGINX connects to `wordpress:9000` (PHP-FPM)
> - WordPress connects to `mariadb:3306` (MySQL)

**Q5: What's the difference between CMD and ENTRYPOINT?**
> - **CMD**: Provides default arguments, can be overridden when running container
> - **ENTRYPOINT**: Defines the main executable, harder to override
> - Often used together: ENTRYPOINT for executable, CMD for default args

**Q6: Why use multi-stage builds? (NGINX)**
> To reduce final image size:
> - **Build stage**: Generate SSL certificates with OpenSSL
> - **Runtime stage**: Only copy the certificates, not OpenSSL
> - Result: Smaller, more secure final image

**Q7: What is PID 1 and why does it matter in containers?**
> PID 1 is the first process in a container (like init in Linux). It's responsible for:
> - Reaping zombie processes
> - Handling signals (SIGTERM, SIGKILL)
> - Proper shutdown
>
> We use `init: true` in docker-compose to ensure proper PID 1 behavior.

### Network Questions

**Q8: Why not use `network: host`?**
> Because:
> - Removes container isolation
> - Container shares host network stack
> - Security risk
> - Against project requirements
>
> Bridge network is better: provides isolation while allowing container communication.

**Q9: Why is only port 443 exposed to the host?**
> Security principle: minimal exposure
> - Only NGINX needs external access
> - WordPress and MariaDB are internal services
> - Reduces attack surface

**Q10: How does NGINX know where WordPress is?**
> Through Docker's DNS and the FastCGI configuration:
> ```nginx
> fastcgi_pass wordpress:9000;
> ```
> Docker resolves `wordpress` to the container's IP on the `inception-network`.

### Volume Questions

**Q11: Why use volumes instead of storing data in containers?**
> Container filesystems are ephemeral (temporary). Volumes provide:
> - Data persistence across container restarts
> - Survival of data when containers are removed
> - Easy backup and migration
> - Better performance for I/O

**Q12: What's the difference between a volume and a bind mount?**
> - **Docker Volume**: Managed by Docker, stored in Docker's directory
> - **Bind Mount**: Directly mounts a host directory
>
> This project uses volumes with bind mount drivers to specify exact host paths (`/home/paranha/data/`).

**Q13: What data is stored in each volume?**
> - **database-volume** (`/var/lib/mysql/`): MariaDB data files, tables, indexes
> - **wordpress-site** (`/var/www/html/`): WordPress PHP files, themes, plugins, uploads

### Security Questions

**Q14: Why not hardcode passwords in Dockerfiles?**
> Because:
> - Dockerfiles are committed to Git (security risk)
> - Images can be inspected with `docker history`
> - Violates security best practices
> - Makes credentials rotation difficult
>
> Solution: Use environment variables from `.env` file (git-ignored)

**Q15: Why use self-signed certificates instead of Let's Encrypt?**
> Because:
> - This is a local development environment
> - Domain (paranha.42.fr) only exists in `/etc/hosts`
> - Let's Encrypt requires publicly accessible domain
> - Self-signed is sufficient for education/testing

**Q16: What's the difference between secrets and environment variables?**
> - **Environment Variables**: Visible in container inspection, logs; simple but less secure
> - **Docker Secrets**: Encrypted at rest and in transit, only in memory; requires Swarm mode
>
> This project uses env vars for simplicity (education), but production should use secrets.

### Service-Specific Questions

**Q17: Why PHP-FPM instead of mod_php?**
> - **mod_php**: Runs inside Apache, ties PHP to web server
> - **PHP-FPM**: Separate FastCGI process manager
>
> Benefits of PHP-FPM:
> - Better performance (process pooling)
> - Can be in separate container (isolation)
> - Works with NGINX (NGINX doesn't support mod_php)
> - More flexibility in configuration

**Q18: What is WP-CLI and why use it?**
> WP-CLI is WordPress Command Line Interface.
>
> Benefits:
> - Automate WordPress installation
> - Create users programmatically
> - No manual setup needed
> - Repeatable and scriptable
>
> Used in entrypoint.sh to fully configure WordPress on first run.

**Q19: Why MariaDB instead of MySQL?**
> - MariaDB is a drop-in replacement for MySQL
> - Better performance
> - More features
> - Fully open-source
> - No licensing concerns
>
> For this project: both work, MariaDB is just the modern choice.

### WordPress Questions

**Q20: Why can't the admin username contain 'admin'?**
> Security best practice:
> - 'admin' is the most common username for brute-force attacks
> - Avoiding it makes attacks harder
> - Part of security hardening
> - Project requirement

**Q21: How are two users created in WordPress?**
> In the entrypoint script:
> ```bash
> # Admin user (created during wp core install)
> wp core install --admin_user=${WP_ADM} --allow-root
>
> # Regular user (created separately)
> wp user create "${WP_USER}" "${WP_MAIL}" --role='author' --allow-root
> ```

---

## Common Defense Scenarios

### Scenario 1: Evaluator Asks to See Running Containers

```bash
docker ps
```

**What to explain**:
- Each container's purpose
- Status should be "Up"
- Only NGINX has port mapping (0.0.0.0:443->443/tcp)

### Scenario 2: Evaluator Asks About Data Persistence

**Demonstration**:
```bash
# 1. Show current WordPress posts
curl -k https://paranha.42.fr

# 2. Stop containers
make stop

# 3. Verify data still exists on host
ls -la /home/paranha/data/wordpress-volume/
ls -la /home/paranha/data/database-volume/

# 4. Restart containers
make up

# 5. Show data persisted
curl -k https://paranha.42.fr  # Same content
```

### Scenario 3: Evaluator Asks to Access a Service

**NGINX**:
```bash
curl -k https://paranha.42.fr
# Or open in browser
```

**WordPress Admin**:
```
https://paranha.42.fr/wp-admin
Login: Check srcs/.env (WP_ADM, WP_ADM_PW)
```

**Database**:
```bash
docker exec -it mariadb mysql -uroot -p${DB_ROOT_PW}
SHOW DATABASES;
USE inception_database;
SHOW TABLES;
SELECT * FROM wp_users;
```

### Scenario 4: Evaluator Asks to Rebuild from Scratch

```bash
# 1. Complete cleanup
make clean_all

# 2. Verify everything is gone
docker ps -a        # No containers
docker images       # No custom images
docker volume ls    # No volumes
ls /home/paranha/data/  # No data directories

# 3. Fresh build
make

# 4. Verify everything works
docker ps           # 3 containers
curl -k https://paranha.42.fr  # WordPress loads
```

### Scenario 5: Evaluator Asks About a Specific Config

**Be prepared to**:
- Open and explain any configuration file
- Show where values come from (.env)
- Explain why each setting is necessary

**Example - NGINX config**:
```nginx
ssl_protocols TLSv1.2 TLSv1.3;  # Why? Security, project requirement
fastcgi_pass wordpress:9000;     # Why 9000? PHP-FPM default port
```

---

## Technical Deep Dives

### How a Request Flows Through the System

```
1. Browser: https://paranha.42.fr
   ↓
2. DNS: /etc/hosts → 127.0.0.1
   ↓
3. NGINX Container (port 443)
   - SSL/TLS handshake
   - Check request (PHP file?)
   ↓
4. WordPress Container (port 9000)
   - PHP-FPM processes request
   - Needs database? →
   ↓
5. MariaDB Container (port 3306)
   - Query database
   - Return results →
   ↓
6. WordPress
   - Generate HTML
   - Return to NGINX →
   ↓
7. NGINX
   - Encrypt with TLS
   - Send to browser
```

**Be ready to trace**: A request for a WordPress page through all layers

### Container Startup Sequence

```
1. make → docker compose up -d
2. Docker reads docker-compose.yml
3. Creates network: inception-network
4. Creates volumes: database, wordpress-site
5. Builds images (if needed):
   - mariadb (no dependencies)
   - wordpress (depends_on: mariadb)
   - nginx (depends_on: wordpress)
6. Starts containers in order:
   - mariadb
   - wordpress (waits for mariadb)
   - nginx (waits for wordpress)
7. Containers run entrypoint/cmd:
   - mariadb: mysqld_safe
   - wordpress: entrypoint.sh (setup + php-fpm)
   - nginx: nginx -g "daemon off;"
```

### What Happens on First Run vs Subsequent Runs

**First Run**:
- MariaDB: Creates database and users
- WordPress: Downloads core, creates config, installs, creates users
- NGINX: Generates SSL certificate

**Subsequent Runs**:
- MariaDB: Uses existing database
- WordPress: Skips installation (checks for wp-config.php)
- NGINX: Uses existing SSL certificate

**How?**
```bash
# WordPress entrypoint.sh
if [ ! -f /var/www/html/wp-config.php ]; then
    # First run - do full setup
else
    # Already configured - just start PHP-FPM
fi
```

---

## Troubleshooting Knowledge

### "Cannot access https://paranha.42.fr"

**Diagnosis**:
```bash
# 1. Check containers running
docker ps

# 2. Check domain in hosts
grep paranha.42.fr /etc/hosts

# 3. Check NGINX logs
docker logs nginx

# 4. Check port 443
sudo netstat -tlnp | grep 443
```

**Solutions**:
- Add domain to /etc/hosts
- Restart NGINX container
- Check firewall

### "WordPress installation page appears"

**Cause**: Database not ready when WordPress started

**Diagnosis**:
```bash
# Check MariaDB logs
docker logs mariadb

# Check WordPress logs
docker logs wordpress

# Test database connection
docker exec wordpress mysql -h mariadb -u${DB_USER} -p${DB_PW} -e "SELECT 1;"
```

**Solution**:
```bash
# Restart WordPress (MariaDB should be ready now)
docker restart wordpress
```

### Container Keeps Restarting

**Diagnosis**:
```bash
# Check logs for errors
docker logs <container>

# Check restart count
docker inspect <container> | grep RestartCount

# Check exit code
docker inspect <container> | grep ExitCode
```

**Common causes**:
- Syntax error in config file
- Missing environment variable
- Port already in use
- Volume permission issues

---

## Defense Day Checklist

### Before the Evaluator Arrives

- [ ] Clean build environment:
  ```bash
  make clean_all
  docker system prune -af
  ```

- [ ] Fresh build to test:
  ```bash
  make
  ```

- [ ] Verify everything works:
  - [ ] `docker ps` shows 3 containers
  - [ ] `https://paranha.42.fr` loads
  - [ ] Can login to WordPress admin
  - [ ] Can access database

- [ ] Review your code:
  - [ ] Know every line in Dockerfiles
  - [ ] Know every section in docker-compose.yml
  - [ ] Know all environment variables

- [ ] Test commands:
  ```bash
  docker logs nginx
  docker logs wordpress
  docker logs mariadb
  docker exec -it mariadb bash
  docker network inspect inception-network
  docker volume inspect database
  ```

### During Defense

- [ ] **Stay calm and confident**
- [ ] **If you don't know**: "Let me check the logs/config" (better than guessing)
- [ ] **Explain your choices**: Why you did things a certain way
- [ ] **Be honest**: If something could be improved, acknowledge it
- [ ] **Show enthusiasm**: This is your project!

### Key Points to Emphasize

1. **All requirements met**:
   - Custom Dockerfiles
   - No pre-made images
   - Proper network and volumes
   - Security (no credentials in Git, TLS only, etc.)

2. **Best practices followed**:
   - Multi-stage builds where appropriate
   - Proper PID 1 handling
   - Foreground daemons (no tail -f hacks)
   - Environment variables for config

3. **Understanding demonstrated**:
   - Can explain every component
   - Can troubleshoot issues
   - Can modify and rebuild

---

## Quick Reference Commands

### Essential Commands

```bash
# Build and start
make

# View containers
docker ps

# View logs
docker logs nginx
docker logs wordpress
docker logs mariadb

# Access containers
docker exec -it nginx bash
docker exec -it mariadb mysql -uroot -p${DB_ROOT_PW}

# Network info
docker network inspect inception-network

# Volume info
docker volume inspect database
ls -la /home/paranha/data/

# Stop everything
make stop

# Complete cleanup
make clean_all

# Rebuild from scratch
make re_all
```

### Inspection Commands

```bash
# Check Dockerfiles for forbidden patterns
grep -r "tail -f" srcs/requirements/
grep -r "sleep infinity" srcs/requirements/
grep -r ":latest" srcs/requirements/

# Check docker-compose for forbidden patterns
grep "network: host" srcs/docker-compose.yml
grep "links:" srcs/docker-compose.yml

# Check .env not in Git
git ls-files | grep .env

# Verify TLS
openssl s_client -connect paranha.42.fr:443 -tls1_2
```

---

## Final Tips

1. **Know your project inside out**: You wrote it, you should understand it completely

2. **Practice explaining**: Talk through your project architecture out loud

3. **Be honest**: If you used external resources or AI, be upfront about it and show you understand the code

4. **Don't panic**: If something doesn't work, calmly troubleshoot using logs

5. **Show passion**: This is system administration - show you're interested in how systems work

6. **Time management**: If evaluation has time limits, prioritize demonstrating core functionality first

7. **Backup plan**: If main system fails, know how to quickly rebuild (`make clean_all && make`)

8. **Document check**: Before defense, make sure all documentation (README, USER_DOC, DEV_DOC) is complete and accurate

---

**Good luck with your defense! You've got this! 🚀**

---

## Bonus: Anticipated Questions and Answers

**"Why this directory structure?"**
> Following the subject requirements and Docker best practices: separating concerns (each service in its own directory), keeping Dockerfiles close to their related configs, and maintaining a clean project root.

**"What would you do differently in production?"**
> - Use Docker Secrets instead of env vars
> - Implement real SSL certificates (Let's Encrypt)
> - Add monitoring (Prometheus, Grafana)
> - Implement backups automation
> - Use Alpine for smaller image sizes
> - Add health checks
> - Implement CI/CD pipeline
> - Use Docker Swarm or Kubernetes for orchestration

**"How would you scale this?"**
> - Horizontal scaling: Multiple WordPress containers behind NGINX
> - Load balancing: NGINX can distribute traffic
> - Database: Read replicas for MariaDB
> - Caching: Add Redis container
> - CDN: For static assets
> - Container orchestration: Kubernetes for auto-scaling

**"What's the most challenging part of this project?"**
> *Choose something you actually struggled with and learned from. Be honest and show growth.*
