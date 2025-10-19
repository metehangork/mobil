# Ubuntu 20.04 UniCampus API Server Kurulum Rehberi

## Hızlı Kurulum (5 dakika)

### 1) Natro'dan server aldıktan sonra:
```bash
# SSH ile bağlan
ssh root@YOUR_SERVER_IP

# Setup scriptini çalıştır
wget https://raw.githubusercontent.com/your-repo/ubuntu-setup.sh
chmod +x ubuntu-setup.sh
sudo bash ubuntu-setup.sh
```

### 2) API dosyalarını yükle:
```bash
# Local'den server'a kopyala
scp -r f:/mobil/server/* unicampus@YOUR_SERVER_IP:/home/unicampus/api/

# Server'da
ssh unicampus@YOUR_SERVER_IP
cd ~/api
npm install
```

### 3) .env ayarla:
```bash
nano .env
```
İçerik:
```
PORT=3000
NODE_ENV=production
JWT_SECRET=unicampus_production_secret_2025_change_this
DB_HOST=localhost
DB_PORT=5432
DB_NAME=unicampus_dev
DB_USER=unicampus
DB_PASSWORD=Kfd2025.mö
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=kafadarkampus@gmail.com
SMTP_PASSWORD=mcudupyktwseyyjf
MAIL_FROM="UniCampus <kafadarkampus@gmail.com>"
```

### 4) API'yi başlat:
```bash
pm2 start server.js --name unicampus-api
pm2 save
pm2 startup  # sistem boot'ta otomatik başlat
```

### 5) Domain ayarla:
**DNS Records (Natro veya domain provider):**
```
A     api.kafadarkampus.online    YOUR_SERVER_IP
A     kafadarkampus.online        YOUR_SERVER_IP  (opsiyonel)
```

### 6) SSL sertifikası:
```bash
sudo certbot --nginx -d api.kafadarkampus.online -d kafadarkampus.online
```

### 7) Test:
```bash
curl https://api.kafadarkampus.online/api/auth/request-verification \
  -H "Content-Type: application/json" \
  -d '{"email":"metehangork@gmail.com"}'
```

## Avantajlar:
✅ Gmail SMTP direkt çalışır  
✅ Tam performans kontrolü  
✅ Kolay SSL (Let's Encrypt)  
✅ PM2 native support  
✅ Nginx reverse proxy  
✅ PostgreSQL native  
✅ cPanel kısıtlamaları yok  

## Sistem Gereksinimleri:
- **RAM:** 1GB (önerilen 2GB)
- **Storage:** 20GB+
- **CPU:** 1 vCPU
- **Bant Genişliği:** 1TB+

## Monitoring:
```bash
pm2 logs unicampus-api    # Logları izle
pm2 monit                 # Performance izle
htop                      # Sistem kaynaklarını izle
```

## Güvenlik:
- UFW firewall aktif
- Fail2ban SSH koruması
- Nginx reverse proxy
- Non-root user (unicampus)
- SSL/TLS şifreleme