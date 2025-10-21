@echo off
REM Kafadar Kampus - Flutter Run Script

echo ========================================
echo   Kafadar Kampus - Uygulama Baslatiyor
echo ========================================
echo.

REM Environment variables
set ANDROID_HOME=C:\Users\METEHAN\AppData\Local\Android\Sdk
set JAVA_HOME=C:\Program Files\Android\Android Studio\jbr
set PATH=%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\tools;%JAVA_HOME%\bin;C:\flutter\bin;%PATH%

REM Check emulator
echo Emulator kontrol ediliyor...
adb devices
echo.

REM Run Flutter app
echo Flutter uygulamasi baslatiliyor...
cd /d "%~dp0"
flutter run --dart-define=API_BASE_URL=http://37.148.210.244:3000

echo.
echo Uygulama baslatildi!
pause
