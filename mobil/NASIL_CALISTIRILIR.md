# 🚀 Kafadar Kampüs - Uygulamayı Çalıştırma Rehberi

## Emülatör Başlatma

Emülatörü açmak için PowerShell'de şu komutu çalıştırın:

```powershell
$env:ANDROID_HOME = "C:\Users\METEHAN\AppData\Local\Android\Sdk"
Start-Process -FilePath "$env:ANDROID_HOME\emulator\emulator.exe" -ArgumentList "-avd", "Medium_Phone_API_36.1" -WindowStyle Normal
```

## VS Code ile Çalıştırma (EN KOLAY)

1. **VS Code'u açın**
2. Proje klasörünü açın: `c:\Users\METEHAN\Documents\GitHub\mobil\mobil`
3. Sol alttaki cihaz seçiciyi tıklayın ve emülatörü seçin
4. **F5** tuşuna basın veya **Run > Start Debugging**
5. Uygulama otomatik derlenip emülatöre yüklenecek! ✅

## Android Studio ile Çalıştırma

1. Android Studio'yu açın
2. **Open Existing Project** ile proje klasörünü seçin
3. Sağ üstteki yeşil Play butonuna tıklayın
4. Emülatörü seçin ve Run'a basın

## Manuel APK Oluşturma

Eğer manuel APK oluşturmak isterseniz:

```powershell
# Proje klasörüne git
cd c:\Users\METEHAN\Documents\GitHub\mobil\mobil

# Debug APK oluştur
flutter build apk --debug

# APK konumu:
# build\app\outputs\flutter-apk\app-debug.apk
```

## APK'yı Emülatöre Yükleme

```powershell
$env:ANDROID_HOME = "C:\Users\METEHAN\AppData\Local\Android\Sdk"
& "$env:ANDROID_HOME\platform-tools\adb.exe" install -r build\app\outputs\flutter-apk\app-debug.apk
```

## Cihazları Kontrol Etme

```powershell
$env:ANDROID_HOME = "C:\Users\METEHAN\AppData\Local\Android\Sdk"
& "$env:ANDROID_HOME\platform-tools\adb.exe" devices
```

Çıktı:
```
List of devices attached
emulator-5554   device    ✅ HAZIR
```

## Sorun Giderme

### Flutter bulunamıyor hatası
- Flutter SDK path'ini sistem PATH'ine ekleyin
- Veya VS Code Flutter extension'ını kullanın

### Git bulunamıyor hatası
- Git'i yükleyin: https://git-scm.com
- PATH'e ekleyin: `C:\Program Files\Git\cmd`

### JAVA_HOME hatası
```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
```

### Emülatör açılmıyor
- Android Studio'dan emülatörü manuel başlatın
- Veya yukarıdaki emülatör başlatma komutunu kullanın

## API Endpoint Ayarı

Uygulama varsayılan olarak şu API'ye bağlanır:
```
http://37.148.210.244:3000
```

Değiştirmek için: `lib/core/config/api_config.dart`

---

## 🎯 ÖNERİLEN YÖNTEM: VS CODE + F5

En kolay ve hızlı yöntem VS Code kullanmak:

1. ✅ Emülatörü başlat (yukarıdaki PowerShell komutu)
2. ✅ VS Code'u aç
3. ✅ F5'e bas
4. ✅ Uygulama çalışsın! 🎉

**Hot Reload:** Kod değişikliklerinde `r` tuşuna basın  
**Hot Restart:** `R` (büyük R) tuşuna basın  
**Çıkış:** `q` tuşuna basın

---

## Yapılan Entegrasyonlar

### ✅ Tamamlandı:
- **AuthBloc** - Gerçek API ile giriş/kayıt
- **ProfileBloc** - Kullanıcı profili
- **API Services** - 10 adet servis (Auth, User, Course, Match, Group, vb.)
- **ServiceLocator** - Dependency injection

### ⏳ Devam Eden:
- Messages, Courses, Groups, Home, Notifications sayfaları

Backend: http://37.148.210.244:3000 ✅ ONLINE
