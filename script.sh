sudo apt update

curl -sL https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo apt install nodejs -y

sudo apt update

sudo apt install postgresql postgresql-contrib -y
sudo systemctl start postgresql.service

sudo apt install nginx -y
sudo ufw allow 'Nginx HTTP'
sudo systemctl start nginx


url=$(curl -s ifconfig.me)

sudo tee /etc/nginx/sites-available/$url <<EOL
server {
    listen 80;
    listen [::]:80;

    server_name $url www.$url;

    location / {
        proxy_pass http://localhost:1337;
        include proxy_params;
    }
}
EOL

sudo ln -s /etc/nginx/sites-available/$url /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
sudo -i -u postgres createdb strapi-db
sudo -i -u postgres createuser akki
sudo -i -u postgres psql -c "ALTER USER akki PASSWORD 'akki';"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE \"strapi-db\" TO akki;"



yes | npx create-strapi-app@latest my-project12 \
  --dbclient=postgres \
  --dbhost=127.0.0.1 \
  --dbname=strapi-db \
  --dbusername=akki \
  --dbpassword=akki \
  --dbport=5432

cd my-project12
NODE_ENV=production npm run build

node /home/adminuser/my-project12/node_modules/.bin/strapi start
