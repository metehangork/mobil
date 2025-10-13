# UniCampus API - cPanel Deployment Guide

## Önkoşullar
- cPanel hosting hesabı
- Node.js App support (cPanel → Setup Node.JS App)
- MySQL database

## Adım 1: cPanel'de Node.js App Oluştur
1. cPanel → "Setup Node.JS App"
2. "Create Application"
   - Node.js Version: 18.x veya üzeri
   - Application Mode: Production
   - Application Root: `api` (veya istediğin klasör)
   - Application URL: `kafadarkampus.online/api`
   - Application Startup File: `server.js`

## Adım 2: Database Oluştur
1. cPanel → "MySQL Databases"
2. Database oluştur: `username_unicampus`
3. User oluştur ve database'e assign et
4. Privileges: ALL

## Adım 3: Dosyaları Upload Et
Aşağıdaki dosyaları cPanel File Manager ile `/api` klasörüne yükle:

```
api/
├── server.js
├── package.json
├── .env
└── src/
    ├── db/
    │   ├── adapter.js
    │   └── init-mysql.sql
    └── routes/
        ├── auth.js
        ├── users.js
        ├── courses.js
        └── matches.js
```

## Adım 4: Environment Variables (.env)
```env
NODE_ENV=production
PORT=3000
HOST=127.0.0.1

# MySQL Database
DB_HOST=localhost
DB_USER=username_dbuser
DB_PASSWORD=your_password
DB_NAME=username_unicampus
DB_PORT=3306

# JWT Secret
JWT_SECRET=your_super_secret_key_here

# CORS
CORS_ORIGINS=https://kafadarkampus.online
```

## Adım 5: Dependencies Install
Terminal (cPanel → Terminal):
```bash
cd ~/public_html/api
npm install --production
```

## Adım 6: Database Init
MySQL'de tabloları oluştur:
```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## Adım 7: App'i Başlat
cPanel → Setup Node.JS App → "Restart App"

## Test
- Browser: `https://yourdomain.com/api/ping`
- Response: `{"pong":true,"time":...}`

## Flutter App Update
```dart
// lib/core/config/app_config.dart
static const String defaultApiBaseUrl = 'https://kafadarkampus.online/api';
```

## Troubleshooting
- Logs: cPanel → Setup Node.JS App → "Open App"
- Errors: Check logs and .env file
- Port: cPanel otomatik assign eder
- SSL: Let's Encrypt ile ücretsiz SSL