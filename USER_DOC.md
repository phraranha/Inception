# User Documentation - Inception Project

This document explains how to use the Inception infrastructure as an end user or system administrator.

## Table of Contents

1. [Understanding the Services](#understanding-the-services)
2. [Starting the Project](#starting-the-project)
3. [Stopping the Project](#stopping-the-project)
4. [Accessing the Website](#accessing-the-website)
5. [Accessing the Administration Panel](#accessing-the-administration-panel)
6. [Managing Credentials](#managing-credentials)
7. [Checking Service Status](#checking-service-status)
8. [Common User Tasks](#common-user-tasks)
9. [Troubleshooting](#troubleshooting)

---

## Understanding the Services

The Inception project provides a complete web hosting infrastructure with three main services:

### 1. NGINX Web Server
- **Purpose**: Serves as the entry point for all web traffic
- **Features**:
  - HTTPS encryption (port 443)
  - SSL/TLS certificate management
  - Reverse proxy to WordPress
- **Security**: Blocks HTTP (port 80) traffic, enforces HTTPS only

### 2. WordPress CMS
- **Purpose**: Content Management System for creating and managing website content
- **Features**:
  - Web-based interface for content creation
  - User management
  - Theme and plugin support
  - Blog and page publishing
- **Access**: Through NGINX at https://paranha.42.fr

### 3. MariaDB Database
- **Purpose**: Stores all WordPress data (posts, users, settings)
- **Features**:
  - Persistent data storage
  - User access control
  - SQL database management
- **Access**: Internal only (not directly accessible from outside)

---

## Starting the Project

### First Time Setup

1. **Open a terminal** in the project directory

2. **Run the initialization command**:
   ```bash
   make
   ```

   This will:
   - ✓ Check that `.env` file exists
   - ✓ Create data directories for persistent storage
   - ✓ Add `paranha.42.fr` to your hosts file
   - ✓ Build all Docker images
   - ✓ Start all containers

3. **Wait for completion** (first build takes 2-5 minutes)

4. **Verify services are running**:
   ```bash
   docker ps
   ```

   You should see three containers: `nginx`, `wordpress`, and `mariadb`

### Subsequent Starts

If the infrastructure has already been built:

```bash
make up
```

Or to start individual containers:

```bash
make start
```

---

## Stopping the Project

### Graceful Shutdown

To stop all running containers:

```bash
make stop
```

This stops the containers but preserves all data.

### What Gets Preserved

When you stop the project:
- ✓ All website content (posts, pages)
- ✓ All user accounts
- ✓ All WordPress settings and plugins
- ✓ All database data
- ✓ All uploaded media files

---

## Accessing the Website

### Website URL

The website is accessible at:

```
https://paranha.42.fr
```

### First Access

1. **Open your browser**

2. **Navigate to** `https://paranha.42.fr`

3. **Security Warning**: You'll see a warning about the SSL certificate
   - This is normal (self-signed certificate)
   - Click **"Advanced"** or **"Show Details"**
   - Click **"Proceed to paranha.42.fr"** or **"Accept the Risk"**

4. **You should now see the WordPress site**

### Certificate Warning Explanation

The security warning appears because:
- The SSL certificate is self-signed (not from a trusted Certificate Authority)
- This is acceptable for local development/education
- In production, you would use a certificate from Let's Encrypt or another CA

---

## Accessing the Administration Panel

### Admin Login Page

1. **Navigate to the admin URL**:
   ```
   https://paranha.42.fr/wp-admin
   ```

2. **Or click** "Log In" from the website footer

### Admin Credentials

The administrator credentials are stored in the `srcs/.env` file:

- **Username**: Value of `WP_ADM` variable
- **Password**: Value of `WP_ADM_PW` variable

**Default setup**:
- Username: `paranha_chief`
- Password: Check `srcs/.env` file

### What You Can Do as Admin

From the WordPress admin panel you can:
- ✎ Create and edit posts and pages
- 👥 Manage users
- 🎨 Change themes
- 🔌 Install/activate plugins
- ⚙️ Configure site settings
- 📊 View analytics
- 💬 Moderate comments

---

## Managing Credentials

### Location of Credentials

All sensitive credentials are stored in:
```
srcs/.env
```

### Available Credentials

#### Database Root User
```env
Username: root
Password: DB_ROOT_PW value from .env
```

#### Database Application User
```env
Username: DB_USER value from .env
Password: DB_PW value from .env
Database: DB_NAME value from .env
```

#### WordPress Administrator
```env
Username: WP_ADM value from .env
Password: WP_ADM_PW value from .env
Email: WP_ADM_MAIL value from .env
```

#### WordPress Regular User
```env
Username: WP_USER value from .env
Password: WP_PW value from .env
Email: WP_MAIL value from .env
```

### Viewing Your Credentials

To view your current credentials:

```bash
cat srcs/.env
```

### Changing Passwords

**⚠️ Warning**: Changing passwords requires rebuilding the infrastructure

1. **Stop all containers**:
   ```bash
   make stop
   ```

2. **Edit the `.env` file**:
   ```bash
   nano srcs/.env
   # or use your preferred editor
   ```

3. **Clean and rebuild everything**:
   ```bash
   make clean_all
   make
   ```

**Note**: This will reset the database and all content!

### Security Best Practices

- 🔒 Never share the `.env` file
- 🔒 Use strong, unique passwords
- 🔒 Don't commit `.env` to version control (it's git-ignored)
- 🔒 Change default passwords for production use

---

## Checking Service Status

### Check Running Containers

```bash
docker ps
```

**Expected output**:
```
CONTAINER ID   IMAGE       STATUS        PORTS                  NAMES
xxxxxxxxxxxx   nginx       Up X minutes  0.0.0.0:443->443/tcp   nginx
xxxxxxxxxxxx   wordpress   Up X minutes  9000/tcp               wordpress
xxxxxxxxxxxx   mariadb     Up X minutes  3306/tcp               mariadb
```

### Check Container Logs

#### All containers:
```bash
docker compose -f srcs/docker-compose.yml logs
```

#### Specific container:
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

#### Follow logs in real-time:
```bash
docker logs -f wordpress
```

### Check Network Connectivity

```bash
docker network ls
```

You should see `inception-network` in the list.

### Check Volumes

```bash
docker volume ls
```

You should see:
- `database` (MariaDB data)
- `wordpress-site` (WordPress files)

### Verify Data Persistence

Check host directories:
```bash
ls -la /home/paranha/data/
```

You should see:
- `database-volume/` - Database files
- `wordpress-volume/` - WordPress installation files

---

## Common User Tasks

### Creating a New Blog Post

1. Log into admin panel at `https://paranha.42.fr/wp-admin`
2. Click **"Posts"** → **"Add New"**
3. Enter your post title and content
4. Click **"Publish"**

### Creating a New Page

1. Log into admin panel
2. Click **"Pages"** → **"Add New"**
3. Enter page title and content
4. Click **"Publish"**

### Uploading Images/Media

1. Log into admin panel
2. Click **"Media"** → **"Add New"**
3. Drag and drop files or click **"Select Files"**
4. Files are uploaded and available for use

### Creating a New User

1. Log into admin panel as administrator
2. Click **"Users"** → **"Add New"**
3. Fill in user details:
   - Username
   - Email
   - Password
   - Role (Subscriber, Contributor, Author, Editor, or Administrator)
4. Click **"Add New User"**

### Changing Site Theme

1. Log into admin panel
2. Click **"Appearance"** → **"Themes"**
3. Click **"Add New"** to browse themes
4. Click **"Activate"** on your chosen theme

### Installing Plugins

1. Log into admin panel
2. Click **"Plugins"** → **"Add New"**
3. Search for desired plugin
4. Click **"Install Now"**
5. Click **"Activate"**

---

## Troubleshooting

### Cannot Access https://paranha.42.fr

**Problem**: Browser shows "Site can't be reached"

**Solutions**:
1. Check if services are running: `docker ps`
2. Check if domain is in hosts file: `grep paranha.42.fr /etc/hosts`
3. If not, run: `make` (it will add it automatically)
4. Try accessing by IP: `https://127.0.0.1` (you'll see certificate name mismatch, but site should load)

### Services Not Starting

**Problem**: Containers keep restarting or failing

**Solutions**:
1. Check logs: `docker compose -f srcs/docker-compose.yml logs`
2. Check if `.env` file exists: `ls -la srcs/.env`
3. Check if ports are available (443 might be in use):
   ```bash
   sudo netstat -tlnp | grep 443
   ```

### WordPress Shows Installation Screen

**Problem**: Instead of the configured site, you see "WordPress Installation"

**Solutions**:
1. Database might not be ready yet. Wait 30 seconds and refresh
2. Check MariaDB container logs: `docker logs mariadb`
3. Restart WordPress container: `docker restart wordpress`
4. If persists, check database connection settings in `.env`

### Permission Denied Errors

**Problem**: Container logs show permission errors

**Solutions**:
```bash
sudo chown -R $USER:$USER /home/paranha/data/
sudo chmod -R 755 /home/paranha/data/
```

### Lost Admin Password

**Problem**: Can't remember WordPress admin password

**Solutions**:
1. Check the `.env` file: `cat srcs/.env | grep WP_ADM_PW`
2. If you've changed it and forgot, you'll need to reset the database:
   ```bash
   make clean_all
   make
   ```
   **Warning**: This deletes all content!

### Site Loads But Shows Errors

**Problem**: Page loads but displays PHP/WordPress errors

**Solutions**:
1. Check WordPress logs: `docker logs wordpress`
2. Check NGINX logs: `docker logs nginx`
3. Verify file permissions inside container:
   ```bash
   docker exec wordpress ls -la /var/www/html
   ```

### Browser Blocks HTTPS Access

**Problem**: Browser won't let you proceed despite clicking "Advanced"

**Solutions**:
1. In Chrome: Type `thisisunsafe` on the warning page
2. In Firefox: Click "Advanced" → "Accept the Risk and Continue"
3. Temporarily use HTTP for testing (not recommended):
   - Modify nginx config to allow port 80 (remember to change back!)

---

## Need More Help?

For developer-level information, see [DEV_DOC.md](DEV_DOC.md)

For project overview and setup, see [README.md](README.md)

### Quick Reference Commands

| Task | Command |
|------|---------|
| Start everything | `make` or `make up` |
| Stop everything | `make stop` |
| View status | `docker ps` |
| View logs | `docker logs <container>` |
| Complete reset | `make clean_all && make` |
| Check .env file | `cat srcs/.env` |

---

**Document Version**: 1.0
**Last Updated**: December 2024
**Maintained by**: paranha
