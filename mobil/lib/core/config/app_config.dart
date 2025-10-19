import 'dart:io';

class AppConfig {
  // Production API URL
  static const String productionApiBaseUrl = 'https://kafadarkampus.online/api';
  
  // Development/Test sunucu IP'leri
  static const List<String> _developmentServerIPs = [
    'http://192.168.1.143:3000', // Eski ev ağı IP
    'http://10.168.251.148:3000',  // Kampüs ağı IP
  ];

  // Ana API Base URL - Production'da çalışıyoruz!
  // Kullanım: flutter run --dart-define=API_BASE_URL=http://192.168.0.25:3000
  static String get effectiveApiBaseUrl {
    // 1. Öncelik: Build/run zamanında verilen değer (development için)
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // 2. Production: Gerçek sunucu URL'i kullan
    return productionApiBaseUrl;
  }

  // Kısa isim (courses_service için)
  static String get apiBaseUrl => effectiveApiBaseUrl;
  
  // Development server IP'lerini döndür (fallback için kullanılabilir)
  static List<String> get developmentServerIPs => _developmentServerIPs;

  static bool get isEmulator {
    // Android emulator veya iOS simulator kontrolü
    return Platform.environment['SIMULATOR_DEVICE_NAME'] != null ||
        Platform.environment['ANDROID_EMULATOR_AUDIO'] != null;
  }
}
