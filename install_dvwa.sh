#!/bin/bash
# ==============================================================
#  DVWA (Damn Vulnerable Web Application) Auto Installer
#  Target OS : Kali Linux
#  Created by: Nand Gajera
#  Usage     : sudo bash install_dvwa.sh
# ==============================================================

# ---------- Colors ----------
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; CYAN='\033[1;36m'; MAGENTA='\033[1;35m'; NC='\033[0m'

# ---------- Settings ----------
WEB_ROOT="/var/www/html"
DVWA_DIR="$WEB_ROOT/DVWA"
DVWA_REPO="https://github.com/digininja/DVWA.git"
DB_NAME="dvwa"
DB_USER="admin"
DB_PASS="password"
TOTAL_STEPS=14
CURRENT_STEP=0

# ---------- Banner ----------
banner() {
    clear
    echo -e "${RED}"
    cat << 'EOF'
 ██████╗ ██╗   ██╗██╗    ██╗ █████╗
 ██╔══██╗██║   ██║██║    ██║██╔══██╗
 ██║  ██║██║   ██║██║ █╗ ██║███████║
 ██║  ██║╚██╗ ██╔╝██║███╗██║██╔══██║
 ██████╔╝ ╚████╔╝ ╚███╔███╔╝██║  ██║
 ╚═════╝   ╚═══╝   ╚══╝╚══╝ ╚═╝  ╚═╝
EOF
    echo -e "${NC}"
    echo -e "${CYAN}   Damn Vulnerable Web Application - Auto Installer${NC}"
    echo -e "${YELLOW}   Created by Nand Gajera${NC}"
    echo -e "${BLUE}   ------------------------------------------------${NC}"
    echo
}

# ---------- Progress bar ----------
progress_bar() {
    local percent=$(( CURRENT_STEP * 100 / TOTAL_STEPS ))
    local filled=$(( percent / 2 ))
    local empty=$(( 50 - filled ))
    printf "${MAGENTA}Overall Progress: [${GREEN}"
    printf '%0.s#' $(seq 1 $filled) 2>/dev/null
    printf "${NC}"
    printf '%0.s-' $(seq 1 $empty) 2>/dev/null
    printf "${MAGENTA}] %3d%%${NC}\n\n" "$percent"
}

step() {
    CURRENT_STEP=$(( CURRENT_STEP + 1 ))
    echo -e "${BLUE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}]${NC} ${CYAN}$1${NC}"
}

ok()   { echo -e "   ${GREEN}[ OK ]${NC} $1"; progress_bar; }
warn() { echo -e "   ${YELLOW}[WARN]${NC} $1"; }
fail() { echo -e "   ${RED}[FAIL]${NC} $1"; exit 1; }

# ---------- Root check ----------
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root:  sudo bash $0${NC}"
    exit 1
fi

banner

# ---------- Step 1: Dependencies ----------
step "Installing required packages (apache2, mariadb, php, git)..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null 2>&1
apt-get install -y apache2 mariadb-server php php-mysqli php-gd libapache2-mod-php git curl >/dev/null 2>&1 \
    || fail "Package installation failed. Check your internet connection."
ok "Dependencies installed"

# ---------- Step 2: Go to web root ----------
step "Changing directory to $WEB_ROOT ..."
cd "$WEB_ROOT" || fail "Cannot access $WEB_ROOT"
ok "Now in $(pwd)"

# ---------- Step 3: Clone DVWA ----------
step "Cloning DVWA from GitHub..."
if [ -d "$DVWA_DIR" ]; then
    warn "DVWA folder already exists - removing old copy for a clean install"
    rm -rf "$DVWA_DIR"
fi
git clone "$DVWA_REPO" 2>&1 | sed 's/^/      /' 
[ -d "$DVWA_DIR" ] || fail "git clone failed"
ok "DVWA downloaded"

# ---------- Step 4: Verify download ----------
step "Verifying download (ls)..."
ls "$WEB_ROOT" | sed 's/^/      /'
ok "DVWA folder present"

# ---------- Step 5: Permissions ----------
step "Setting permissions (chmod -R 777 DVWA)..."
chmod -R 777 "$DVWA_DIR"
ok "Permissions set"

# ---------- Step 6: Config file ----------
step "Creating config file from template..."
cd "$DVWA_DIR/config" || fail "Cannot access DVWA config directory"
cp config.inc.php.dist config.inc.php || fail "Could not copy config.inc.php.dist"
ok "config.inc.php created (original .dist file kept)"

# ---------- Step 7: Edit config ----------
step "Setting DB username='$DB_USER' and password='$DB_PASS' in config.inc.php..."
sed -i "s/^\(\$_DVWA\[ *'db_user' *\] *= *\).*/\1'${DB_USER}';/" config.inc.php
sed -i "s/^\(\$_DVWA\[ *'db_password' *\] *= *\).*/\1'${DB_PASS}';/" config.inc.php
grep -E "db_user|db_password" config.inc.php | sed 's/^/      /'
ok "config.inc.php updated"

# ---------- Step 8: Start database ----------
step "Starting database service..."
service mariadb start >/dev/null 2>&1 || service mysql start >/dev/null 2>&1 \
    || fail "Could not start MariaDB/MySQL"
sleep 3
ok "Database service running"

# ---------- Step 9: Create DB ----------
step "Creating database '$DB_NAME'..."
mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};" \
    || fail "Could not create database (is a root password set?)"
ok "Database '$DB_NAME' created"

# ---------- Step 10: Create user + grant ----------
step "Creating user '$DB_USER' and granting privileges..."
mysql -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';" \
    || fail "Could not create DB user"
mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1'; FLUSH PRIVILEGES;" \
    || fail "Could not grant privileges"
ok "User created and privileges granted"

# ---------- Step 11: Start Apache ----------
step "Starting Apache web server..."
service apache2 start >/dev/null 2>&1 || fail "Could not start apache2"
ok "Apache2 running"

# ---------- Step 12: PHP configuration ----------
step "Configuring PHP (allow_url_fopen / allow_url_include)..."
PHP_VER=$(ls /etc/php | sort -V | tail -n 1)
PHP_INI="/etc/php/${PHP_VER}/apache2/php.ini"
[ -f "$PHP_INI" ] || fail "php.ini not found at $PHP_INI"
echo "      Detected PHP version: $PHP_VER"
sed -i 's/^;*\s*allow_url_fopen\s*=.*/allow_url_fopen = On/'   "$PHP_INI"
sed -i 's/^;*\s*allow_url_include\s*=.*/allow_url_include = On/' "$PHP_INI"
grep -E "^allow_url_(fopen|include)" "$PHP_INI" | sed 's/^/      /'
ok "php.ini updated"

# ---------- Step 13: Reload Apache ----------
step "Reloading Apache..."
service apache2 reload >/dev/null 2>&1 || service apache2 restart >/dev/null 2>&1
ok "Apache reloaded"

# ---------- Step 14: Create/Reset DVWA database (best effort) ----------
step "Creating/Resetting DVWA database via setup page..."
COOKIE_JAR=$(mktemp)
SETUP_URL="http://127.0.0.1/DVWA/setup.php"
PAGE=$(curl -s -c "$COOKIE_JAR" "$SETUP_URL")
TOKEN=$(echo "$PAGE" | grep -oP "user_token' value='\K[^']+" | head -n 1)
if [ -n "$TOKEN" ]; then
    curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" -o /dev/null \
        -d "create_db=Create / Reset Database&user_token=${TOKEN}" "$SETUP_URL"
    ok "DVWA database created"
else
    warn "Could not auto-click 'Create / Reset Database'. Do it manually in the browser."
    progress_bar
fi
rm -f "$COOKIE_JAR"

# ---------- Done ----------
echo -e "${GREEN}=================================================${NC}"
echo -e "${GREEN}   DVWA INSTALLATION COMPLETE!${NC}"
echo -e "${GREEN}=================================================${NC}"
echo -e " Open in browser : ${CYAN}http://127.0.0.1/DVWA${NC}"
echo -e " Login           : ${CYAN}admin / password${NC}"
echo -e " If prompted     : scroll to the setup page and click ${CYAN}Create / Reset Database${NC}, then log in again."
echo
echo -e "${RED}"
cat << 'EOF'
 ██████╗ ██╗   ██╗██╗    ██╗ █████╗
 ██╔══██╗██║   ██║██║    ██║██╔══██╗
 ██║  ██║██║   ██║██║ █╗ ██║███████║
 ██║  ██║╚██╗ ██╔╝██║███╗██║██╔══██║
 ██████╔╝ ╚████╔╝ ╚███╔███╔╝██║  ██║
 ╚═════╝   ╚═══╝   ╚══╝╚══╝ ╚═╝  ╚═╝
EOF
echo -e "${NC}${YELLOW}            Created by Nand Gajera${NC}"
echo
