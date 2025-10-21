# Ubuntu 20.04 UniCampus API Server

## ✅ SUNUCU DURUMU: KURULU VE HAZIR

**Sunucu IP:** `37.148.210.244`  
**SSH Kullanıcı:** `root`  
**Domain:** `kafadarkampus.online`  
**API URL:** `https://kafadarkampus.online/api`  
**Durum:** Aktif ve çalışıyor  
**Kurulum Tarihi:** 19 Ekim 2025

**Not:** SSH anahtarı ile bağlanıyorsunuz, şifre gerekmez.

---

## 🚀 SUNUCUYA BAĞLANMA

### Otomatik Bağlantı (Şifresiz - Önerilen)
```bash
ssh root@37.148.210.244
```
*Not: SSH anahtarı kuruldu, şifre sormaz.*

### Manuel Bağlantı (Şifre ile)
```bash
ssh root@37.148.210.244
# Şifre: Do0!Ag8#Vm8#Qh5#
```

### Windows PowerShell İçin
```powershell
# Direkt bağlan
ssh root@37.148.210.244

# Komut çalıştır ve çık
ssh root@37.148.210.244 "pm2 list"
```

---

## 📋 KURULU SİSTEMLER

✅ Ubuntu 20.04 LTS  
✅ Node.js 18.20.8  
✅ PostgreSQL (Database: kafadar)  
✅ Redis 5.0.7 (Mesajlaşma önbellek) **YENİ!**  
✅ Socket.io 4.8.1 (Anlık mesajlaşma) **YENİ!**  
✅ Nginx (Reverse Proxy)  
✅ PM2 (Process Manager)  
✅ UFW Firewall  
✅ Fail2ban  
✅ Certbot (Let's Encrypt)

---

---

## 🔄 API GÜNCELLEME (Deploy)

### Otomatik Yöntem (Önerilen):
```bash
# Lokal bilgisayardan (PowerShell)
scp -r c:\Users\METEHAN\Documents\GitHub\mobil\mobil\server\* root@37.148.210.244:/var/www/kafadar/server/

# Sunucuda güncelle
ssh root@37.148.210.244 "cd /var/www/kafadar/server && npm install && pm2 restart kafadar-api --update-env && pm2 logs kafadar-api --lines 20 --nostream"
```

### Manuel Yöntem:
```bash
# 1. Sunucuya bağlan
ssh root@37.148.210.244

# 2. API dizinine git
cd /var/www/kafadar/server

# 3. Değişiklikleri çek (eğer git kullanıyorsan)
git pull origin main

# 4. Bağımlılıkları güncelle
npm install

# 5. PM2'yi restart et
pm2 restart kafadar-api --update-env

# 6. Logları kontrol et
pm2 logs kafadar-api --lines 30 --nostream
```

### Sadece Belirli Dosyaları Güncelle:
```bash
# Redis config
scp c:\Users\METEHAN\Documents\GitHub\mobil\mobil\server\src\config\redis.js root@37.148.210.244:/var/www/kafadar/server/src/config/

# Socket.io handler
scp c:\Users\METEHAN\Documents\GitHub\mobil\mobil\server\src\socket\messageSocket.js root@37.148.210.244:/var/www/kafadar/server/src/socket/

# Server.js
scp c:\Users\METEHAN\Documents\GitHub\mobil\mobil\server\server.js root@37.148.210.244:/var/www/kafadar/server/

# Restart
ssh root@37.148.210.244 "pm2 restart kafadar-api"
```

---

## 📝 YAPILANDIRMA DOSYALARI

### .env dosyası (`/var/www/kafadar/server/.env`):
```bash
nano /var/www/kafadar/server/.env
```
İçerik:
```
PORT=3000
NODE_ENV=production
JWT_SECRET=unicampus_production_secret_2025_change_this
DB_HOST=localhost
DB_PORT=5432
DB_NAME=kafadar
DB_USER=kafadar_user
DB_PASSWORD=Kfd2025.mö
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=kafadarkampus@gmail.com
SMTP_PASSWORD=mcudupyktwseyyjf
MAIL_FROM="UniCampus <kafadarkampus@gmail.com>"

# Redis Configuration (Mesajlaşma için)
REDIS_HOST=localhost
REDIS_PORT=6379
```

---

## 🎯 SUNUCU YÖNETİMİ

### Redis Komutları:
```bash
# Redis durumu
systemctl status redis-server

# Redis'i başlat/durdur/restart
systemctl start redis-server
systemctl stop redis-server
systemctl restart redis-server

# Redis CLI
redis-cli

# Redis test
redis-cli ping  # PONG dönmeli
redis-cli SET test "hello"
redis-cli GET test

# Tüm anahtarları listele
redis-cli KEYS '*'

# Bellek kullanımı
redis-cli INFO memory
```

### PM2 Komutları:
```bash
pm2 list                    # Çalışan uygulamaları listele
pm2 logs unicampus-api      # Logları izle
pm2 restart unicampus-api   # API'yi yeniden başlat
pm2 stop unicampus-api      # API'yi durdur
pm2 start unicampus-api     # API'yi başlat
pm2 monit                   # Performans izleme
```

### Nginx Komutları:
```bash
sudo nginx -t               # Yapılandırmayı test et
sudo systemctl reload nginx # Nginx'i yeniden yükle
sudo systemctl status nginx # Nginx durumunu kontrol et
```

### PostgreSQL:
```bash
sudo -u postgres psql unicampus_dev  # Veritabanına bağlan
```

---

## 🧪 TEST

```bash
# API health check (Redis ve Socket.io dahil)
curl http://localhost:3000/health
# Beklenen: {"status":"OK","db":"connected","redis":"connected","socket":"active"}

# Public API test
curl https://kafadarkampus.online/health

# Redis test
redis-cli ping

# PostgreSQL test
sudo -u postgres psql -d kafadar -c 'SELECT COUNT(*) FROM users;'

# PM2 durumu
pm2 list

# Son loglar
pm2 logs kafadar-api --lines 50 --nostream
```

---

## 📊 MONİTORİNG

```bash
pm2 logs unicampus-api    # Logları izle
pm2 monit                 # Performance izle
htop                      # Sistem kaynaklarını izle
```

---

## 🔒 GÜVENLİK

✅ UFW firewall aktif  
✅ Fail2ban SSH koruması  
✅ Nginx reverse proxy  
✅ Non-root user (unicampus)  
✅ SSL/TLS şifreleme (Let's Encrypt)

---

## ℹ️ SİSTEM BİLGİLERİ

- **RAM:** 1GB (önerilen 2GB)
- **Storage:** 20GB+
- **CPU:** 1 vCPU
- **Bant Genişliği:** 1TB+
- **OS:** Ubuntu 20.04 LTS