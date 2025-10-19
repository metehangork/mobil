# UniCampus Mail Relay Endpoint

Bu klasör `api.kafadarkampus.online` sunucusuna yüklenecek.

## Kurulum Adımları

### 1) Dosyaları yükle
cPanel File Manager ile şu dosyaları `/home/yourusername/public_html/` (veya subdomain root) altına yükle:
- `send-mail.php`
- `composer.json`

### 2) PHPMailer kur
cPanel > Terminal (veya SSH varsa):
```bash
cd /home/yourusername/public_html
composer install
```

Terminal yoksa cPanel > PHP Composer aracını kullan veya PHPMailer'ı manuel indir:
```bash
wget https://github.com/PHPMailer/PHPMailer/archive/refs/tags/v6.9.1.zip
unzip v6.9.1.zip
mv PHPMailer-6.9.1 vendor/phpmailer/phpmailer
```

### 3) Doküman kökünü doğrula ve sağlık testi
cPanel > Subdomains ekranında `api.kafadarkampus.online` için Document Root yolunu not edin (ör: `/home/USER/public_html/api`).

- Bu klasöre `send-mail.php` ve `vendor/` klasörünü yerleştirin.
- `health.txt` dosyasını da aynı dizine koyup tarayıcıda açın:
  - http://api.kafadarkampus.online/health.txt → `ok` görmelisiniz.

HTTPS henüz yoksa, önce HTTP ile test edin; SSL kurulduktan sonra HTTPS'e geçin.

### 4) Test
```bash
curl -X POST http://api.kafadarkampus.online/send-mail.php \
  -H "Content-Type: application/json" \
  -H "X-API-Key: unicampus_secret_2025_change_this" \
  -d '{"to":"test@example.com","subject":"Test Mail","body":"<p>Test içerik</p>"}'
```

Başarılı yanıt:
```json
{"sent":true,"messageId":"msg_...","to":"test@example.com","timestamp":"2025-10-11T..."}
```

SSL kurulduktan sonra URL'yi HTTPS yapın.

### 5) Ana sunucuda .env güncelle
212.58.14.118 sunucusunda `~/server/.env`:
```
RELAY_MAIL_URL=http://api.kafadarkampus.online/send-mail.php
RELAY_API_KEY=unicampus_secret_2025_change_this
```

### 6) .htaccess ile koruma (opsiyonel - önce çalışsın sonra ekle)
**UYARI:** .htaccess dosyası bazen 404/405 hatalarına sebep olabilir. Önce relay'in çalıştığından emin olun, sonra `.htaccess.sample`'ı `.htaccess` olarak kopyalayıp test edin. Sorun çıkarsa .htaccess'i silin.

### 7) emailService.js güncelle ve PM2 restart
```bash
cd ~/server
# emailService.js'i güncelle (HTTP relay desteği mevcut)
npm run pm2:restart -- --update-env
```

### 8) API Test
```bash
curl -X POST http://212.58.14.118:3000/api/auth/request-verification \
  -H "Content-Type: application/json" \
  -d '{"email":"metehangork@gmail.com"}'
```

## Güvenlik Notları
- `send-mail.php` içindeki `$apiKey` değerini güçlü bir şifreyle değiştir
- `.env` dosyasındaki `RELAY_API_KEY` ile aynı olmalı
- Rate limiting eklemek için PHP tarafında basit kontrol eklenebilir

## Sorun Giderme
- 401 Unauthorized → API key yanlış
- 500 Error → PHPMailer kurulmamış veya Gmail şifresi yanlış
- SMTP hatası → Gmail App Password kullan (2FA aktif olmalı)
