const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { body, validationResult } = require('express-validator');
const { query } = require('../db/pool');
const router = express.Router();

// Geçici memory verification (ileride Redis)
const verificationStore = new Map();

// Debug için store durumunu kontrol
function debugStore() {
  console.log('📋 Store içeriği:', Array.from(verificationStore.entries()));
}

async function findUserByEmail(email) {
  const result = await query('SELECT * FROM users WHERE email = $1 LIMIT 1', [email]);
  return result.rows[0];
}

async function createUser(email) {
  const university = email.split('@')[1] || '';
  const result = await query(
    `INSERT INTO users (email, password_hash, first_name, last_name, is_verified)
     VALUES ($1, '', '', '', true)
     ON CONFLICT (email) DO UPDATE SET updated_at = NOW()
     RETURNING *`,
    [email]
  );
  return result.rows[0];
}

// E-posta doğrulama isteği - tüm e-postalara izin ver
router.post('/request-verification', [
  body('email').isEmail().withMessage('Geçerli e-posta adresi giriniz')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  const { email } = req.body;
  
  // 6 haneli rastgele kod oluştur
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  
  // Store'a kaydet (1 saat geçerli)
  verificationStore.set(email, { code, expiresAt: Date.now() + 60 * 60 * 1000 });
  
  // E-posta gönder
  try {
    const { sendMail } = require('../services/emailService');
    await sendMail({
      to: email,
      subject: 'UniCampus - E-posta Doğrulama Kodu',
      text: `Merhaba,\n\nUniCampus hesabınızı doğrulamak için kod: ${code}\n\nBu kod 1 saat geçerlidir.\n\nİyi günler,\nUniCampus Ekibi`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
          <h2 style="color: #2563eb;">UniCampus E-posta Doğrulama</h2>
          <p>Merhaba,</p>
          <p>UniCampus hesabınızı doğrulamak için aşağıdaki kodu kullanın:</p>
          <div style="background-color: #f3f4f6; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 5px; margin: 20px 0;">
            ${code}
          </div>
          <p style="color: #6b7280; font-size: 14px;">Bu kod 1 saat geçerlidir.</p>
          <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 20px 0;">
          <p style="color: #9ca3af; font-size: 12px;">Bu e-postayı siz talep etmediyseniz, lütfen dikkate almayın.</p>
        </div>
      `
    });
    console.log(`📧 Doğrulama kodu gönderildi (${email}): ${code}`);
    res.json({ message: 'Doğrulama kodu e-posta adresinize gönderildi', email });
  } catch (emailError) {
    console.error('❌ E-posta gönderilemedi:', emailError);
    // Yine de kodu kaydet, log'dan bakılabilir
    console.log(`📧 [FALLBACK] Doğrulama kodu (${email}): ${code}`);
    res.json({ message: 'Doğrulama kodu oluşturuldu (e-posta gönderilemedi)', email, code });
  }
});

// Kod doğrulama
router.post('/verify-code', [
  body('email').isEmail(),
  body('code').isLength({ min: 6, max: 6 })
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  const { email, code } = req.body;
  console.log(`🔍 Kod doğrulama: email=${email}, code=${code}`);
  debugStore();
  const record = verificationStore.get(email);
  if (!record) {
    console.log(`❌ Kod bulunamadı: ${email}`);
    return res.status(400).json({ error: 'Kod bulunamadı' });
  }
  if (record.expiresAt < Date.now()) {
    verificationStore.delete(email);
    return res.status(400).json({ error: 'Kod süresi doldu' });
  }
  if (record.code !== code) return res.status(400).json({ error: 'Geçersiz kod' });

  // Debug için kodu silme, tekrar kullanılabilir olsun
  console.log('✅ Kod doğru, mock user ile devam');

  // DB yok ise mock user döndür
  let user;
  try {
    user = await findUserByEmail(email);
    if (!user) {
      user = await createUser(email);
    }
  } catch (dbError) {
    console.log('⚠️ DB unavailable, using mock user');
    user = {
      id: 'mock_' + Date.now(),
      email: email,
      first_name: email.split('@')[0],
      last_name: '',
      is_verified: true
    };
  }

  const token = jwt.sign(
    { userId: user.id, email: user.email },
    process.env.JWT_SECRET || 'development_secret',
    { expiresIn: '7d' }
  );

  res.json({
    message: 'Giriş başarılı',
    token,
    user: {
      id: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      isVerified: user.is_verified
    }
  });
});

// Token doğrulama middleware
const { authenticateToken } = require('../middleware/auth');

router.get('/me', authenticateToken, async (req, res) => {
  const user = await query('SELECT id, email, first_name, last_name, is_verified FROM users WHERE id = $1', [req.user.userId]);
  if (!user.rows[0]) return res.status(404).json({ error: 'Kullanıcı yok' });
  const u = user.rows[0];
  res.json({ id: u.id, email: u.email, firstName: u.first_name, lastName: u.last_name, isVerified: u.is_verified });
});

// Kullanıcı arama - JWT gerekli
router.get('/search', authenticateToken, async (req, res) => {
  try {
    const { q } = req.query;
    
    if (!q || q.trim().length < 2) {
      return res.status(400).json({ error: 'En az 2 karakter giriniz' });
    }
    
    const searchPattern = `%${q.trim()}%`;
    const result = await query(
      `SELECT id, email, first_name, last_name, school_id, created_at
       FROM users
       WHERE is_verified = true
         AND id != $1
         AND (email ILIKE $2 OR first_name ILIKE $2 OR last_name ILIKE $2)
       ORDER BY email
       LIMIT 20`,
      [req.user.userId, searchPattern]
    );
    
    res.json({ users: result.rows });
  } catch (error) {
    console.error('❌ Kullanıcı arama hatası:', error);
    res.status(500).json({ error: 'Arama yapılamadı' });
  }
});

module.exports = router;