const express = require('express');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();
const { query } = require('./src/db/pool');

// Redis ve Socket.io importları
const { redisClient } = require('./src/config/redis');
const initializeSocket = require('./src/socket/messageSocket');

// Mevcut route'lar
const authRoutes = require('./src/routes/auth');
const schoolsRoutes = require('./src/routes/schools');
const departmentsRoutes = require('./src/routes/departments');
const coursesRoutes = require('./src/routes/courses');
const usersRoutes = require('./src/routes/users');
const matchesRoutes = require('./src/routes/matches');
// Mesajlaşma route'ları
const messagesRoutes = require('./src/routes/messages');
const conversationsRoutes = require('./src/routes/conversations');

const app = express();
const server = http.createServer(app);
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

// Middleware
app.use(helmet());

// Trust proxy (Nginx arkasında çalıştığı için)
app.set('trust proxy', 1);

// CORS
if (process.env.DEBUG_CORS === '1') {
  app.use(cors({ origin: true, credentials: true }));
  console.warn('⚠️  DEBUG_CORS=1 aktif. Tüm originlere izin veriliyor (sadece geliştirme için).');
} else {
  app.use(cors({
    origin: function (origin, callback) {
      if (!origin) return callback(null, true);

      const allowed = [
        'http://localhost:8080',
        'http://localhost:3000',
        'https://kafadarkampus.online',
        'http://kafadarkampus.online'
      ];

      if (allowed.indexOf(origin) !== -1) {
        return callback(null, true);
      }

      console.warn('CORS blocked origin:', origin);
      return callback(new Error('Not allowed by CORS'));
    },
    credentials: true
  }));
}

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Çok fazla istek gönderildi, lütfen daha sonra tekrar deneyin.',
  standardHeaders: true,
  legacyHeaders: false
});
app.use(limiter);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Redis bağlantısını başlat
(async () => {
  try {
    await redisClient.connect();
    console.log('✅ Redis bağlantısı başarılı');
  } catch (error) {
    console.error('❌ Redis bağlantı hatası:', error.message);
    console.error('   -> Redis kurulu değilse: apt install redis-server');
    console.error('   -> Redis çalışmıyorsa devam edilecek (bazı özellikler devre dışı)');
  }
})();

// Socket.io'yu başlat
const io = initializeSocket(server);
console.log('✅ Socket.io mesajlaşma sistemi hazır');

// Socket.io instance'ını app'e ekle (route'larda kullanmak için)
app.set('io', io);

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/schools', schoolsRoutes);
app.use('/api/departments', departmentsRoutes);
app.use('/api/courses', coursesRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/matches', matchesRoutes);
app.use('/api/messages', messagesRoutes);
app.use('/api/conversations', conversationsRoutes);

// Health check
app.get('/health', async (req, res) => {
  try {
    const dbRes = await query('SELECT 1 as ok');
    
    // Redis durumunu kontrol et
    let redisStatus = 'disconnected';
    try {
      if (redisClient.isOpen) {
        await redisClient.ping();
        redisStatus = 'connected';
      }
    } catch (e) {
      redisStatus = 'error';
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

// Lightweight ping
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

server.listen(PORT, HOST, () => {
  console.log(`🚀 UniCampus API sunucusu http://${HOST}:${PORT} adresinde çalışıyor`);
  console.log(`📚 Ders arkadaşı eşleştirme sistemi hazır!`);
  console.log(`💬 Anlık mesajlaşma sistemi aktif!`);
  
  // PostgreSQL ilk bağlantı testi
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
