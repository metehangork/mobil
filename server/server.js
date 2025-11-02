
//server sunucuda yüklü ssh ile bağlan 
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const http = require('http');
require('dotenv').config();
const { query } = require('./src/db/pool');

const authRoutes = require('./src/routes/auth');
const schoolsRoutes = require('./src/routes/schools');
const departmentsRoutes = require('./src/routes/departments');
const chatsRoutes = require('./src/routes/chats');
const conversationsRoutes = require('./src/routes/conversations');
const messagesRoutes = require('./src/routes/messages');
const usersRoutes = require('./src/routes/users');
const matchesRoutes = require('./src/routes/matches');
const groupsRoutes = require('./src/routes/groups');
const notificationsRoutes = require('./src/routes/notifications');
const coursesRoutes = require('./src/routes/courses');

// FCM Service (try-catch ile optional)
let fcmService = null;
try {
  fcmService = require('./src/services/fcmService');
} catch (err) {
  console.warn('⚠️ FCM service bulunamadı, push notification devre dışı');
}

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

// Trust proxy (Nginx reverse proxy için gerekli)
app.set('trust proxy', 1);

// Middleware
app.use(helmet());
// CORS: DEBUG_CORS=1 ise gelen origin'i otomatik kabul et (sadece lokal debug için!)
if (process.env.DEBUG_CORS === '1') {
  app.use(cors({ origin: true, credentials: true }));
  console.warn('⚠️  DEBUG_CORS=1 aktif. Tüm originlere izin veriliyor (sadece geliştirme için).');
} else {
  app.use(cors({
    origin: ['http://localhost:8080', 'http://localhost:3000', 'https://kafadarkampus.online'],
    credentials: true
  }));
}

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 100, // maksimum 100 request
  message: 'Çok fazla istek gönderildi, lütfen daha sonra tekrar deneyin.',
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  // Nginx proxy arkasında gerçek IP'yi al
  keyGenerator: (req) => {
    return req.ip || req.headers['x-forwarded-for'] || req.connection.remoteAddress;
  }
});
app.use(limiter);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/schools', schoolsRoutes);
app.use('/api/departments', departmentsRoutes);
app.use('/api/chats', chatsRoutes);
app.use('/api/conversations', conversationsRoutes);
app.use('/api/messages', messagesRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/matches', matchesRoutes);
app.use('/api/groups', groupsRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/courses', coursesRoutes);

// Health check
app.get('/health', async (req, res) => {
  try {
    const dbRes = await query('SELECT 1 as ok');
    
    // Redis durumunu kontrol et
    let redisStatus = 'disconnected';
    try {
      const { redisClient } = require('./src/config/redis');
      if (redisClient.isOpen) {
        await redisClient.ping();
        redisStatus = 'connected';
      }
    } catch (e) {
      redisStatus = 'disconnected';
    }
    
    res.json({
      status: 'OK',
      db: dbRes.rows[0].ok === 1 ? 'connected' : 'unknown',
      redis: redisStatus,
      socket: io ? 'active' : 'inactive',
      timestamp: new Date().toISOString(),
      service: 'UniCampus API',
      version: '1.0.0'
    });
  } catch (e) {
    res.status(500).json({ status: 'ERROR', db: 'disconnected', error: e.message });
  }
});

// Lightweight ping (DB yok, sadece canlılık)
app.get('/ping', (req, res) => {
  res.json({ pong: true, time: Date.now() });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint bulunamadı',
    path: req.originalUrl
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Sunucu hatası',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// HTTP server oluştur (Socket.io için gerekli)
const server = http.createServer(app);

// Socket.io'yu başlat (Redis kullanıyor olabilir, önce Redis'i dene)
let io = null;
(async () => {
  try {
    // Redis bağlantısını dene
    const { redisClient } = require('./src/config/redis');
    await redisClient.connect();
    console.log('✅ Redis bağlantısı başarılı');

    // Firebase Cloud Messaging (FCM) başlat
    if (fcmService) {
      try {
        fcmService.initialize();
        console.log('✅ FCM servisi başlatıldı');
      } catch (fcmError) {
        console.warn('⚠️ FCM initialization hatası:', fcmError.message);
      }
    }

    // Socket.io'yu başlat
    const initializeSocket = require('./src/socket/messageSocket');
    io = initializeSocket(server);
    console.log('✅ Socket.io mesajlaşma sistemi hazır');
    console.log('💬 Anlık mesajlaşma sistemi aktif!');
  } catch (error) {
    console.warn('⚠️  Redis bağlantısı başarısız, Socket.io devre dışı:', error.message);
    console.warn('   -> Mesajlaşma sadece REST API ile çalışacak');
  }
})();

server.listen(PORT, HOST, () => {
  console.log(`🚀 UniCampus API sunucusu http://${HOST}:${PORT} adresinde çalışıyor`);
  console.log(`📚 Ders arkadaşı eşleştirme sistemi hazır!`);
  // PostgreSQL ilk bağlantı testi (sunucu açılışında hemen dene)
  (async () => {
    try {
      const r = await query('SELECT 1 as ok');
      if (r.rows[0].ok === 1) {
        console.log('✅ PostgreSQL bağlantı testi başarılı');
      } else {
        console.log('⚠️ PostgreSQL bağlantı testi beklenmeyen sonuç döndü');
      }
    } catch (e) {
      console.error('❌ PostgreSQL bağlantı testi başarısız:', e.message);
      console.error('   -> Lütfen PostgreSQL servisinin çalıştığını ve .env bilgilerini doğrulayın');
    }
  })();
});