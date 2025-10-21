# 📝 PROJE NOTLARI - HIZLI ERİŞİM

**Tarih:** 19 Ekim 2025  
**Proje:** UniCampus - Ders Arkadaşı Eşleştirme & Mesajlaşma Sistemi

---

## 🎯 ÖNEMLİ BİLGİLER

### Sunucu Bilgileri:
```
IP: 37.148.210.244
Domain: kafadarkampus.online
API URL: https://kafadarkampus.online
SSH: ssh root@37.148.210.244
```

### Çalışma Dizinleri:
```
API Dizini: /var/www/kafadar/server/
Veritabanı: kafadar (PostgreSQL)
PM2 App: kafadar-api
```

### Teknolojiler:
```
Backend: Node.js 18.20.8, Express
Veritabanı: PostgreSQL (38 tablo)
Cache: Redis 5.0.7
WebSocket: Socket.io 4.8.1
Process Manager: PM2
Web Server: Nginx
Frontend: Flutter
```

---

## 📚 ÖNEMLİ DOSYALAR

### 1. **HATALAR_VE_COZUMLER.md** 🔥
**Ne zaman oku:** Hata aldığında veya kurulum yapmadan ÖNCE!

**İçerik:**
- ✅ Yapılan 8 büyük hata ve çözümleri
- ✅ Lokal vs Sunucu farkı
- ✅ Doğru kurulum sırası
- ✅ Kontrol listesi
- ✅ Yapılmaması gerekenler

**Önemli Hatalar:**
- Yanlış dizine dosya yükleme
- Lokal bilgisayarda Node.js test etme
- Var olmayan route'ları import etme
- .env güncellemeden restart yapma

---

### 2. **SOCKET_REDIS_KURULUM.md** 📦
**Ne zaman oku:** Socket.io ve Redis kurulumu yapacaksan

**İçerik:**
- ✅ Adım adım kurulum (Backend + Flutter)
- ✅ Redis kurulumu (Windows + Linux)
- ✅ Socket.io entegrasyonu
- ✅ Flutter client kullanımı
- ✅ Test komutları
- ✅ Sorun giderme

**Test Komutu:**
```bash
curl https://kafadarkampus.online/health
# Beklenen: {"redis":"connected","socket":"active"}
```

---

### 3. **DATABASE_STRUCTURE.md** 📊
**Ne zaman oku:** Veritabanı tabloları hakkında bilgi lazımsa

**İçerik:**
- ✅ 38 tablo detaylı açıklama
- ✅ Mesajlaşma tabloları (messages, conversations, participants)
- ✅ Kullanıcı sistemi (users, profiles, settings)
- ✅ Eşleştirme sistemi (matches, preferences)
- ✅ Socket.io uyumluluk analizi
- ✅ Foreign key ilişkileri

**Önemli Tablolar:**
- messages → 17 sütun (tam özellikli!)
- conversations → Grup/direct desteği
- conversation_participants → Okundu bilgisi
- users → 27 sütun

---

### 4. **ubuntu-deployment.md** 🚀
**Ne zaman oku:** Sunucuya deploy yapacaksan veya sunucu yönetimi

**İçerik:**
- ✅ Sunucu bilgileri
- ✅ SSH bağlantı
- ✅ PM2 komutları
- ✅ Redis komutları
- ✅ Nginx yapılandırması
- ✅ Deploy adımları
- ✅ .env konfigürasyonu

**Hızlı Deploy:**
```bash
scp -r server\* root@37.148.210.244:/var/www/kafadar/server/
ssh root@37.148.210.244 "cd /var/www/kafadar/server && npm install && pm2 restart kafadar-api"
```

---

## 🚨 HATA ALDIĞINDA

### 1. Önce Logları Kontrol Et:
```bash
ssh root@37.148.210.244 "pm2 logs kafadar-api --lines 50 --nostream"
```

### 2. Sistem Durumunu Kontrol Et:
```bash
# PM2
ssh root@37.148.210.244 "pm2 list"

# Redis
ssh root@37.148.210.244 "redis-cli ping"

# PostgreSQL
ssh root@37.148.210.244 "sudo -u postgres psql -d kafadar -c 'SELECT 1;'"

# Health Check
curl https://kafadarkampus.online/health
```

### 3. HATALAR_VE_COZUMLER.md dosyasına bak!

### 4. Restart Dene:
```bash
ssh root@37.148.210.244 "pm2 restart kafadar-api --update-env"
```

---

## 🎯 SIKÇA YAPILAN HATALAR

### ❌ YANLIŞ:
```bash
# Lokal bilgisayarda Node.js kurmaya çalışma
node --version  # ❌ Sunucu projesi!

# Yanlış dizine yükleme
scp file.js root@sunucu:/home/unicampus/api/  # ❌ Yanlış dizin!

# .env güncellemeden restart
pm2 restart app  # ❌ --update-env unutma!

# Var olmayan route import
require('./src/routes/emailRoutes')  # ❌ Dosya yok!
```

### ✅ DOĞRU:
```bash
# Sunucuda kontrol et
ssh root@37.148.210.244 "node --version"  # ✅

# Doğru dizine yükle
scp file.js root@37.148.210.244:/var/www/kafadar/server/  # ✅

# .env ile restart
pm2 restart app --update-env  # ✅

# Önce dosya varlığını kontrol et
ssh root@sunucu "ls src/routes/"  # ✅
```

---

## 📋 HIZLI KOMUTLAR

### Sunucuya Bağlan:
```bash
ssh root@37.148.210.244
```

### Logları İzle:
```bash
ssh root@37.148.210.244 "pm2 logs kafadar-api"
```

### Health Check:
```bash
curl https://kafadarkampus.online/health
```

### Redis Test:
```bash
ssh root@37.148.210.244 "redis-cli ping"
```

### PM2 Restart:
```bash
ssh root@37.148.210.244 "pm2 restart kafadar-api --update-env"
```

### Dosya Yükle:
```bash
scp file.js root@37.148.210.244:/var/www/kafadar/server/
```

---

## 🔍 DOSYA YAPISI

```
server/
├── HATALAR_VE_COZUMLER.md      ← ⭐ ÖNCE BUNU OKU!
├── SOCKET_REDIS_KURULUM.md     ← Socket.io kurulum rehberi
├── DATABASE_STRUCTURE.md       ← Veritabanı yapısı
├── ubuntu-deployment.md        ← Sunucu yönetimi
├── README.md                   ← Bu dosya
├── server.js                   ← Ana sunucu dosyası
├── package.json                ← npm paketleri
├── .env                        ← Konfigürasyon (SAKLA!)
└── src/
    ├── config/
    │   └── redis.js            ← Redis yapılandırması
    ├── socket/
    │   └── messageSocket.js    ← Socket.io mesajlaşma
    ├── db/
    │   └── pool.js             ← PostgreSQL bağlantısı
    └── routes/
        ├── auth.js
        ├── schools.js
        ├── departments.js
        ├── courses.js
        ├── users.js
        └── matches.js
```

---

## 🎓 ÖĞRENİLENLER

### 1. **Sunucu vs Lokal Farkı:**
- Sunucu projesi → Lokal'de Node.js'e gerek YOK
- Tüm işlemler SSH ile sunucuda yapılır
- Lokal sadece kod editörü

### 2. **Dizin Yapısı Önemli:**
- PM2 hangi dizinde çalışıyor → `pm2 show app-name`
- O dizine dosya yükle
- Yanlış dizin = dosya çalışmaz

### 3. **npm vs Sistem Paketi:**
- `npm install redis` → JavaScript client
- `apt install redis-server` → Redis veritabanı
- İkisi FARKLI şeyler!

### 4. **Environment Variables:**
- .env değişince `--update-env` ile restart
- .env değişikliği → restart gerekli
- Hassas bilgiler .env'de (git'e ekleme!)

### 5. **Testing:**
- Her değişiklikten sonra test et
- Health endpoint kullan
- Logları kontrol et

---

## 📞 SORUN YAŞARSAN

1. **Logları Kontrol Et** → `pm2 logs`
2. **HATALAR_VE_COZUMLER.md'ye Bak** → Muhtemelen orada var
3. **Health Check Yap** → Hangi servis çalışmıyor?
4. **Restart Dene** → `pm2 restart --update-env`
5. **Dosya Varlığını Kontrol Et** → `ls -la`

---

## ✅ SİSTEM DURUMU

```
✅ PostgreSQL: 38 tablo, çalışıyor
✅ Redis: 5.0.7, çalışıyor
✅ Socket.io: 4.8.1, çalışıyor
✅ API: Online (kafadarkampus.online)
✅ PM2: kafadar-api running
✅ Nginx: Reverse proxy aktif
```

---

**Son Güncelleme:** 19 Ekim 2025  
**Durum:** Tüm sistemler çalışıyor ✅
