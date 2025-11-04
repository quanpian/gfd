#!/bin/bash
set -euo pipefail

# ================== 配置 ==================
APP_DIR="/opt/pyflix/app"
ZIP_FILE="/root/php_video_cms_demo_wentaocms.zip"  # 已上传到服务器
BACKUP_DIR="/root/wentaocms_backups"
LOG_FILE="/root/wentaocms_auto.log"

MYSQL_ROOT_PASS="9698"        # 可改成固定密码，也可用 openssl rand -base64 12
DB_NAME="wentaocms"
DB_USER="wentaouser"
DB_PASS="9698"                # 可改成固定密码，也可用 openssl rand -base64 12

# ================== 输出日志 ==================
log() { echo -e "$(date +'%F %T') $1" | tee -a "$LOG_FILE"; }

log "🚀 WentaoCMS 终极无人值守部署开始..."

# ================== 安装依赖 ==================
log "📦 安装基础依赖..."
yum install -y epel-release yum-utils unzip wget curl git socat >> "$LOG_FILE" 2>&1 || true
yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm >> "$LOG_FILE" 2>&1 || true
yum-config-manager --enable remi-php74 >> "$LOG_FILE" 2>&1
yum install -y php php-fpm php-mysqlnd php-mbstring php-xml mariadb-server nginx certbot python3-certbot-nginx mailx >> "$LOG_FILE" 2>&1

# ================== 启动数据库 ==================
log "🛠 启动 MariaDB 数据库..."
systemctl enable mariadb >> "$LOG_FILE" 2>&1
systemctl start mariadb >> "$LOG_FILE" 2>&1

# ================== 配置数据库 ==================
log "🔑 配置数据库..."
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASS'; FLUSH PRIVILEGES;" >> "$LOG_FILE" 2>&1
mysql -uroot -p"$MYSQL_ROOT_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" >> "$LOG_FILE" 2>&1
mysql -uroot -p"$MYSQL_ROOT_PASS" -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';" >> "$LOG_FILE" 2>&1
mysql -uroot -p"$MYSQL_ROOT_PASS" -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;" >> "$LOG_FILE" 2>&1

# ================== 部署 CMS ==================
log "📥 解压 CMS..."
mkdir -p "$APP_DIR"
unzip -o "$ZIP_FILE" -d "$APP_DIR" >> "$LOG_FILE" 2>&1
chmod -R 755 "$APP_DIR"

# ================== 自动生成 CMS 配置 ==================
CONFIG_FILE="$APP_DIR/config.php"
log "📝 生成 CMS 配置文件..."
cat > "$CONFIG_FILE" <<EOL
<?php
return [
    'DB_HOST' => 'localhost',
    'DB_NAME' => '$DB_NAME',
    'DB_USER' => '$DB_USER',
    'DB_PASS' => '$DB_PASS',
];
EOL

# ================== 启动 PHP & Nginx ==================
log "⚡ 启动服务..."
systemctl enable php-fpm >> "$LOG_FILE" 2>&1
systemctl start php-fpm >> "$LOG_FILE" 2>&1
systemctl enable nginx >> "$LOG_FILE" 2>&1
systemctl start nginx >> "$LOG_FILE" 2>&1

# ================== Nginx 配置 ==================
NGINX_CONF="/etc/nginx/conf.d/wentaocms.conf"
log "🔧 配置 Nginx..."
cat > "$NGINX_CONF" <<EOL
server {
    listen 80;
    server_name _;
    root $APP_DIR;
    index index.php index.html index.htm;

    access_log /var/log/nginx/wentaocms.access.log;
    error_log /var/log/nginx/wentaocms.error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico)\$ {
        expires 30d;
        access_log off;
    }
}
EOL

nginx -t >> "$LOG_FILE" 2>&1
systemctl restart nginx >> "$LOG_FILE" 2>&1

log "✅ WentaoCMS 部署完成！"
log "MySQL root=$MYSQL_ROOT_PASS, DB user=$DB_USER, password=$DB_PASS"
log "访问你的服务器 IP 即可打开 CMS 首页。"


#!/bin/bash
set -euo pipefail

# ================== 配置 ==================
APP_DIR="/opt/pyflix/app"
ZIP_URL="https://example.com/php_video_cms_demo_wentaocms.zip"  # 替换成实际可下载 URL
ZIP_FILE="/root/php_video_cms_demo_wentaocms.zip"
LOG_FILE="/root/wentaocms_auto_full.log"

MYSQL_ROOT_PASS=$(openssl rand -base64 12)
DB_NAME="wentaocms"
DB_USER="wentaouser"
DB_PASS=$(openssl rand -base64 12)

# ================== 输出日志 ==================
log() { echo -e "$(date +'%F %T') $1" | tee -a "$LOG_FILE"; }

log "🚀 WentaoCMS 完全无人值守部署开始..."
log "MySQL root=$MYSQL_ROOT_PASS, DB user=$DB_USER password=$DB_PASS"

# ================== 安装依赖 ==================
log "📦 安装基础依赖..."
yum install -y epel-release yum-utils unzip wget curl git socat >> "$LOG_FILE" 2>&1 || true
yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm >> "$LOG_FILE" 2>&1 || true
yum-config-manager --enable remi-php74 >> "$LOG_FILE" 2>&1
yum install -y php php-fpm php-mysqlnd php-mbstring php-xml mariadb-server nginx certbot python3-certbot-nginx mailx >> "$LOG_FILE" 2>&1

# ================== 下载 CMS ==================
log "📥 下载 CMS 文件..."
wget -O "$ZIP_FILE" "$https://pan.quark.cn/s/d06f4e1b43b3" >> "$LOG_FILE" 2>&1

# ================== 启动数据库 ==================
log "🛠 启动 MariaDB 数据库..."
systemctl enable mariadb >> "$LOG_FILE" 2>&1
systemctl start mariadb >> "$LOG_FILE" 2>&1

# ================== 配置数据库 ==================
log "🔑 配置数据库..."
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASS'; FLUSH PRIVILEGES;" >> "$LOG_FILE" 2>&1
mysql -uroot -p"$MYSQL_ROOT_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" >> "$LOG_FILE" 2>&1
mysql -uroot -p"$MYSQL_ROOT_PASS" -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';" >> "$LOG_FILE" 2>&1
mysql -uroot -p"$MYSQL_ROOT_PASS" -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;" >> "$LOG_FILE" 2>&1

# ================== 部署 CMS ==================
log "📦 解压 CMS..."
mkdir -p "$APP_DIR"
unzip -o "$ZIP_FILE" -d "$APP_DIR" >> "$LOG_FILE" 2>&1
chmod -R 755 "$APP_DIR"

# ================== 自动生成 CMS 配置 ==================
CONFIG_FILE="$APP_DIR/config.php"
log "📝 生成 CMS 配置文件..."
cat > "$CONFIG_FILE" <<EOL
<?php
return [
    'DB_HOST' => 'localhost',
    'DB_NAME' => '$DB_NAME',
    'DB_USER' => '$DB_USER',
    'DB_PASS' => '$DB_PASS',
];
EOL

# ================== 启动 PHP & Nginx ==================
log "⚡ 启动服务..."
systemctl enable php-fpm >> "$LOG_FILE" 2>&1
systemctl start php-fpm >> "$LOG_FILE" 2>&1
systemctl enable nginx >> "$LOG_FILE" 2>&1
systemctl start nginx >> "$LOG_FILE" 2>&1

# ================== 配置 Nginx ==================
NGINX_CONF="/etc/nginx/conf.d/wentaocms.conf"
log "🔧 配置 Nginx..."
cat > "$NGINX_CONF" <<EOL
server {
    listen 80;
    server_name _;
    root $APP_DIR;
    index index.php index.html index.htm;

    access_log /var/log/nginx/wentaocms.access.log;
    error_log /var/log/nginx/wentaocms.error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico)\$ {
        expires 30d;
        access_log off;
    }
}
EOL

nginx -t >> "$LOG_FILE" 2>&1
systemctl restart nginx >> "$LOG_FILE" 2>&1

log "✅ WentaoCMS 完全无人值守部署完成！"
log "访问服务器 IP 即可打开 CMS 首页。"
