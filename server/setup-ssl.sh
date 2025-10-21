#!/bin/bash
# Kafadar Kampüs - Nginx + SSL Kurulum Script
# Alan Adı: kafadarkampus.online

echo "=========================================="
echo "  Kafadar Kampüs - SSL Kurulum"
echo "  Domain: kafadarkampus.online"
echo "=========================================="

# 1. Nginx Kurulumu
echo "📦 Nginx kuruluyor..."
sudo apt update
sudo apt install -y nginx

# 2. Certbot (Let's Encrypt) Kurulumu
echo "🔐 Certbot kuruluyor..."
sudo apt install -y certbot python3-certbot-nginx

# 3. Nginx Konfigürasyon Dosyası Oluştur
echo "⚙️ Nginx konfigürasyonu oluşturuluyor..."
sudo tee /etc/nginx/sites-available/kafadarkampus.online > /dev/null <<'EOF'
# Kafadar Kampüs - Nginx Configuration
# HTTP to HTTPS Redirect
server {
    listen 80;
    listen [::]:80;
    server_name kafadarkampus.online www.kafadarkampus.online;

    # Let's Encrypt doğrulama için
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # Tüm trafiği HTTPS'e yönlendir
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS Server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name kafadarkampus.online www.kafadarkampus.online;

    # SSL Sertifikaları (Certbot tarafından otomatik eklenecek)
    # ssl_certificate /etc/letsencrypt/live/kafadarkampus.online/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/kafadarkampus.online/privkey.pem;
    # include /etc/letsencrypt/options-ssl-nginx.conf;
    # ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # CORS Headers (API için gerekli)
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, PATCH, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Authorization, Content-Type, Accept' always;

    # Root Location - API Proxy
    location /api {
        proxy_pass http://localhost:3000/api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeout ayarları
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Socket.io için WebSocket desteği
    location /socket.io {
        proxy_pass http://localhost:3000/socket.io;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket için timeout
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }

    # Health Check
    location /health {
        proxy_pass http://localhost:3000/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }

    # Ana sayfa (opsiyonel - şimdilik API bilgisi göster)
    location = / {
        return 200 '{"message":"Kafadar Kampüs API","version":"1.0.0","status":"online","docs":"/api"}';
        add_header Content-Type application/json;
    }

    # Dosya upload limiti
    client_max_body_size 10M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;

    # Access ve Error Logları
    access_log /var/log/nginx/kafadarkampus.online.access.log;
    error_log /var/log/nginx/kafadarkampus.online.error.log;
}
EOF

# 4. Nginx Konfigürasyonunu Aktif Et
echo "🔗 Nginx konfigürasyonu aktif ediliyor..."
sudo ln -sf /etc/nginx/sites-available/kafadarkampus.online /etc/nginx/sites-enabled/

# 5. Varsayılan Nginx sayfasını devre dışı bırak
sudo rm -f /etc/nginx/sites-enabled/default

# 6. Nginx Syntax Kontrolü
echo "✅ Nginx konfigürasyon kontrolü..."
sudo nginx -t

# 7. Nginx Restart
echo "🔄 Nginx yeniden başlatılıyor..."
sudo systemctl restart nginx
sudo systemctl enable nginx

# 8. Firewall Ayarları
echo "🔥 Firewall ayarları yapılıyor..."
sudo ufw allow 'Nginx Full'
sudo ufw allow 'OpenSSH'
sudo ufw --force enable

# 9. SSL Sertifikası Al (Let's Encrypt)
echo "🔐 SSL sertifikası alınıyor..."
echo ""
echo "ÖNEMLİ: SSL sertifikası almak için DNS ayarlarının yapılmış olması gerekir!"
echo "DNS'de şu kayıtların olduğundan emin olun:"
echo "  A Record: kafadarkampus.online -> 37.148.210.244"
echo "  A Record: www.kafadarkampus.online -> 37.148.210.244"
echo ""
read -p "DNS ayarları yapıldı mı? (y/n): " dns_ready

if [ "$dns_ready" = "y" ] || [ "$dns_ready" = "Y" ]; then
    echo "SSL sertifikası alınıyor..."
    sudo certbot --nginx -d kafadarkampus.online -d www.kafadarkampus.online --non-interactive --agree-tos --email admin@kafadarkampus.online --redirect
    
    # 10. Otomatik Yenileme Testi
    echo "🔄 SSL otomatik yenileme testi..."
    sudo certbot renew --dry-run
    
    echo ""
    echo "=========================================="
    echo "✅ KURULUM TAMAMLANDI!"
    echo "=========================================="
    echo ""
    echo "🌐 Domain: https://kafadarkampus.online"
    echo "📡 API: https://kafadarkampus.online/api"
    echo "❤️ Health: https://kafadarkampus.online/health"
    echo "🔌 Socket: wss://kafadarkampus.online/socket.io"
    echo ""
    echo "🔐 SSL Sertifikası: ✅ Aktif"
    echo "🔄 Otomatik Yenileme: ✅ Aktif (90 günde bir)"
    echo ""
    echo "Test etmek için:"
    echo "  curl https://kafadarkampus.online/health"
    echo ""
else
    echo ""
    echo "⚠️ DNS ayarlarını yaptıktan sonra şu komutu çalıştırın:"
    echo "  sudo certbot --nginx -d kafadarkampus.online -d www.kafadarkampus.online"
    echo ""
    echo "DNS ayarları (domain sağlayıcınızda):"
    echo "  A Record: kafadarkampus.online -> 37.148.210.244"
    echo "  A Record: www.kafadarkampus.online -> 37.148.210.244"
    echo ""
    echo "DNS yayılması 5-30 dakika sürebilir."
    echo "Kontrol için: nslookup kafadarkampus.online"
fi

echo "=========================================="
echo "📝 Notlar:"
echo "- SSL sertifikası 90 gün geçerli"
echo "- Otomatik yenileme ayarlandı (certbot)"
echo "- Nginx logları: /var/log/nginx/"
echo "- PM2 logları: pm2 logs kafadar-api"
echo "=========================================="
