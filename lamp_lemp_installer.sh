#!/bin/bash

###############################################################################
# 📦 One-Click LAMP/LEMP Installer Script
# ---------------------------------------
# Installs a complete LAMP or LEMP stack (Apache/Nginx, MariaDB, PHP) on
# Ubuntu 20.04/22.04 or Debian 11+ with minimal interaction.
#
# 🧑‍💻 Developed by: Hosteons.com
# 🌐 Website: https://hosteons.com
# 💬 Support: https://my.hosteons.com
#
# 📝 License: MIT
# You are free to use, modify, and distribute this script. Attribution is appreciated.
#
# ⭐ Star this on GitHub if you found it useful: https://github.com/hosteons/lamp-lemp-oneclick-installer
###############################################################################

set -e

echo "====================================="
echo " One-Click LAMP/LEMP Installer Script"
echo " by Hosteons.com | MIT Licensed"
echo "====================================="

if [[ "$EUID" -ne 0 ]]; then
  echo "❌ Please run this script as root"
  exit 1
fi

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "❌ Unsupported OS"
    exit 1
fi

if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    echo "❌ Only Ubuntu and Debian are supported."
    exit 1
fi

echo "Choose stack to install:"
echo "1. LAMP (Apache + MariaDB + PHP)"
echo "2. LEMP (Nginx + MariaDB + PHP-FPM)"
read -rp "Enter your choice (1 or 2): " choice

apt update && apt upgrade -y

PHP_PACKAGES="php php-mysql php-cli php-curl php-gd php-mbstring php-xml unzip"

if [[ "$choice" == "1" ]]; then
  echo "🔧 Installing LAMP stack..."
  apt install -y apache2 mariadb-server $PHP_PACKAGES libapache2-mod-php ufw
  systemctl enable apache2 mariadb
  systemctl start apache2 mariadb
  echo "<?php phpinfo(); ?>" > /var/www/html/info.php
  echo "✅ LAMP stack installed successfully!"
  echo "🔗 Visit http://YOUR_SERVER_IP/info.php to verify PHP is working."
elif [[ "$choice" == "2" ]]; then
  echo "🔧 Installing LEMP stack..."
  apt install -y nginx mariadb-server $PHP_PACKAGES php-fpm ufw
  PHP_VER=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
  PHP_SOCK="/run/php/php${PHP_VER}-fpm.sock"
  cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF
  systemctl enable nginx mariadb "php${PHP_VER}-fpm"
  systemctl start nginx mariadb "php${PHP_VER}-fpm"
  mkdir -p /var/www/html
  echo "<?php phpinfo(); ?>" > /var/www/html/info.php
  nginx -t && systemctl reload nginx
  echo "✅ LEMP stack installed successfully!"
  echo "🔗 Visit http://YOUR_SERVER_IP/info.php to verify PHP is working."
else
  echo "❌ Invalid selection. Exiting."
  exit 1
fi

ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw --force enable
echo "✅ Firewall configured. Allowed ports: SSH, HTTP, HTTPS."
