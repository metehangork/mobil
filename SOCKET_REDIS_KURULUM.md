# 🚀 Socket.io + Redis Mesajlaşma Sistemi - Kurulum Rehberi

## 📦 Gereksinimler

### 1. Node.js Kurulumu
- **İndir:** https://nodejs.org/ (LTS sürüm - 20.x)
- Yükle ve bilgisayarı **yeniden başlat**
- Test: `node --version` ve `npm --version`

### 2. Redis Kurulumu (Windows)

#### Yöntem 1: Chocolatey ile (Önerilen)
```powershell
# Chocolatey yüklü değilse önce onu yükle
# https://chocolatey.org/install

# Redis'i yükle
choco install redis-64

# Redis'i başlat
redis-server
```

#### Yöntem 2: Manuel Kurulum
1. İndir: https://github.com/tporadowski/redis/releases
2. `redis-server.exe` çalıştır
3. Test: Yeni terminalde `redis-cli` → `ping` → `PONG` görmeli

---

## 🔧 Backend Kurulumu

### 1. Paketleri Yükle
```powershell
cd c:\Users\METEHAN\Documents\GitHub\mobil\mobil\server
npm install socket.io redis@4.6.7
```

### 2. .env Dosyasını Kontrol Et
```env
# .env dosyasına ekle (yoksa)
REDIS_HOST=localhost
REDIS_PORT=6379
```

### 3. Redis'i Başlat
Ayrı bir terminal penceresinde:
```powershell
redis-server
```

### 4. Backend'i Başlat
```powershell
cd c:\Users\METEHAN\Documents\GitHub\mobil\mobil\server
npm start
# veya geliştirme için
npm run dev
```

**Başarılı çıktı:**
```
✅ Redis bağlantısı başarılı
✅ Socket.io mesajlaşma sistemi hazır
🚀 UniCampus API sunucusu http://0.0.0.0:3000 adresinde çalışıyor
💬 Anlık mesajlaşma sistemi aktif!
✅ PostgreSQL bağlantı testi başarılı
```

---

## 📱 Flutter Kurulumu

### 1. Paketleri Yükle
```bash
cd c:\Users\METEHAN\Documents\GitHub\mobil\mobil
flutter pub get
```

### 2. Socket Servisini Kullan

#### main.dart'a ekle (Uygulama başlarken):
```dart
import 'package:unicampus/core/services/socket_service.dart';

void main() {
  runApp(MyApp());
  
  // Uygulama kapanırken
  WidgetsBinding.instance.addObserver(
    LifecycleEventHandler(
      resumeCallBack: () async {},
      suspendingCallBack: () async {
        SocketService().dispose();
      },
    ),
  );
}
```

#### Mesajlaşma ekranında kullan:
```dart
import 'package:unicampus/core/services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    
    // Backend sunucu adresinizi yazın
    final serverUrl = 'http://192.168.1.5:3000'; // IP'nizi değiştirin!
    final currentUserId = 'USER_ID_BURAYA';
    
    SocketService().connect(serverUrl, currentUserId);
    
    // Mesaj dinle
    SocketService().messageStream.listen((event) {
      if (event['type'] == 'new_message') {
        // Yeni mesaj geldi, UI'yi güncelle
        setState(() {
          messages.add(event['data']);
        });
      }
    });
  }
  
  void sendMessage(String content) {
    SocketService().sendMessage(
      senderId: currentUserId,
      receiverId: receiverUserId,
      content: content,
    );
  }
}
```

**Tam örnek için:** `lib/core/services/socket_example.dart` dosyasına bakın!

---

## 🧪 Test Etme

### 1. Backend Testi
```bash
# Sunucu çalışıyor mu?
curl http://localhost:3000/health

# Beklenen çıktı:
# {"status":"OK","db":"connected",...}
```

### 2. Redis Testi
```bash
redis-cli
> SET test "hello"
> GET test
# Çıktı: "hello"
```

### 3. Flutter Test
1. Backend ve Redis çalışıyor olmalı
2. `socket_example.dart` dosyasındaki IP'yi değiştir
3. Flutter uygulamasını çalıştır
4. İki cihaz/emülatör arasında mesaj gönder

---

## 🔍 Sorun Giderme

### ❌ "npm: The term 'npm' is not recognized"
**Çözüm:** Node.js'i yükle ve bilgisayarı yeniden başlat

### ❌ "Redis connection failed"
**Çözüm:** 
1. `redis-server` çalışıyor mu kontrol et
2. Port 6379 kullanımda mı: `netstat -ano | findstr :6379`
3. Redis servisini yeniden başlat

### ❌ "Socket connection timeout"
**Çözüm:**
1. Backend sunucusu çalışıyor mu? → `http://localhost:3000/health`
2. Flutter'daki IP adresi doğru mu? (192.168.1.X gibi)
3. Firewall/Antivirus port 3000'i engelliyor mu?

### ❌ "CORS Error"
**Çözüm:** `server.js` içinde CORS ayarlarını kontrol et veya `.env` dosyasına ekle:
```env
DEBUG_CORS=1
```

---

## 📊 Sistem Mimarisi

```
┌─────────────┐      WebSocket      ┌──────────────┐
│   Flutter   │ ←─────────────────→ │   Socket.io  │
│  (Mobil)    │                     │  (Backend)   │
└─────────────┘                     └──────────────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
                    ▼                      ▼                      ▼
            ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
            │    Redis     │      │  PostgreSQL  │      │   Express    │
            │  (Hız/Cache) │      │   (Kalıcı)   │      │  (REST API)  │
            └──────────────┘      └──────────────┘      └──────────────┘
```

### Veri Akışı:
1. **Kullanıcı mesaj gönderir** → Flutter
2. **Socket.io emit** → Backend
3. **PostgreSQL'e kaydet** → Kalıcı veri
4. **Redis'te alıcı çevrimiçi mi kontrol et** → Hızlı
5. **Socket.io ile alıcıya ilet** → Anlık
6. **Flutter UI güncelle** → Mesaj görünür

---

## 📝 Oluşturulan Dosyalar

### Backend:
- ✅ `server/src/config/redis.js` - Redis bağlantı ve yardımcı fonksiyonlar
- ✅ `server/src/socket/messageSocket.js` - Socket.io mesajlaşma mantığı
- ✅ `server/server.js` - Express + Socket.io entegrasyonu

### Flutter:
- ✅ `lib/core/services/socket_service.dart` - Socket.io client servisi
- ✅ `lib/core/services/socket_example.dart` - Örnek kullanım

### Diğer:
- ✅ `pubspec.yaml` - socket_io_client paketi eklendi
- ✅ `package.json` - socket.io ve redis paketleri eklendi

---

## 🎯 Sonraki Adımlar

1. ✅ Node.js'i yükle
2. ✅ Redis'i yükle ve başlat
3. ✅ `npm install` çalıştır
4. ✅ Backend'i başlat
5. ✅ Flutter paketlerini güncelle
6. ✅ IP adresini düzenle
7. ✅ Uygulamayı test et

---

## 💡 Önemli Notlar

- **Production'da:**
  - Socket.io CORS'u spesifik domainlere kısıtla
  - Redis için şifre ekle
  - Environment variable'ları kullan
  - Rate limiting ekle

- **Performans:**
  - Redis sayesinde çevrimiçi durumu çok hızlı
  - Mesaj önbellekleme ile veritabanı sorguları azalır
  - WebSocket ile polling'e göre %90 daha az kaynak

- **Güvenlik:**
  - JWT token ile Socket.io authentication eklenebilir
  - Mesaj şifreleme eklenebilir
  - Rate limiting ile spam önlenebilir

---

## 📞 Yardım

Sorun yaşarsan:
1. Konsol loglarını kontrol et (hem backend hem Flutter)
2. Redis ve PostgreSQL çalışıyor mu kontrol et
3. Firewall/antivirus ayarlarını kontrol et
4. IP adreslerini doğrula

**Başarılar! 🚀**
