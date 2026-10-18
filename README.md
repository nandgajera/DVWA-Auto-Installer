# DVWA Auto Installer for Kali Linux

One-command installer for **DVWA (Damn Vulnerable Web Application)** on Kali Linux, with a live progress bar and step-by-step output.

> **Created by [Nand Gajera](https://github.com/nandgajera/)**

---


## ✨ Features

- Fully automated installation of DVWA
- Live progress: `[Step n/14]` with an overall percentage bar
- Installs required packages (Apache2, MariaDB, PHP, Git)
- Creates the DVWA config file and sets the database credentials
- Creates the database and user, and grants privileges
- Auto-detects your PHP version and enables `allow_url_fopen` and `allow_url_include`
- Tries to click **Create / Reset Database** for you at the end

---

## 📋 Requirements

| Requirement | Details |
|---|---|
| OS | Kali Linux (recommended) also works on most Debian-based distros |
| Privileges | Root / `sudo` |
| Internet | Needed to download packages and clone DVWA |

---

## 🚀 Installation Guide

### 1. Clone this repository

```bash
git clone https://github.com/nandgajera/DVWA-Auto-Installer.git
cd DVWA-Auto-Installer
```

> Replace `DVWA-Auto-Installer` with your actual repository name if it is different.

### 2. Make the script executable

```bash
chmod +x install_dvwa.sh
```

### 3. Run the installer as root

```bash
sudo bash install_dvwa.sh
```

You will see the DVWA banner, then each step with its progress:

```
[Step 3/14] Cloning DVWA from GitHub...
   [ OK ] DVWA downloaded
Overall Progress: [###############-----------------------------------]  21%
```

### 4. Open DVWA in your browser

```
http://127.0.0.1/DVWA
```

| Field | Value |
|---|---|
| Username | `admin` |
| Password | `password` |

If you see a setup page, scroll down and click **Create / Reset Database**, then log in again.

---

## 🛠️ What the Script Does

| Step | Action |
|---|---|
| 1 | Installs Apache2, MariaDB, PHP, PHP extensions, Git, curl |
| 2 | Moves to the web root `/var/www/html` |
| 3 | Clones DVWA from `https://github.com/digininja/DVWA.git` |
| 4 | Verifies the download |
| 5 | Sets permissions with `chmod -R 777 DVWA` |
| 6 | Copies `config.inc.php.dist` to `config.inc.php` (original is kept) |
| 7 | Sets database user `admin` and password `password` in the config |
| 8 | Starts the database service |
| 9 | Creates the `dvwa` database |
| 10 | Creates user `admin`@`127.0.0.1` and grants privileges |
| 11 | Starts Apache2 |
| 12 | Enables `allow_url_fopen` and `allow_url_include` in `php.ini` |
| 13 | Reloads Apache2 |
| 14 | Creates / resets the DVWA database through the setup page |


## 🔄 Re-run DVWA After Shutdown / Restart
 
DVWA stays installed on your disk. After you shut down or restart your PC, you only need to start the services again. **You do not need to run the installer again.**
 
### 1. Start the database and web server
 
```bash
sudo service mariadb start
sudo service apache2 start
```
 
### 2. Open DVWA in your browser
 
```
http://127.0.0.1/DVWA
```
 
Log in with `admin` / `password`.
 
### 3. Set the security level (if needed)
 
After logging in, go to **DVWA Security** in the left menu and choose a level (Low, Medium, High or Impossible). The level may reset after a restart.
 
### Start services automatically at boot (optional)
 
Run this once, and DVWA will be available whenever Kali starts:
 
```bash
sudo systemctl enable mariadb apache2
```
 
To turn auto-start off again:
 
```bash
sudo systemctl disable mariadb apache2
```
 
### Stop DVWA when you are done
 
```bash
sudo service apache2 stop
sudo service mariadb stop
```
 
### Quick check that everything is running
 
```bash
sudo service mariadb status
sudo service apache2 status
```
 
---

## 🧰 Manual Installation (Optional)

If you prefer to do it by hand:

```bash
# 1. Clone DVWA
cd /var/www/html
git clone https://github.com/digininja/DVWA.git
chmod -R 777 DVWA

# 2. Create the config file
cd DVWA/config
cp config.inc.php.dist config.inc.php
nano config.inc.php      # set username 'admin' and password 'password'

# 3. Start the database and configure it
service mariadb start
mysql -u root -p
```

```sql
CREATE DATABASE dvwa;
CREATE USER 'admin'@'127.0.0.1' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON dvwa.* TO 'admin'@'127.0.0.1';
EXIT;
```

```bash
# 4. Start Apache and edit PHP settings
service apache2 start
ls /etc/php                         # check your PHP version
nano /etc/php/<version>/apache2/php.ini
#   allow_url_fopen = On
#   allow_url_include = On
service apache2 reload
```

Then open `http://127.0.0.1/DVWA`, click **Create / Reset Database** and log in.

---

## ❓ Troubleshooting

| Problem | Fix |
|---|---|
| `Please run as root` | Run with `sudo bash install_dvwa.sh` |
| Cannot create database (access denied) | A MySQL/MariaDB root password is set. Run the manual DB steps with `mysql -u root -p` |
| Page not found at `/DVWA` | Check Apache is running: `sudo service apache2 status` |
| Database connection error on DVWA | Make sure the DB service is running: `sudo service mariadb start` |
| Auto database setup failed | Open `http://127.0.0.1/DVWA/setup.php` and click **Create / Reset Database** |

---

## 🧹 Uninstall

```bash
sudo rm -rf /var/www/html/DVWA
sudo mysql -u root -e "DROP DATABASE dvwa; DROP USER 'admin'@'127.0.0.1';"
```

---

## 🙏 Credits

- [DVWA](https://github.com/digininja/DVWA) by Robin Wood (digininja) and contributors
- Installer script by [Nand Gajera](https://github.com/nandgajera/)

---

## 📄 License

This installer script is provided for educational use. DVWA is licensed under its own terms. See the [DVWA repository](https://github.com/digininja/DVWA) for details.
