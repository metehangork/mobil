# UniCampus - Ders Arkadaşı Eşleştirme Sistemi

Üniversite öğrencilerinin ortak aldıkları derslere göre eşleştirilmesini sağlayan mobil uygulama ve backend API.

## 📁 Proje Yapısı

```
f:\mobil\
├── lib/                    # Flutter mobil uygulama
│   ├── core/
│   │   ├── models/         # Veri modelleri
│   │   ├── theme/          # UI tema ve renkler
│   │   └── router/         # Navigasyon yapılandırması
│   └── features/
│       ├── authentication/ # Giriş/çıkış ve kayıt
│       ├── profile/        # Kullanıcı profili
│       ├── course_matching/# Ders eşleştirme
│       └── home/          # Ana sayfa
├── server/                 # Backend API sunucusu
│   ├── src/
│   │   ├── routes/        # API route'ları
│   │   ├── db/           # Veritabanı bağlantısı
│   │   └── middleware/   # Express middleware'leri
│   ├── database/         # PostgreSQL schema
│   ├── server.js         # Ana server dosyası
│   └── package.json      # Server dependencies
├── android/              # Android platform dosyları
├── ios/                  # iOS platform dosyaları
├── web/                  # Web platform dosyaları
└── assets/              # Statik dosyalar (images, fonts)
```

## 🛠️ Teknoloji Stack

### Mobil Uygulama
- **Flutter 3.24+** - Cross-platform framework
- **BLoC State Management** - Reactive state management
- **Go Router** - Declarative routing
- **Material Design 3** - Modern UI components
- **HTTP Client** - API komunikasyonu

### Backend API
- **Node.js + Express** - RESTful API sunucusu
- **PostgreSQL** - İlişkisel veritabanı
- **JWT Authentication** - Güvenli oturum yönetimi
- **PM2** - Process management
- **CORS & Helmet** - Güvenlik middleware'leri

## 🚀 Hızlı Başlangıç

### Server Başlat
```bash
cd server
pm2 start server.js --name unicampus-api
```

### Mobil Uygulamayı Çalıştır
```bash
flutter run -d chrome
# veya
flutter run -d [DEVICE_ID]
```

### Health Check
```bash
curl http://192.168.1.180:3000/health
```

## 📊 Sistem Durumu
- ✅ **Backend API:** PM2 ile çalışıyor
- ✅ **PostgreSQL:** Bağlantı aktif  
- ✅ **Authentication:** JWT token sistemi
- ✅ **Mobile App:** Cross-platform desteği

## Uygulama İsmi ve Logo

Yeni marka: "Kafadar Kampüs"

Logo ekleme:
- Proje köküne gelen logo dosyasını `assets/images/kafadar_logo.png` olarak kopyalayın.
- `pubspec.yaml` içinde `assets/images/` zaten listelenmiş olmalı; yoksa ekleyin.

Kullanım örneği (Flutter):

```dart
import 'package:your_app/widgets/app_logo.dart';

AppBar(
	title: Row(
		children: [
			const AppLogo(size: 40),
			const SizedBox(width: 8),
			const Text('Kafadar Kampüs'),
		],
	),
)
```

Android/iOS gösterilen isimler güncellendi (AndroidManifest.xml, Info.plist). Uygulamayı tekrar derleyip çalıştırdığınızda yeni isim ve logo görünmelidir.

---
**Son Güncelleme:** 27.09.2025 - Temiz mimari uygulandı