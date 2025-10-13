const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();
const { query } = require('./src/db/pool');

const authRoutes = require('./src/routes/auth');
const emailRoutes = require('./src/routes/emailRoutes');
const schoolsRoutes = require('./src/routes/schools');
const departmentsRoutes = require('./src/routes/departments');
const chatsRoutes = require('./src/routes/chats');

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

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
  message: 'Çok fazla istek gönderildi, lütfen daha sonra tekrar deneyin.'
});
app.use(limiter);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/email', emailRoutes);
app.use('/api/schools', schoolsRoutes);
app.use('/api/departments', departmentsRoutes);
app.use('/api/chats', chatsRoutes);

// Health check
app.get('/health', async (req, res) => {
  try {
    const dbRes = await query('SELECT 1 as ok');
    res.json({
      status: 'OK',
      db: dbRes.rows[0].ok === 1 ? 'connected' : 'unknown',
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

app.listen(PORT, () => {
  console.log(`🚀 UniCampus API sunucusu http://localhost:${PORT} adresinde çalışıyor`);
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