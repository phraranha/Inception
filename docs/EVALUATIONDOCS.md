# Inception - Evaluation Guide

This document guides you through the evaluation process step by step, based on the official evaluation scale. Use this to prepare for defense and understand what evaluators will check.

## Table of Contents

1. [Preliminaries](#preliminaries)
2. [General Instructions](#general-instructions)
3. [Mandatory Part](#mandatory-part)
4. [Evaluation Deep Dive](#evaluation-deep-dive)
5. [Common Evaluator Questions](#common-evaluator-questions)
6. [Red Flags to Avoid](#red-flags-to-avoid)

---

## Preliminaries

### Pre-Evaluation Checks

Before the evaluator arrives, verify:

#### 1. No Credentials in Git Repository

**What evaluator checks**:
```bash
# Check Git history
git log --all --full-history --source -- '*/.env'

# Check current files
git ls-files | grep -E "\.env|password|secret|credential"

# Check if .env is tracked
git check-ignore srcs/.env
```

**Expected result**: `.env` should NOT be in Git

**If credentials found**:
- Evaluation stops immediately
- Grade: 0 (automatic fail)

**Your preparation**:
- Verify `.gitignore` includes `srcs/.env`
- Never commit `.env` file
- Use environment variables for all secrets

#### 2. Defense Requires Presence

**Requirement**: Student must be present for defense

**What this means**:
- You must attend your own defense
- No proxy or remote defenses
- Be on time

#### 3. Git Repository on Workstation

**Requirement**: Clone the Git repository during evaluation

**Evaluator will**:
```bash
cd /tmp
git clone <your-repo-url> inception
cd inception
ls -la
```

**What they're checking**:
- Repository accessible
- Correct project structure
- No extraneous files

---

## General Instructions

### Step-by-Step Checks

#### 1. Initial Cleanup (Critical!)

**Evaluator MUST run before starting**:
```bash
docker stop $(docker ps -qa)
docker rm $(docker ps -qa)
docker rmi -f $(docker images -qa)
docker volume rm $(docker volume ls -q)
docker network rm $(docker network ls -q) 2>/dev/null
```

**Purpose**: Ensure clean environment, no cached containers

**Your role**: Be ready to run this command

#### 2. Check docker-compose.yml

**Evaluator reads and checks**:

```bash
cat srcs/docker-compose.yml
```

**Looking for**:

✅ **MUST HAVE**:
```yaml
networks:
  inception-network:
    # network definition
```

❌ **MUST NOT HAVE**:
```yaml
network: host         # Forbidden
network_mode: host   # Forbidden
```

❌ **MUST NOT HAVE**:
```yaml
links:                # Forbidden
  - mariadb
```

**If forbidden patterns found**:
- Evaluation ends immediately
- No points awarded

#### 3. Check Dockerfiles

**Evaluator checks each Dockerfile**:

❌ **FORBIDDEN in ENTRYPOINT or CMD**:
- `tail -f`
- `bash` (unless running a script)
- `sleep infinity`
- `while true`
- Background execution with `&`

**Examples of violations**:
```dockerfile
# ❌ BAD
ENTRYPOINT ["tail", "-f", "/dev/null"]
CMD ["bash"]
ENTRYPOINT ["sh", "-c", "nginx & bash"]

# ✅ GOOD
CMD ["nginx", "-g", "daemon off;"]
ENTRYPOINT ["mysqld_safe", "--bind-address=0.0.0.0"]
```

**If violations found**:
- Evaluation ends immediately

#### 4. Check Base Images

**Evaluator inspects each Dockerfile**:

```bash
head -1 srcs/requirements/*/Dockerfile
```

**Required**: Each must start with:
- `FROM alpine:X.X.X` (specific version)
- `FROM debian:XXXXX` (specific version)
- Or local image built in project

❌ **FORBIDDEN**:
```dockerfile
FROM alpine          # No version = :latest
FROM nginx:latest    # Pre-made image
FROM wordpress       # DockerHub image
```

**If violations found**:
- Evaluation ends immediately

#### 5. Run the Makefile

```bash
make
```

**Evaluator observes**:
- Build process (should complete without errors)
- No manual intervention needed
- All containers start successfully

**Expected outcome**:
```bash
docker ps
# Should show 3 containers: nginx, wordpress, mariadb
```

---

## Mandatory Part

### Project Overview

**Evaluator asks you to explain**:

1. **How Docker and docker compose work**

   **What to say**:
   - Docker: Containerization platform, packages apps with dependencies
   - Compose: Tool to define multi-container apps with YAML
   - Compose reads docker-compose.yml, builds images, creates containers

2. **Difference between Docker image with/without compose**

   **What to say**:
   - **Without compose**: Manual `docker build`, `docker run`, individual management
   - **With compose**: Define everything in YAML, `docker compose up` starts all
   - Compose manages networks, volumes, dependencies automatically

3. **Benefit of Docker vs VMs**

   **What to say**:
   - **Docker**: Shares host kernel, lightweight (MBs), fast startup (seconds), better performance
   - **VMs**: Full OS, heavy (GBs), slow startup (minutes), hypervisor overhead
   - Docker better for microservices, VMs better for complete OS isolation

4. **Relevance of directory structure**

   **What to say**:
   - `srcs/`: Contains all project configs (requirement)
   - Makefile at root: Build automation
   - `requirements/`: Each service isolated
   - Separates concerns, easy to maintain

**If unable to explain**: May indicate lack of understanding

### Simple Setup

**Evaluator verifies**:

#### 1. NGINX Accessible on Port 443 Only

```bash
# Test HTTPS (should work)
curl -k https://paranha.42.fr

# Test HTTP (should NOT work)
curl http://paranha.42.fr
```

**Expected**:
- HTTPS: WordPress site loads
- HTTP: Connection refused or dropped

#### 2. SSL/TLS Certificate Used

**Evaluator checks in browser**:
- Opens `https://paranha.42.fr`
- Checks certificate (self-signed is OK)
- Verifies TLS 1.2 or 1.3 (in browser dev tools → Security)

#### 3. WordPress Properly Installed

**Evaluator checks**:
- `https://paranha.42.fr` → WordPress site (NOT installation page)
- Site accessible via HTTPS
- NOT accessible via HTTP

**If any fail**: Evaluation ends immediately

### Docker Basics

**Evaluator checks thoroughly**:

#### 1. Dockerfile for Each Service

```bash
ls srcs/requirements/*/Dockerfile
# Must show:
# - srcs/requirements/nginx/Dockerfile
# - srcs/requirements/wordpress/Dockerfile
# - srcs/requirements/mariadb/Dockerfile
```

**Each must be non-empty**

**If missing or empty**: Evaluation ends immediately

#### 2. Student Has Written Own Dockerfiles

**Evaluator asks**:
- "Did you write these Dockerfiles yourself?"
- "Can you explain this line?" (points to random line)

**Purpose**: Ensure no copying of pre-made Dockerfiles

**Prohibited**: Using DockerHub images like:
- `FROM nginx`
- `FROM wordpress`
- `FROM mariadb`

#### 3. Penultimate Stable Version of Alpine or Debian

**Evaluator checks each Dockerfile's first line**:

```bash
grep "^FROM" srcs/requirements/*/Dockerfile
```

**Valid examples**:
- `FROM alpine:3.18`
- `FROM debian:oldstable`
- `FROM debian:bullseye`

❌ **Invalid**:
- `FROM nginx`
- `FROM alpine` (no version)
- `FROM ubuntu:latest`

**If invalid**: Evaluation ends immediately

#### 4. Docker Image Names Match Services

```bash
docker images
```

**Expected**:
```
REPOSITORY    TAG
nginx         latest
wordpress     latest
mariadb       latest
```

**If not matching**: Evaluation ends immediately

#### 5. Makefile Sets Up via docker compose

**Already verified** when running `make`

**No crashes allowed**:
- All containers must start successfully
- No container in restart loop

**If crashes occur**: Evaluation ends

### Docker Network

**Evaluator checks**:

#### 1. Network Defined in docker-compose.yml

```bash
grep -A 3 "^networks:" srcs/docker-compose.yml
```

**Must show network definition**

#### 2. Network Visible

```bash
docker network ls | grep inception-network
```

**Expected**: Network exists

#### 3. Student Explains docker-network

**Evaluator asks**: "Explain what docker-network is"

**What to say**:
- Docker network allows containers to communicate
- Bridge network creates isolated network
- Containers can reach each other via service names
- DNS resolution built-in

**If not correct**: Evaluation ends immediately

### NGINX with SSL/TLS

**Evaluator verifies**:

#### 1. Dockerfile Exists

```bash
cat srcs/requirements/nginx/Dockerfile
```

#### 2. Container Created

```bash
docker compose -f srcs/docker-compose.yml ps
# or
docker ps | grep nginx
```

#### 3. Cannot Connect via HTTP (Port 80)

```bash
curl http://paranha.42.fr
# Should fail or be refused
```

#### 4. Opens in Browser via HTTPS

- Navigate to `https://paranha.42.fr`
- Should show WordPress site
- Self-signed cert warning is OK

#### 5. TLS v1.2 or v1.3 Demonstrated

**How to show**:
- Browser dev tools → Security tab
- Should show TLS 1.2 or 1.3

**Or via command**:
```bash
openssl s_client -connect paranha.42.fr:443 -tls1_2
openssl s_client -connect paranha.42.fr:443 -tls1_3
```

**If any fails**: Evaluation ends immediately

### WordPress with php-fpm and Volume

**Evaluator checks**:

#### 1. Dockerfile Exists

```bash
cat srcs/requirements/wordpress/Dockerfile
```

#### 2. No NGINX in Dockerfile

```bash
grep -i nginx srcs/requirements/wordpress/Dockerfile
# Should return nothing
```

**If NGINX found in WordPress Dockerfile**: May be questioned

#### 3. Container Created

```bash
docker ps | grep wordpress
```

#### 4. Volume Present

```bash
# List volumes
docker volume ls | grep wordpress

# Inspect volume
docker volume inspect wordpress-site

# Check it points to /home/paranha/data/
docker volume inspect wordpress-site | grep /home/paranha/data
```

**Expected path**: `/home/paranha/data/wordpress-volume`

#### 5. Can Add Comment

**Evaluator tests**:
- Logs into WordPress as regular user
- Goes to a post
- Adds a comment

**Expected**: Comment appears successfully

#### 6. Admin Account Check

**Evaluator logs in as admin**:
- Goes to `https://paranha.42.fr/wp-admin`
- Logs in with admin credentials

**Username check**:
```bash
grep WP_ADM srcs/.env
```

❌ **Username CANNOT contain**:
- `admin`
- `Admin`
- `administrator`
- `Administrator`
- `admin-123`
- `admin_login`

**Examples**:
- ✅ OK: `paranha_chief`, `site_manager`, `webmaster`
- ❌ NOT OK: `admin`, `site_admin`, `Administrator`

**If admin username invalid**: Evaluation ends

#### 7. Edit Page from Admin Dashboard

**Evaluator**:
- Opens page editor
- Makes a change
- Publishes
- Verifies change visible on site

**Expected**: Changes reflected immediately

**If any fails**: Evaluation ends immediately

### MariaDB and Volume

**Evaluator checks**:

#### 1. Dockerfile Exists

```bash
cat srcs/requirements/mariadb/Dockerfile
```

#### 2. No NGINX in Dockerfile

```bash
grep -i nginx srcs/requirements/mariadb/Dockerfile
# Should return nothing
```

#### 3. Container Created

```bash
docker ps | grep mariadb
```

#### 4. Volume Exists

```bash
docker volume ls | grep database
docker volume inspect database | grep /home/paranha/data
```

#### 5. Student Can Log Into Database

**Evaluator asks**: "How do I log into the database?"

**You should explain and demonstrate**:
```bash
# Method 1: From host
docker exec -it mariadb mysql -uroot -p${DB_ROOT_PW}

# Method 2: Enter container first
docker exec -it mariadb bash
mysql -uroot -p
```

#### 6. Database is Not Empty

```sql
SHOW DATABASES;
-- Should see 'inception_database' or similar

USE inception_database;
SHOW TABLES;
-- Should see WordPress tables (wp_users, wp_posts, etc.)

SELECT * FROM wp_users;
-- Should see at least 2 users
```

**If any fails**: Evaluation ends immediately

### Persistence Test

**Critical test** - Evaluator will:

```bash
# 1. Note current state (posts, pages, users)

# 2. Reboot the virtual machine
sudo reboot

# 3. After reboot, restart docker compose
cd /path/to/project
make up  # or docker compose up -d

# 4. Verify everything still works:
# - WordPress site loads
# - Previous content still there
# - Database contains same data
# - Can log in with same accounts
```

**What's being tested**:
- Volume persistence across reboots
- Data not stored in containers
- Proper volume configuration

**If data lost**: Evaluation ends immediately

**Your preparation**:
- Test this yourself before defense
- Ensure volumes mounted correctly
- Verify data in `/home/paranha/data/`

---

## Evaluation Deep Dive

### Potential Evaluator Questions and Expected Answers

#### "Why did you choose this directory structure?"

**Good answer**:
> "Following the subject requirements, I put all configuration files in the `srcs` folder. I organized each service in its own subdirectory under `requirements/` to separate concerns. Each service has its Dockerfile and related configuration files together, making the project easier to maintain and understand."

#### "Walk me through what happens when I run 'make'"

**Good answer**:
> "The Makefile first checks that the `.env` file exists, then creates the necessary directories for volumes (`/home/paranha/data/`), adds the domain to `/etc/hosts` if needed, and finally runs `docker compose up -d` which reads the compose file, builds the images from the Dockerfiles, creates the network and volumes, and starts the containers in the correct order."

#### "Why use environment variables instead of hardcoding?"

**Good answer**:
> "For security - hardcoded passwords would be visible in Dockerfiles which are committed to Git. Environment variables keep credentials separate and are stored in `.env` which is git-ignored. This also makes the infrastructure more flexible - I can change passwords without modifying Dockerfiles."

#### "What happens if I stop and remove the WordPress container?"

**Good answer**:
> "The WordPress files and database would remain safe because they're stored in Docker volumes on the host at `/home/paranha/data/`. When I restart the container, it would mount the same volumes and have access to all the existing data. The container itself is stateless."

#### "How does NGINX know where to send PHP requests?"

**Good answer**:
> "In the NGINX configuration, I have `fastcgi_pass wordpress:9000;` which tells NGINX to proxy PHP requests to the WordPress container on port 9000. Docker's built-in DNS resolves `wordpress` to the container's IP address on the `inception-network`."

#### "What would happen if MariaDB crashes?"

**Good answer**:
> "Because I set `restart: on-failure:5` in docker-compose.yml, Docker would automatically try to restart the MariaDB container up to 5 times. The data would still be safe in the volume, so when it restarts successfully, it would have access to all the existing data."

#### "Why PHP-FPM instead of running PHP in NGINX?"

**Good answer**:
> "PHP-FPM (FastCGI Process Manager) allows PHP to run as a separate process from NGINX. This provides better performance through process pooling, better isolation (I can put it in a separate container), and more flexibility in configuration. NGINX doesn't have built-in PHP support like Apache's mod_php, so FastCGI is the standard approach."

#### "Show me where the SSL certificate is generated"

**Good answer**:
```bash
# Show the script
cat srcs/requirements/nginx/tools/script.sh

# Explain the Dockerfile
cat srcs/requirements/nginx/Dockerfile

# Show multi-stage build: builder stage generates cert, runtime stage uses it
```

---

## Common Evaluator Questions

### Technical Questions

**"What is the difference between `COPY` and `ADD` in Dockerfile?"**
> `COPY` simply copies files from host to container. `ADD` can also extract tar archives and fetch URLs. I use `COPY` because it's more explicit and predictable.

**"What does `daemon off;` do in NGINX?"**
> It keeps NGINX running in the foreground. Docker needs the main process to stay in the foreground, otherwise the container exits immediately. Background daemons would cause the container to stop.

**"Why use `--allow-root` with WP-CLI?"**
> WP-CLI by default refuses to run as root user for security. But in our Docker container, we're running as root during setup, so `--allow-root` bypasses this safety check. It's acceptable in a containerized environment.

**"What's the difference between `CMD` and `ENTRYPOINT`?"**
> `ENTRYPOINT` defines the main executable that always runs. `CMD` provides default arguments that can be overridden. Often used together: ENTRYPOINT for the command, CMD for its default options.

**"Why are volumes better than storing data in containers?"**
> Container filesystems are ephemeral - they disappear when the container is removed. Volumes persist independently, survive container removal, are easier to backup, and have better I/O performance.

### Conceptual Questions

**"Explain the benefit of containerization"**
> - **Isolation**: Each service in its own environment
> - **Portability**: Runs identically on any system with Docker
> - **Efficiency**: Shares host kernel, lightweight
> - **Reproducibility**: Infrastructure as code
> - **Scalability**: Easy to replicate and scale

**"What is the attack surface of your infrastructure?"**
> - Only port 443 exposed to outside (NGINX)
> - Internal services (WordPress, MariaDB) not directly accessible
> - TLS encryption for all traffic
> - Minimal: one entry point, all others isolated

**"How would you improve security for production?"**
> - Use Docker Secrets instead of environment variables
> - Implement proper SSL certificates (Let's Encrypt)
> - Add fail2ban for brute-force protection
> - Regular security updates for images
> - Implement network policies for stricter isolation
> - Add monitoring and logging
> - Use non-root users in containers

---

## Red Flags to Avoid

### Automatic Failures

These will end the evaluation immediately with a grade of 0:

1. ❌ **Credentials in Git repository**
2. ❌ **Missing `networks:` in docker-compose.yml**
3. ❌ **Using `network: host` or `links:`**
4. ❌ **Infinite loops in entrypoints** (`tail -f`, `sleep infinity`, `while true`)
5. ❌ **Pre-made Docker images** from DockerHub
6. ❌ **Missing or empty Dockerfiles**
7. ❌ **Using `:latest` tag**
8. ❌ **Admin username contains** `admin` or `administrator`
9. ❌ **HTTP accessible** (port 80 working)
10. ❌ **WordPress installation page** appears instead of configured site

### Common Mistakes

1. **Not testing persistence**: Data disappears after restart
2. **Wrong volume paths**: Not in `/home/login/data/`
3. **Containers not restarting**: No `restart` policy
4. **Services crash**: Build errors or configuration issues
5. **Cannot explain**: Not understanding own code

### How to Avoid Red Flags

✅ **Before defense**:
```bash
# 1. Clean build test
make clean_all && make

# 2. Verify no credentials in Git
git log --all --source -- '*/.env'
git ls-files | grep .env  # Should return nothing

# 3. Check for forbidden patterns
grep -r "tail -f" srcs/
grep -r "sleep infinity" srcs/
grep -r "while true" srcs/
grep "network: host" srcs/docker-compose.yml
grep "links:" srcs/docker-compose.yml

# 4. Verify admin username
grep WP_ADM srcs/.env  # Should NOT contain 'admin'

# 5. Test HTTP blocked
curl http://paranha.42.fr  # Should fail

# 6. Test persistence
make stop && make up
# Verify data still there
```

---

## Evaluation Scoring

### Preliminary Tests
- **Pass**: Can proceed
- **Fail**: Evaluation ends, grade = 0

### General Instructions
- **Pass**: Can proceed to mandatory part
- **Fail**: Evaluation ends, grade = 0

### Mandatory Part
Each section is critical:
- Project overview: Must demonstrate understanding
- Simple setup: Must work correctly
- Docker basics: All requirements must be met
- Network: Must be configured correctly
- NGINX: Must work with TLS only
- WordPress: Must be properly set up
- MariaDB: Must work with volume
- Persistence: Must survive reboot

**Failing any mandatory section** = evaluation ends

### Bonus Part
Only evaluated if **all mandatory parts perfect**

---

## Final Checklist

### Day Before Defense

- [ ] Read through all documentation
- [ ] Test clean build: `make clean_all && make`
- [ ] Test all commands you might need
- [ ] Verify no credentials in Git
- [ ] Check for forbidden patterns
- [ ] Test persistence (reboot VM)
- [ ] Practice explaining each component

### During Defense

- [ ] Stay calm and confident
- [ ] Listen carefully to evaluator's questions
- [ ] Explain clearly and concisely
- [ ] If unsure, check logs/config before answering
- [ ] Be honest about what you know/don't know
- [ ] Show enthusiasm for your work

### If Something Goes Wrong

1. **Don't panic**
2. **Check logs**: `docker logs <container>`
3. **If rebuild needed**: `make clean_all && make`
4. **Stay professional**
5. **Troubleshoot methodically**

---

**Remember**: The evaluator wants to see that you understand what you built and can explain it clearly. Show confidence, knowledge, and problem-solving ability.

**Good luck! 🚀**
