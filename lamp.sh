################################# altra Rocky ##################################

###################### CREATED By Luca Sabato employee ######################### 


#!/bin/bash

set -x

# Aggiornamento e installazione dei pacchetti
sudo dnf update -y

#sudo dnf config-manager --set-enabled powertools

sudo dnf install -y epel-release

sudo dnf update -y

#sudo dnf groupinstall "Development Tools"
sudo dnf install -y bind bind-utils curl avahi httpd mariadb mariadb-server php php-mysqlnd php-json php-mbstring php-fpm 

# Abilitazione dei moduli di Apache
sudo systemctl enable httpd
sudo systemctl start httpd
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Sicurezza dell'installazione di MariaDB
sudo mysql_secure_installation

sudo dnf install -y phpmyadmin

# Configurazione dei virtual host
declare -a vhost_names=("www.prova1.com" "www.provaluca2.com")

for vhost_name in "${vhost_names[@]}"; do
  # Creazione della directory del virtual host
  sudo mkdir -p /var/www/html/$vhost_name

  # Assegnazione dei permessi in scrittura ed eseguzione delle directory del virtual host
  #sudo find /var/www/html/www.provaluca2.com -type f -exec chmod 644 {} \;
  #sudo find /var/www/html/www.prova1.com -type f -exec chmod 644 {} \;
  sudo find /var/www/html/$vhost_name -type f -exec chmod 644 {} \;

  # Assegnazione dei permessi alla directory del virtual host
  sudo chown -R apache:apache /var/www/html/$vhost_name

  sudo chcon -R -t httpd_sys_rw_content_t /var/www/html/$vhost_name

  # Creazione del file di configurazione del virtual host per HTTPS
  sudo bash -c "cat <<EOF > /etc/httpd/conf.d/$vhost_name-ssl.conf
<VirtualHost *:443>
  ServerName $vhost_name
  ServerAlias www.$vhost_name
  DocumentRoot /var/www/html/$vhost_name
  ErrorLog /var/log/httpd/$vhost_name-ssl-error.log
  CustomLog /var/log/httpd/$vhost_name-ssl-access.log combined
  SSLEngine on
  SSLCertificateFile /etc/pki/tls/certs/$vhost_name.crt
  SSLCertificateKeyFile /etc/pki/tls/private/$vhost_name.key
  <Directory /var/www/html/$vhost_name>
    AllowOverride All
    Require all granted
  </Directory>

  # Reindirizzamento su HTTPS
  RewriteEngine On
  RewriteCond %{HTTPS} off
  RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</VirtualHost>
EOF"

  # Generazione dei certificati SSL per il virtual host
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/tls/private/$vhost_name.key -out /etc/pki/tls/certs/$vhost_name.crt -subj "/C=IT/ST=Lazio/L=Rome/O=Organization/OU=Department/CN=$vhost_name"
done

# Riavvio di Apache per applicare le modifiche
sudo systemctl reload httpd
sudo systemctl restart httpd


# Configurazione di BIND9 per i domini
sudo bash -c "cat <<EOF > /etc/named.conf.local
$(for vhost_name in "${vhost_names[@]}"; do
echo "zone \"$vhost_name\" {
    type master;
    file \"/var/named/$vhost_name.zone\";
};
";
done)
EOF"

# Creazione delle directory delle zone
for vhost_name in "${vhost_names[@]}"; do
  sudo mkdir -p /var/named
done

# Creazione dei file di zona
for vhost_name in "${vhost_names[@]}"; do
  sudo bash -c "cat <<EOF > /var/named/$vhost_name.zone
\$TTL 86400
@       IN      SOA     ns1.$vhost_name. admin.$vhost_name. (
                            2023062501 ; Serial
                            3600       ; Refresh
                            1800       ; Retry
                            604800     ; Expire
                            86400      ; Minimum TTL
                     )
@       IN      NS      ns1.$vhost_name.
@       IN      A       192.168.0.166
www     IN      A       192.168.0.166
EOF"
done

# Riavvio di BIND9 per applicare le modifiche

sudo systemctl enable named
sudo systemctl restart named


################################# altra Rocky ##################################

###################### CREATED By Luca Sabato employee ######################### 
