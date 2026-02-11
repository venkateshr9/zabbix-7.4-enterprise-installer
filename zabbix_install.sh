########################################
# Installer Script for Zabbix NMS Server 
# with system required tools on Centos 10 
# Creator - Venkatesh Ramalingam
# Mail - technousher@gmail.com
#!/bin/bash
set -e
set -o pipefail
trap 'echo "❌ FAILED at line $LINENO"; exit 1' ERR

echo "================================================="
echo " ZABBIX 7.4.6 ENTERPRISE INSTALLER"
echo " START TIME: $(date)"
echo "================================================="

TZ="Asia/Kolkata"
DB_NAME="zabbix"
DB_USER="zabbix"
SERVER_NAME=$(hostname -f)
DB_PASS_FILE="/root/.zabbix_db_pass"

########################################################
# PRECHECK
########################################################
[[ $EUID -ne 0 ]] && { echo "Run as root"; exit 1; }

echo "[STEP 1] Internet Check"
ping -c 3 google.com >/dev/null || { echo "No Internet"; exit 1; }
echo "✔ Internet OK"

########################################################
# SYSTEM UPDATE
########################################################
echo "[STEP 2] Updating System"
dnf update -y
echo "✔ System Updated"

########################################################
# BASE PACKAGES
########################################################
echo "[STEP 3] Installing base packages"
dnf install -y firewalld audit chrony \
policycoreutils-python-utils vim wget curl unzip tar openssl

systemctl enable --now firewalld auditd chronyd
timedatectl set-timezone $TZ
echo "✔ Base configured"

########################################################
# CREATE ADMIN USER
########################################################
echo "[STEP 4] Creating local admin user"
if ! id zabbixadmin &>/dev/null; then
    useradd -m -s /bin/bash zabbixadmin
    echo "zabbixadmin ALL=(ALL) ALL" >> /etc/sudoers
fi
echo "✔ User ready"

########################################################
# FIREWALL
########################################################
echo "[STEP 5] Firewall"
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=10050/tcp
firewall-cmd --permanent --add-port=10051/tcp
firewall-cmd --reload
echo "✔ Firewall configured"

########################################################
# SELINUX
########################################################
echo "[STEP 6] SELinux"
setsebool -P httpd_can_network_connect on
echo "✔ SELinux configured"

########################################################
# ZABBIX REPO
########################################################
echo "[STEP 7] Zabbix Repo"
if ! rpm -q zabbix-release >/dev/null; then
    rpm -Uvh https://repo.zabbix.com/zabbix/7.4/release/centos/10/noarch/zabbix-release-latest-7.4.el10.noarch.rpm
fi
dnf clean all
echo "✔ Repo ready"

########################################################
# INSTALL PACKAGES
########################################################
echo "[STEP 8] Installing Zabbix stack"
dnf install -y \
zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf \
zabbix-agent2 zabbix-sql-scripts \
mariadb-server php php-mysqlnd php-gd php-xml \
php-bcmath php-mbstring php-opcache mod_ssl

echo "✔ Packages installed"

########################################################
# START MARIADB
########################################################
echo "[STEP 9] Starting MariaDB"
systemctl enable --now mariadb
systemctl is-active --quiet mariadb || { echo "MariaDB failed"; exit 1; }
echo "✔ MariaDB running"

########################################################
# GENERATE SAFE PASSWORD (NO $ SYMBOL)
########################################################
if [ ! -f "$DB_PASS_FILE" ]; then
    DB_PASS=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9' | head -c 16)
    echo "$DB_PASS" > "$DB_PASS_FILE"
    chmod 600 "$DB_PASS_FILE"
else
    DB_PASS=$(cat "$DB_PASS_FILE")
fi

echo "✔ DB Password Generated"

########################################################
# CREATE DATABASE
########################################################
echo "[STEP 10] Configuring Database"

mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME}
CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost'
IDENTIFIED BY '${DB_PASS}';

ALTER USER '${DB_USER}'@'localhost'
IDENTIFIED BY '${DB_PASS}';

GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "✔ Database user configured"

########################################################
# IMPORT SCHEMA
########################################################
echo "[STEP 11] Importing Schema"

if ! mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME} -e "show tables like 'users';" | grep -q users; then
    SCHEMA=$(rpm -ql zabbix-sql-scripts | grep -m1 '/mysql/server.sql.gz')
    zcat "$SCHEMA" | mysql -u ${DB_USER} -p${DB_PASS} ${DB_NAME}
    echo "✔ Schema imported"
else
    echo "✔ Schema already exists"
fi

########################################################
# CONFIGURE ZABBIX SERVER FILE
########################################################
echo "[STEP 12] Configuring Zabbix Server"

sed -i "/^DBName=/d" /etc/zabbix/zabbix_server.conf
sed -i "/^DBUser=/d" /etc/zabbix/zabbix_server.conf
sed -i "/^DBPassword=/d" /etc/zabbix/zabbix_server.conf

cat >> /etc/zabbix/zabbix_server.conf <<EOF
DBName=${DB_NAME}
DBUser=${DB_USER}
DBPassword=${DB_PASS}
EOF

echo "✔ Zabbix config updated"

########################################################
# MARIADB TUNING
########################################################
echo "[STEP 13] MariaDB tuning"
RAM=$(free -m | awk '/Mem:/ {print $2}')
BUFFER=$((RAM / 2))

cat <<EOF >/etc/my.cnf.d/zabbix.cnf
[mysqld]
innodb_buffer_pool_size=${BUFFER}M
innodb_log_file_size=256M
innodb_flush_log_at_trx_commit=2
innodb_file_per_table=1
max_connections=200
character-set-server=utf8mb4
collation-server=utf8mb4_bin
EOF

systemctl restart mariadb
echo "✔ MariaDB tuned"

########################################################
# START SERVICES
########################################################
echo "[STEP 14] Starting Services"

systemctl enable --now zabbix-server zabbix-agent2 httpd php-fpm

sleep 10

########################################################
# VERIFY SERVER
########################################################
echo "[STEP 15] Verification"

systemctl is-active --quiet zabbix-server || { echo "Zabbix server failed"; exit 1; }

ss -lntp | grep 10051 || { echo "Port 10051 not listening"; exit 1; }

echo "✔ Zabbix Server Running"
echo "✔ Port 10051 Listening"

########################################################
# COMPLETE
########################################################
echo "================================================="
echo " INSTALLATION COMPLETED SUCCESSFULLY"
echo " URL: https://$(hostname -I | awk '{print $1}')/zabbix"
echo " DB PASSWORD: ${DB_PASS}"
echo " Password stored in: ${DB_PASS_FILE}"
echo "================================================="
echo "Creator - Venkatesh Ramalingam Mail - technousher@gmail.com"
########################################################