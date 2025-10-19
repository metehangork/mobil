# 🔥 SOCKET.IO + REDIS KURULUM HATALARI VE ÇÖZÜMLER

## ⚠️ YAPILAN HATALAR VE ÖĞRENİLENLER

### ❌ HATA 1: Yanlış Dizine Dosya Yükleme

**Hata:**
```bash
# YANLIŞ - Lokal geliştirme dizini
scp dosya.js root@sunucu:/home/unicampus/api/
```

**Sorun:** 
- Sunucuda API `/var/www/kafadar/server/` dizininde çalışıyordu
- PM2 `/var/www/kafadar/server/server.js` dosyasını çalıştırıyordu
- Ben `/home/unicampus/api/` dizinine yüklüyordum

**Çözüm:**
```bash
# PM2'deki çalışan dizini bul
ssh root@37.148.210.244 "pm2 show kafadar-api | grep script"
# Çıktı: script path: /var/www/kafadar/server/server.js

# DOĞRU dizine yükle
scp dosya.js root@37.148.210.244:/var/www/kafadar/server/
```

**Öğrenilen:**
✅ Önce `pm2 show APP_NAME` ile çalışan uygulamanın dizinini bul
✅ O dizine dosyaları yükle

---

### ❌ HATA 2: Lokal Bilgisayarda Node.js Test Etme

**Hata:**
```bash
cd c:\Users\METEHAN\Documents\GitHub\mobil\mobil\server
node --version
# Hata: node is not recognized
```

**Sorun:**
- Lokal Windows bilgisayarda Node.js yüklü değil
- Ama sunucuda Node.js VAR ve ÇALIŞIYOR!
- Lokal bilgisayara Node.js yüklemeye gerek YOK

**Çözüm:**
```bash
# Sunucuyu kontrol et
ssh root@37.148.210.244 "node --version"
# Çıktı: v18.20.8 ✅

# Tüm işlemleri sunucuda yap
ssh root@37.148.210.244 "cd /var/www/kafadar/server && npm install socket.io redis"
```

**Öğrenilen:**
✅ Sunucu projesiyse LOKAL bilgisayara Node.js yükleme
✅ Tüm komutları `ssh root@sunucu "komut"` ile çalıştır
✅ Lokal sadece kod editörü olarak kullan

---

### ❌ HATA 3: Var Olmayan Route'ları Import Etme

**Hata:**
```javascript
// server.js içinde
const emailRoutes = require('./src/routes/emailRoutes');
const chatsRoutes = require('./src/routes/chats');

app.use('/api/email', emailRoutes);
app.use('/api/chats', chatsRoutes);
```

**Sorun:**
```bash
# Sunucuda bu dosyalar YOK
ls /var/www/kafadar/server/src/routes/
# Çıktı: auth.js, courses.js, departments.js, matches.js, schools.js, users.js
# emailRoutes.js ve chats.js YOK!
```

**Hata Mesajı:**
```
Error: Cannot find module './src/routes/emailRoutes'
```

**Çözüm:**
```javascript
// Sadece MEVCUT route'ları import et
const authRoutes = require('./src/routes/auth');
const schoolsRoutes = require('./src/routes/schools');
const departmentsRoutes = require('./src/routes/departments');
const coursesRoutes = require('./src/routes/courses');
const usersRoutes = require('./src/routes/users');
const matchesRoutes = require('./src/routes/matches');

// Var olmayanları import ETME!
// const emailRoutes = require('./src/routes/emailRoutes'); // ❌ YOK
// const chatsRoutes = require('./src/routes/chats'); // ❌ YOK
```

**Öğrenilen:**
✅ Sunucuya dosya göndermeden önce `ls` ile dosyaların varlığını kontrol et
✅ Lokal geliştirme dosyalarını sunucu ile karıştırma
✅ Sunucudaki mevcut yapıya uyumlu kod yaz

---

### ❌ HATA 4: Redis Kurulmadan Paket Yükleme

**Hata:**
```bash
# Önce npm paketini yükle
npm install redis

# Sonra Redis'i kullanmaya çalış
# Hata: Redis connection refused
```

**Sorun:**
- Redis npm paketi yüklü AMA Redis SERVER yüklü değil!
- npm `redis` = JavaScript client (bağlantı kütüphanesi)
- `redis-server` = Gerçek Redis veritabanı

**Çözüm:**
```bash
# 1. Önce Redis SERVER'ı kur
ssh root@37.148.210.244 "apt-get update && apt-get install -y redis-server"

# 2. Redis'i başlat
ssh root@37.148.210.244 "systemctl start redis-server && systemctl enable redis-server"

# 3. Test et
ssh root@37.148.210.244 "redis-cli ping"
# Çıktı: PONG ✅

# 4. SONRA npm paketini yükle
ssh root@37.148.210.244 "cd /var/www/kafadar/server && npm install redis@4.6.7"
```

**Öğrenilen:**
✅ npm redis ≠ Redis server
✅ Önce sunucuya Redis kur, sonra npm paketini ekle
✅ `redis-cli ping` ile test et

---

### ❌ HATA 5: .env Dosyasını Güncellemeden Yeniden Başlatma

**Hata:**
```bash
# Redis kuruldu, npm paketleri yüklendi
pm2 restart kafadar-api

# Kod Redis'e bağlanmaya çalışıyor
# Ama .env'de REDIS_HOST ve REDIS_PORT YOK!
```

**Çözüm:**
```bash
# .env'ye Redis ayarlarını ekle
ssh root@37.148.210.244 "cd /var/www/kafadar/server && echo '' >> .env && echo '# Redis Configuration' >> .env && echo 'REDIS_HOST=localhost' >> .env && echo 'REDIS_PORT=6379' >> .env"

# SONRA yeniden başlat
ssh root@37.148.210.244 "pm2 restart kafadar-api --update-env"
```

**Öğrenilen:**
✅ Yeni environment variable ekleyince `--update-env` kullan
✅ .env değişikliklerinden sonra mutlaka restart et
✅ Restart öncesi .env içeriğini `tail -5 .env` ile kontrol et

---

### ❌ HATA 6: Trust Proxy Ayarı Eksik

**Hata:**
```
ValidationError: The 'X-Forwarded-For' header is set but the Express 'trust proxy' setting is false
```

**Sorun:**
- Nginx reverse proxy arkasında çalışıyor
- Express varsayılan olarak proxy'lere güvenmiyor
- Rate limiting IP adresini doğru algılayamıyor

**Çözüm:**
```javascript
// server.js içinde
const app = express();

// Trust proxy (Nginx arkasında çalıştığı için)
app.set('trust proxy', 1);

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false  // Yeni header formatı kullan
});
```

**Öğrenilen:**
✅ Nginx/Apache arkasında çalışıyorsa `trust proxy` ekle
✅ Rate limiting'de `standardHeaders: true` kullan
✅ Production'da proxy yapılandırması şart

---

### ❌ HATA 7: Veritabanı Adını Yanlış Bilme

**Hata:**
```bash
# Yanlış veritabanı adı
psql -d unicampus_dev
# Hata: database "unicampus_dev" does not exist
```

**Sorun:**
- Lokal geliştirme veritabanı: `unicampus_dev`
- Sunucu veritabanı: `kafadar`
- İkisi farklı!

**Çözüm:**
```bash
# Önce veritabanlarını listele
ssh root@37.148.210.244 "sudo -u postgres psql -c '\l' | grep -i kafadar"

# Doğru veritabanı adını kullan
ssh root@37.148.210.244 "sudo -u postgres psql -d kafadar -c '\dt'"
```

**Öğrenilen:**
✅ `.env` dosyasını kontrol et → `DB_NAME=kafadar`
✅ Sunucu ve lokal farklı veritabanı isimleri kullanabilir
✅ `psql -c '\l'` ile önce listeyi gör

---

### ❌ HATA 8: Socket.io CORS Hatası

**Sorun:**
```javascript
// Sadece backend CORS ayarı yeterli DEĞİL!
app.use(cors({ origin: '*' }));

// Socket.io'nun kendi CORS ayarı lazım
```

**Çözüm:**
```javascript
const io = new Server(server, {
  cors: {
    origin: '*', // Geliştirme için
    // Production'da:
    // origin: ['https://kafadarkampus.online', 'https://app.kafadarkampus.online'],
    methods: ['GET', 'POST'],
    credentials: true
  }
});
```

**Öğrenilen:**
✅ Socket.io'nun kendi CORS ayarı var
✅ Express CORS ≠ Socket.io CORS
✅ İkisini de ayrı ayrı ayarla

---

## 🎯 DOĞRU KURULUM SIRASI

### 1️⃣ Sunucuya Bağlan ve Ortamı Kontrol Et
```bash
# Sunucuya bağlan
ssh root@37.148.210.244

# Node.js versiyonunu kontrol et
node --version

# PM2 uygulamasını bul
pm2 list

# Çalışma dizinini öğren
pm2 show kafadar-api | grep script
```

### 2️⃣ Redis Sunucuyu Kur
```bash
# Redis'i kur
apt-get update
apt-get install -y redis-server

# Başlat
systemctl start redis-server
systemctl enable redis-server

# Test et
redis-cli ping  # PONG görmeli
```

### 3️⃣ Gerekli Dizinleri Oluştur
```bash
# Çalışma dizinine git
cd /var/www/kafadar/server

# Dizinleri oluştur
mkdir -p src/config src/socket
```

### 4️⃣ Dosyaları Lokal'den Sunucuya Yükle
```bash
# Windows PowerShell'den
scp redis.js root@37.148.210.244:/var/www/kafadar/server/src/config/
scp messageSocket.js root@37.148.210.244:/var/www/kafadar/server/src/socket/
scp server.js root@37.148.210.244:/var/www/kafadar/server/
```

### 5️⃣ npm Paketlerini Yükle
```bash
ssh root@37.148.210.244 "cd /var/www/kafadar/server && npm install socket.io redis@4.6.7"
```

### 6️⃣ .env Dosyasını Güncelle
```bash
ssh root@37.148.210.244 "cd /var/www/kafadar/server && echo '' >> .env && echo 'REDIS_HOST=localhost' >> .env && echo 'REDIS_PORT=6379' >> .env"
```

### 7️⃣ PM2 ile Yeniden Başlat
```bash
ssh root@37.148.210.244 "pm2 restart kafadar-api --update-env"
```

### 8️⃣ Logları Kontrol Et
```bash
ssh root@37.148.210.244 "pm2 logs kafadar-api --lines 30 --nostream"
```

### 9️⃣ Health Check ile Test Et
```bash
ssh root@37.148.210.244 "curl -s http://localhost:3000/health"
# Beklenen:
# {"status":"OK","db":"connected","redis":"connected","socket":"active"}
```

---

## 📋 KONTROL LİSTESİ

### Sunucu Hazırlığı:
- [x] SSH ile bağlanabiliyorum
- [x] Node.js yüklü (v18+)
- [x] PM2 çalışıyor
- [x] PostgreSQL çalışıyor
- [x] Çalışma dizinini biliyorum

### Redis Kurulumu:
- [x] Redis server yüklü
- [x] Redis başlatıldı
- [x] `redis-cli ping` çalışıyor
- [x] Otomatik başlatma aktif

### Dosya Yükleme:
- [x] src/config/redis.js yüklendi
- [x] src/socket/messageSocket.js yüklendi
- [x] server.js güncellendi
- [x] Doğru dizine yüklendi (/var/www/kafadar/server)

### npm Paketleri:
- [x] socket.io@4.8.1 yüklü
- [x] redis@4.6.7 yüklü
- [x] package.json güncellendi

### Konfigürasyon:
- [x] .env'de REDIS_HOST var
- [x] .env'de REDIS_PORT var
- [x] trust proxy ayarlandı
- [x] CORS ayarlandı (hem Express hem Socket.io)

### Test:
- [x] PM2 restart başarılı
- [x] Logda "Redis bağlantısı başarılı" var
- [x] Logda "Socket.io mesajlaşma sistemi hazır" var
- [x] /health endpoint'i "redis":"connected" dönüyor
- [x] /health endpoint'i "socket":"active" dönüyor

---

## 🚫 YAPILMAMASI GEREKENLER

### ❌ Lokal Bilgisayarda:
- ❌ Node.js yüklemeye çalışma (sunucu projesi)
- ❌ npm install çalıştırma (sunucuda yap)
- ❌ Lokal test sunucusu başlatma
- ❌ Lokal veritabanı oluşturma

### ❌ Dosya Yükleme:
- ❌ Yanlış dizine yükleme
- ❌ Var olmayan route'ları import etme
- ❌ Lokal geliştirme dosyalarını sunucuya kopyalama

### ❌ Konfigürasyon:
- ❌ .env güncellemeden restart yapma
- ❌ Trust proxy ayarını unutma (Nginx arkasında)
- ❌ Socket.io CORS'unu unutma

### ❌ Test:
- ❌ Redis kurulmadan npm redis yükleme
- ❌ Restart yapmadan test etme
- ❌ Log kontrol etmeden "çalışıyor" deme

---

## 💡 PRO İPUÇLARI

### 1. Her Zaman Önce Kontrol Et
```bash
# Dizin varlığı
ssh root@sunucu "ls -la /path/to/dir"

# Dosya varlığı
ssh root@sunucu "cat /path/to/file | head -10"

# Servis durumu
ssh root@sunucu "systemctl status redis-server"

# PM2 durumu
ssh root@sunucu "pm2 show app-name"
```

### 2. Log Takibi
```bash
# Canlı log izleme
ssh root@sunucu "pm2 logs app-name"

# Son 50 satır
ssh root@sunucu "pm2 logs app-name --lines 50 --nostream"

# Sadece hataları
ssh root@sunucu "pm2 logs app-name --err --lines 30 --nostream"
```

### 3. Yedekleme
```bash
# Dosya değiştirmeden önce yedekle
ssh root@sunucu "cp /var/www/app/server.js /var/www/app/server.js.backup"

# Sorun olursa geri al
ssh root@sunucu "cp /var/www/app/server.js.backup /var/www/app/server.js"
ssh root@sunucu "pm2 restart app-name"
```

### 4. Test Komutları
```bash
# Redis test
ssh root@sunucu "redis-cli ping"
ssh root@sunucu "redis-cli SET test hello"
ssh root@sunucu "redis-cli GET test"

# PostgreSQL test
ssh root@sunucu "sudo -u postgres psql -d dbname -c 'SELECT 1;'"

# API test
ssh root@sunucu "curl -s http://localhost:3000/health | jq"
```

---

## 📚 İLGİLİ DOSYALAR

- `SOCKET_REDIS_KURULUM.md` → Detaylı kurulum rehberi
- `DATABASE_STRUCTURE.md` → Veritabanı tablo yapısı
- `ubuntu-deployment.md` → Sunucu bilgileri
- `server/src/config/redis.js` → Redis yapılandırması
- `server/src/socket/messageSocket.js` → Socket.io mantığı

---

**Tarih:** 19 Ekim 2025  
**Son Güncelleme:** Tüm hatalar çözüldü, sistem çalışıyor ✅
