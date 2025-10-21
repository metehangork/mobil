# UniCampus - Ders Arkadaşı Eşleştirme Sistemi

Bu proje, üniversite öğrencilerinin ortak aldıkları derslere göre eşleştirilmesini sağlayan bir mobil uygulama ve API sunucusudur.

## Proje Yapısı
test test test test 
### Frontend (Flutter)
- **Dil:** Dart
- **Framework:** Flutter 3.x
- **Durum Yönetimi:** flutter_bloc (BLoC pattern)
- **HTTP İstemcisi:** http package
- **Mimari:** Feature-first (clean architecture)
  - `lib/core/` - Uygulama genelinde kullanılan yapılar (config, theme, router)
  - `lib/features/` - Özellik bazlı modüller (authentication, courses, groups, messages, profile, home)
  - `lib/widgets/` - Paylaşılan UI bileşenleri

### Backend (Node.js)
- **Framework:** Express.js
- **Veritabanı:** PostgreSQL (pg driver)
- **Auth:** JWT (jsonwebtoken)
- **Email:** Nodemailer
- **Güvenlik:** helmet, cors, express-rate-limit
- **Deployment:** PM2 process manager
- **Sunucu:** 10.168.251.148:3000
- **Dosya Yapısı:**
  - `server/server.js` - Ana sunucu dosyası
  - `server/src/routes/` - API endpoint'leri (auth, chats, schools, departments)
  - `server/src/db/` - Database connection pool
  - `server/src/middleware/` - Auth middleware
  - `server/src/services/` - Email service vb.

## Önemli Özellikler

### Kimlik Doğrulama
- E-posta bazlı doğrulama (6 haneli kod)
- JWT token tabanlı oturum yönetimi
- Middleware ile protected endpoints

### Mesajlaşma
- Kullanıcılar arası 1-1 sohbet
- Kullanıcı arama endpoint'i (`/api/auth/search`)
- Real-time mesajlaşma hazırlığı (Socket.IO yüklü)
- Conversation ve message yönetimi

### Ders Yönetimi
- Okul ve bölüm seçimi
- Ders ekleme/çıkarma
- Ortak ders bazlı eşleştirme algoritması

### UI/UX
- Material Design 3
- Özel tema (AppTheme)
- Responsive tasarım
- Arama için SearchableDropdown widget'ı

## API Endpoint'leri

### Auth (`/api/auth`)
- `POST /request-verification` - E-posta doğrulama kodu gönder
- `POST /verify-code` - Kodu doğrula ve giriş yap
- `GET /me` - Mevcut kullanıcı bilgisi (JWT gerekli)
- `GET /search?q=<term>` - Kullanıcı ara (JWT gerekli)

### Chats (`/api/chats`)
- `GET /` - Tüm konuşmaları listele
- `GET /:id/messages` - Mesajları getir
- `POST /:id/messages` - Mesaj gönder
- `POST /:id/read` - Okundu işaretle
- `POST /ensure` - Konuşma oluştur/getir

### Schools & Departments
- `GET /api/schools` - Okul listesi
- `GET /api/departments` - Bölüm listesi

## Veritabanı Şeması

### users
- id, email, password_hash, first_name, last_name
- school_id, department_id, is_verified
- created_at, updated_at

### conversations
- id, user1_id, user2_id
- created_at, updated_at

### messages
- id, conversation_id, sender_id
- text, type, created_at

## Geliştirme Ortamı

### Local Backend
- `cd server && npm start` - Server'ı başlat
- PostgreSQL lokal ortamda çalışmalı
- `.env` dosyası gerekli (DB credentials, JWT secret)

### Production
- Sunucu: 10.168.251.148
- PM2 ile yönetiliyor
- SSH: `ssh root1@10.168.251.148`
- Restart: `pm2 restart unicampus-api`

### Flutter
- `flutter run` - Uygulamayı çalıştır
- `flutter build apk` - APK oluştur
- API base URL: `AppConfig.effectiveApiBaseUrl`

## Geliştirme Durumu

✅ Backend API kuruldu ve production'da çalışıyor
✅ JWT authentication implementasyonu
✅ Kullanıcı arama özelliği
✅ Mesajlaşma altyapısı
✅ Flutter temel ekranlar (auth, home, messages, profile)
⏳ Ders eşleştirme algoritması geliştiriliyor
⏳ Real-time mesajlaşma entegrasyonu
⏳ Grup sohbet özellikleri

## Kod Standartları

- **Dart:** Effective Dart guidelines
- **JavaScript:** ES6+ syntax, async/await kullan
- **Naming:** camelCase (JS/Dart), snake_case (SQL)
- **Error Handling:** Try-catch blokları ve anlamlı hata mesajları
- **Comments:** Türkçe veya İngilizce, önemli business logic'lerde zorunlu

## Basit Klasör ve Dosya Yapısı (Mobil + Arka Plan)

NOT: Sistemi ikiye ayırıyoruz: Mobil (Flutter) ve Arka Plan (Backend API). Yeni dosya/klasör eklendiğinde lütfen bu bölümü güncelleyin.

### Mobil (Flutter) - `./`
- `lib/` – Uygulamanın tüm Dart kaynak kodu
  - `lib/main.dart` – Uygulamanın giriş noktası
  - `lib/core/` – Uygulama çapında yapı ve altyapı
    - `config/` – Uygulama ayarları (örn. `app_config.dart` API URL)
    - `theme/` – Tema ve renkler
    - `router/` – Navigasyon/route tanımları
    - `models/` – Temel veri modelleri
  - `lib/features/` – Özellik bazlı modüller
    - `authentication/` – Giriş/kimlik doğrulama ekranları ve BLoC
    - `messages/` – Sohbet listesi, detay, kullanıcı arama (örn. `user_search_page.dart`)
      - `data/` – API erişimi (örn. `chat_repository.dart`, modeller)
      - `presentation/` – Ekranlar ve widget’lar
    - `courses/`, `groups/`, `profile/`, `home/`, `notifications/` – İlgili modüller
  - `lib/widgets/` – Paylaşılan UI bileşenleri (örn. `searchable_dropdown.dart`)

- `assets/` – Görseller ve fontlar (pubspec.yaml altında tanımlanmalı)
  - `assets/images/` – Uygulama görselleri (örn. `kafadar_logo.png`)
  - `assets/icons/` – İkon setleri
  - `assets/fonts/` – Özel fontlar

- `android/` – Android platform projesi (Gradle)
  - `android/app/build.gradle` – applicationId, versionCode/versionName, minSdk/targetSdk
  - `android/app/src/main/AndroidManifest.xml` – İzinler, intent-filters, activity tanımları
  - `android/gradle.properties` – AndroidX, JVM ayarları
  - `android/build.gradle`, `settings.gradle` – Proje seviyesinde Gradle yapılandırmaları
  - Not: Release imzası için `key.properties` ve keystore (varsa) burada konumlanır

- `ios/` – iOS platform projesi (Xcode)
  - `ios/Runner.xcworkspace` ve `ios/Runner.xcodeproj` – Xcode proje dosyaları
  - `ios/Runner/Info.plist` – Bundle ayarları, izin metinleri
  - `ios/Runner/AppDelegate.swift` – Uygulama yaşam döngüsü giriş noktası
  - `ios/Flutter/Generated.xcconfig` vb. – Flutter build konfig dosyaları
  - Not: Bundle Identifier, Signing & Capabilities Xcode üzerinden yönetilir

- `web/` – Web hedefi (Flutter web)
  - `web/index.html` – Kök HTML, meta/seo ayarları
  - `web/manifest.json` – PWA manifest’i, ikonlar ve adlandırma
  - Not: Renderer ve canvas-kit tercihleri gerektiğinde `index.html` üzerinden yapılandırılır

- `test/` – Flutter/Dart birim ve widget testleri
  - `test/` altındaki `*_test.dart` dosyaları
  - Çalıştırma: `flutter test` (CI entegrasyonu önerilir)

### Arka Plan (Backend API) - `./server/`
- `server/server.js` – Express uygulamasının ana dosyası
- `server/src/`
  - `routes/` – API uç noktaları
    - `auth.js` – Doğrulama ve kullanıcı işlemleri (örn. `/request-verification`, `/verify-code`, `/me`, `/search`)
    - `chats.js` – Konuşmalar ve mesaj uçları
    - `schools.js`, `departments.js` – Okul/bölüm listeleri
  - `middleware/` – Ortak ara katmanlar
    - `auth.js` – JWT doğrulama (`authenticateToken`)
  - `db/` – Veritabanı bağlantısı
    - `pool.js` – PostgreSQL pool ve `query` fonksiyonu
  - `services/` – Harici servisler
    - `emailService.js` – Nodemailer ile e-posta gönderimi
- `server/database/` – SQL ve init dosyaları (örn. `init.sql`)
- `server/logs/` – Sunucu logları
- `server/package.json` – Script’ler (örn. `pm2:restart`, `start`)

### Production Sunucu (10.168.251.148)
- Klasör: `/home/root1/server/`
  - `server.js`, `src/routes/*`, `src/middleware/*`, `src/db/*`
- Yönetim: PM2
  - `pm2 status`, `pm2 restart unicampus-api`, `pm2 logs unicampus-api`
- Dağıtım: SCP ile dosya kopyalama
  - Örnek: `scp f:/mobil/server/src/routes/auth.js root1@10.168.251.148:server/src/routes/`

## Bakım Notu (Önemli)
- Yeni her dosya/klasör eklendiğinde bu dokümanı güncelleyin.
- Mobil ve Arka Plan bölümlerinde ilgili klasör altına kısa açıklama ekleyin.
- API uç noktası değişikliklerinde hem Backend routes açıklamalarını hem de Flutter tarafındaki ilgili repository/sayfa dosya yollarını buraya yazın.