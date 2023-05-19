#!/bin/bash

echo "Masukan Wilayah Replikasi"
read wilayah

# This script assumes it's being run as a user with sudo permissions.

# Update package index and install required packages.
sudo apt-get update -y 
sudo apt-get install -y ca-certificates curl gnupg wget

# Install Docker
sudo apt-get -y update 
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify Docker installation by checking the Docker daemon status.
systemctl is-active --quiet docker || sudo systemctl start docker.service

# Install PostgreSQL 11 and Nginx.
DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs)
sudo sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ $CODENAME-pgdg main' > /etc/apt/sources.list.d/postgresql.list"
sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update -y 
sudo apt-get install -y postgresql-11 nginx

# Prompt the user for the PostgreSQL username
echo "Masukan PostgreSQL username:"
read username

# Prompt the user for the new password
echo "Masukan password baru:"
read password

# Connect to the database and change the user's password
sudo -u postgres psql

# Confirm the password change
echo "Password for $username has been changed to $password."

# Stop the PostgreSQL service
sudo systemctl stop postgresql

# Use sed to change the value of max_connections
sudo sed -i "s/^#*\(max_connections\s*=\s*\).*\$/\1 1000/" /etc/postgresql/11/main/postgresql.conf

# Use sed to change the value of listen_addresses
sudo sed -i "s/^#*\(listen_addresses\s*=\s*\).*\$/\1 '*'/" /etc/postgresql/11/main/postgresql.conf

# Use sed to change the value of password_encryption
sudo sed -i "s/^#*\(password_encryption\s*=\s*\).*\$/\1 'scram-sha-256'/" /etc/postgresql/11/main/postgresql.conf

# Append the line to the end of the pg_hba.conf file
echo "host all all 0.0.0.0/0 scram-sha-256" | sudo tee -a /etc/postgresql/11/main/pg_hba.conf
echo "host all all ::/0 scram-sha-256" | sudo tee -a /etc/postgresql/11/main/pg_hba.conf

# Start the PostgreSQL service
sudo systemctl start postgresql

# Launch Docker containers.
echo "Masukan username gitlab"
read username
echo "Masukan password gitlab"
read -s userpassword
docker login registry.gitlab.com -u $username -p $userpassword
sudo docker run -d --restart always --name replikasi-pdj-frontend-admin-main -p 20021:80 registry.gitlab.com/jdsteam/portal-data-jabar/replikasi-pdj-frontend:admin-main
sudo docker run -d --restart always --name replikasi-pdj-frontend-opendata-main-browser -p 20042:80 registry.gitlab.com/jdsteam/portal-data-jabar/replikasi-pdj-frontend:opendata-main-browser
sudo docker run -d --restart always --name replikasi-pdj-frontend-opendata-main-server -p 20041:4000 registry.gitlab.com/jdsteam/portal-data-jabar/replikasi-pdj-frontend:opendata-main-server
sudo docker run -d --restart always --name replikasi-pdj-frontend-satudata-main -p 20031:80 registry.gitlab.com/jdsteam/portal-data-jabar/replikasi-pdj-frontend:satudata-main


# # Get the network interface name
# sudo apt install -y net-tools
# interface=$(ip route get 1 | awk '{print $5;exit}')

# # Get the IP address for the interface
# host=$(ifconfig $interface | awk '$1=="inet"{print$2}')

echo "Masukan IP Address untuk host db"
read host
echo "Masukan password baru untuk db"
read password

APP_NAME=$(echo "Portal Data $wilayah")
PORT=5000
DEBUG=0
RELOAD=0
WORKER=1
DB_DRIVER=postgresql
DB=replikasipdj
DB_BIGDATA=replikasipdj-bigdata
DB_LOG=replikasipdj-log
DB_HOST=$host
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=$password

SQLALCHEMY_ECHO=0
SQLALCHEMY_POOL_SIZE=1000
SQLALCHEMY_POOL_PRE_PING=1
SQLALCHEMY_POOL_TIMEOUT=30
SQLALCHEMY_MAX_OVERFLOW=0
SQLALCHEMY_POOL_RECYCLE=1
SQLALCHEMY_RECORD_QUERIES=1

OTEL_EXPORTER_OTLP_ENDPOINT=http://34.87.79.223:4317
OTEL_METRICS_EXPORTER=none
OTEL_SERVICE_NAME=$(echo $wilayah".backend" | tr '[:upper:]' '[:lower:]')

echo "APP_NAME=$APP_NAME" >> environment.env
echo "PORT=$PORT" >> environment.env
echo "DEBUG=$DEBUG" >> environment.env
echo "RELOAD=$RELOAD" >> environment.env
echo "WORKER=$WORKER" >> environment.env
echo "DB_DRIVER=$DB_DRIVER" >>  environment.env
echo "DB=$DB" >> environment.env
echo "DB_BIGDATA=$DB_BIGDATA" >> environment.env
echo "DB_LOG=$DB_LOG" >> environment.env
echo "DB_HOST=$DB_HOST" >> environment.env
echo "DB_PORT=$DB_PORT" >> environment.env
echo "DB_USER=$DB_USER" >> environment.env
echo "DB_PASSWORD=$DB_PASSWORD" >> environment.env
echo "SQLALCHEMY_ECHO=$SQLALCHEMY_ECHO" >> environment.env
echo "SQLALCHEMY_POOL_SIZE=$SQLALCHEMY_POOL_SIZE" >> environment.env
echo "SQLALCHEMY_POOL_PRE_PING=$SQLALCHEMY_POOL_PRE_PING" >> environment.env
echo "SQLALCHEMY_POOL_TIMEOUT=$SQLALCHEMY_POOL_TIMEOUT" >> environment.env
echo "SQLALCHEMY_MAX_OVERFLOW=$SQLALCHEMY_MAX_OVERFLOW" >> environment.env
echo "SQLALCHEMY_POOL_RECYCLE=$SQLALCHEMY_POOL_RECYCLE" >> environment.env
echo "SQLALCHEMY_RECORD_QUERIES=$SQLALCHEMY_RECORD_QUERIES" >> environment.env
echo "OTEL_EXPORTER_OTLP_ENDPOINT=$OTEL_EXPORTER_OTLP_ENDPOINT" >> environment.env
echo "OTEL_METRICS_EXPORTER=$OTEL_METRICS_EXPORTER" >> environment.env
echo "OTEL_SERVICE_NAME=$OTEL_SERVICE_NAME" >> environment.env

docker run --name replikasi-pdj-backend-main -p 20011:5000 --restart always --env-file environment.env -v /home/application/replikasi-pdj-backend-main/static/upload:/app/static/upload --network bridge -d registry.gitlab.com/jdsteam/portal-data-jabar/replikasi-pdj-backend:master 

docker logout registry.gitlab.com

rm environment.env


# Check if all containers are running.
for container in replikasi-pdj-frontend-admin-main replikasi-pdj-frontend-opendata-main-browser replikasi-pdj-frontend-opendata-main-server replikasi-pdj-frontend-satudata-main; do
    if ! (sudo docker ps | grep -q $container); then
        echo "Error: Container $container failed to start"
        exit 1
    fi
done

# Install socat.
sudo apt-get install -y socat
echo "Masukan email"
read email
# Install acme.sh.
curl https://get.acme.sh | sh -s email=$email

echo "Masukan domain admin"
read domainadmin
echo "Masukan domain satudata"
read domainsatudata
echo "Masukan domain opendata"
read domainopendata

service nginx stop
/root/.acme.sh/acme.sh  --issue  --standalone  -d $domainadmin -d $domainsatudata -d $domainopendata
service nginx start

curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt-get install gitlab-runner
gitlab-runner register

# Clean up.
sudo apt-get autoclean -y && sudo apt-get autoremove -y
echo "SELESAI, Silahkan config nginxnya!!!"