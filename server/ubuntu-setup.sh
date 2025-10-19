#!/bin/bash
# Ubuntu 20.04 UniCampus API Server Setup Script
# Run as root: sudo bash ubuntu-setup.sh

set -e

echo "🚀 UniCampus API Server Setup Starting..."

# Update system
echo "📦 Updating system packages..."
apt update && apt upgrade -y

# Install essential packages
echo "🔧 Installing essential packages..."
apt install -y curl wget git nginx ufw fail2ban htop nano

# Install Node.js 18.x
echo "📱 Installing Node.js 18.x..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs

# Install PostgreSQL
echo "🗄️ Installing PostgreSQL..."
apt install -y postgresql postgresql-contrib

# Install PM2 globally
echo "⚡ Installing PM2..."
npm install -g pm2

# Configure firewall
echo "🔒 Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'
ufw --force enable

# Create unicampus user
echo "👤 Creating unicampus user..."
adduser --disabled-password --gecos "" unicampus
usermod -aG sudo unicampus

# Setup PostgreSQL
echo "🗃️ Setting up PostgreSQL..."
sudo -u postgres createdb unicampus_dev
sudo -u postgres psql -c "CREATE USER unicampus WITH PASSWORD 'Kfd2025.mö';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE unicampus_dev TO unicampus;"

# Create project directory
echo "📁 Creating project structure..."
mkdir -p /home/unicampus/api
chown -R unicampus:unicampus /home/unicampus


    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable Nginx site
ln -sf /etc/nginx/sites-available/unicampus /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# Install Certbot for Let's Encrypt
echo "🔐 Installing Certbot..."
apt install -y certbot python3-certbot-nginx

# Setup PM2 startup
echo "🔄 Setting up PM2 startup..."
sudo -u unicampus pm2 startup systemd -u unicampus --hp /home/unicampus
# Note: Run the command that PM2 outputs

echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Copy your API files to /home/unicampus/api/"
echo "2. Create .env file with production settings"
echo "3. Install dependencies: cd /home/unicampus/api && npm install"
echo "4. Start API: pm2 start server.js --name unicampus-api"
echo "5. Setup SSL: certbot --nginx -d api.kafadarkampus.online"
echo ""
echo "🌍 Server IP: $(curl -s ifconfig.me)"
echo "📧 Point your domain A records to this IP"