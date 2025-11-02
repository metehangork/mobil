const express = require('express');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const { query } = require('../db/pool');
const router = express.Router();

// Geçici memory verification (ileride Redis)
const verificationStore = new Map();
const emailCooldown = new Map(); // E-posta gönderim limiti için

// Debug için store durumunu kontrol
function debugStore() {
  console.log('📋 Store içeriği:', Array.from(verificationStore.entries()));
}

// E-posta cooldown kontrolü (60 saniye)
function checkEmailCooldown(email) {
  const lastSent = emailCooldown.get(email);
  if (lastSent) {
    const timePassed = Date.now() - lastSent;
    const cooldownTime = 60 * 1000; // 60 saniye
    if (timePassed < cooldownTime) {
      const remainingSeconds = Math.ceil((cooldownTime - timePassed) / 1000);
      return { allowed: false, remainingSeconds };
    }
  }
  return { allowed: true };
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

// Şifre ile giriş endpoint'i
router.post('/login', [
  body('email').isEmail().withMessage('Geçerli e-posta adresi giriniz'),
  body('password').notEmpty().withMessage('Şifre gerekli')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { email, password } = req.body;
  console.log(`🔐 Login isteği: ${email}`);

  try {
    // Kullanıcıyı bul
    const user = await findUserByEmail(email);
    
    if (!user) {
      console.log(`❌ Kullanıcı bulunamadı: ${email}`);
      return res.status(401).json({ error: 'E-posta veya şifre hatalı' });
    }

    // Şifre kontrolü (basit string karşılaştırma - production'da bcrypt kullan)
    if (user.password_hash !== password) {
      console.log(`❌ Şifre hatalı: ${email}`);
      return res.status(401).json({ error: 'E-posta veya şifre hatalı' });
    }

    // JWT token oluştur
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      process.env.JWT_SECRET || 'development_secret',
      { expiresIn: '7d' }
    );

    console.log(`✅ Login başarılı: ${email}`);
    res.json({
      message: 'Giriş başarılı',
      token,
      user: {
        id: user.id,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        school_id: user.school_id,
        department_id: user.department_id
      }
    });
  } catch (error) {
    console.error('❌ Login error:', error);
    res.status(500).json({ error: 'Giriş sırasında bir hata oluştu' });
  }
});

// Kayıt endpoint'i (şifre ile)
router.post('/register', [
  body('email').isEmail().withMessage('Geçerli e-posta adresi giriniz'),
  body('password').isLength({ min: 6 }).withMessage('Şifre en az 6 karakter olmalı'),
  body('firstName').notEmpty().withMessage('Ad gerekli'),
  body('lastName').notEmpty().withMessage('Soyad gerekli'),
  body('schoolId').optional().isInt(),
  body('departmentId').optional().isInt()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { email, password, firstName, lastName, schoolId, departmentId } = req.body;
  console.log(`📝 Kayıt isteği: ${email}`);

  try {
    // Kullanıcı zaten var mı?
    const existingUser = await findUserByEmail(email);
    if (existingUser) {
      console.log(`❌ E-posta zaten kayıtlı: ${email}`);
      return res.status(400).json({ error: 'Bu e-posta adresi zaten kayıtlı' });
    }

    // Yeni kullanıcı oluştur (şifreyi düz text olarak kaydet - production'da bcrypt kullan)
    const result = await query(
      `INSERT INTO users (email, password_hash, first_name, last_name, school_id, department_id, is_verified)
       VALUES ($1, $2, $3, $4, $5, $6, false)
       RETURNING id, email, first_name, last_name, school_id, department_id`,
      [email, password, firstName, lastName, schoolId || null, departmentId || null]
    );

    const user = result.rows[0];

    console.log(`✅ Kayıt başarılı: ${email} (Okul: ${schoolId}, Bölüm: ${departmentId})`);
    
    // Email doğrulama kodu oluştur ve gönder
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store'a kaydet (1 saat geçerli)
    verificationStore.set(email, { 
      code, 
      expiresAt: Date.now() + 60 * 60 * 1000,
      type: 'email_verification',
      userId: user.id
    });
    
    // E-posta gönder
    try {
      const { sendMail } = require('../services/emailService');
      await sendMail({
        to: email,
        subject: 'UniCampus - E-posta Doğrulama',
        text: `Merhaba ${firstName},\n\nUniCampus hesabınızı doğrulamak için kod: ${code}\n\nBu kod 1 saat geçerlidir.\n\nİyi günler,\nUniCampus Ekibi`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <h2 style="color: #2563eb;">UniCampus'e Hoş Geldin!</h2>
            <p>Merhaba ${firstName},</p>
            <p>UniCampus hesabınızı doğrulamak için aşağıdaki kodu kullanın:</p>
            <div style="background-color: #eff6ff; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 5px; margin: 20px 0; color: #2563eb;">
              ${code}
            </div>
            <p style="color: #6b7280; font-size: 14px;">Bu kod 1 saat geçerlidir.</p>
            <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 20px 0;">
            <p style="color: #9ca3af; font-size: 12px;">Bu e-postayı siz talep etmediyseniz, lütfen dikkate almayın.</p>
          </div>
        `
      });
      console.log(`📧 Doğrulama kodu gönderildi (${email}): ${code}`);
    } catch (emailError) {
      console.error('❌ E-posta gönderilemedi:', emailError);
      console.log(`📧 [FALLBACK] Doğrulama kodu (${email}): ${code}`);
    }
    
    res.status(201).json({
      message: 'Kayıt başarılı, lütfen e-postanızı doğrulayın',
      email: email,
      requiresVerification: true
    });
  } catch (error) {
    console.error('❌ Register error:', error);
    res.status(500).json({ error: 'Kayıt sırasında bir hata oluştu' });
  }
});

// E-posta doğrulama isteği - tüm e-postalara izin ver
router.post('/request-verification', [
  body('email').isEmail().withMessage('Geçerli e-posta adresi giriniz')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  const { email } = req.body;
  
  // Cooldown kontrolü
  const cooldownCheck = checkEmailCooldown(email);
  if (!cooldownCheck.allowed) {
    return res.status(429).json({ 
      error: `Lütfen ${cooldownCheck.remainingSeconds} saniye bekleyin`,
      remainingSeconds: cooldownCheck.remainingSeconds
    });
  }
  
  // 6 haneli rastgele kod oluştur
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  
  // Store'a kaydet (1 saat geçerli)
  verificationStore.set(email, { code, expiresAt: Date.now() + 60 * 60 * 1000 });
  
  // Cooldown zamanını kaydet
  emailCooldown.set(email, Date.now());
  
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

  // Kodu sil (tek kullanımlık)
  verificationStore.delete(email);
  console.log('✅ Kod doğru, kullanıcı doğrulanıyor');

  // Kullanıcıyı bul ve is_verified=true yap
  let user;
  try {
    user = await findUserByEmail(email);
    if (!user) {
      return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
    }
    
    // is_verified=true yap
    await query(
      'UPDATE users SET is_verified = true WHERE email = $1',
      [email]
    );
    user.is_verified = true;
    
    console.log(`✅ E-posta doğrulandı: ${email}`);
  } catch (dbError) {
    console.error('❌ DB error:', dbError);
    return res.status(500).json({ error: 'Veritabanı hatası' });
  }

  const token = jwt.sign(
    { userId: user.id, email: user.email },
    process.env.JWT_SECRET || 'development_secret',
    { expiresIn: '7d' }
  );

  res.json({
    message: 'E-posta doğrulandı, giriş başarılı',
    token,
    user: {
      id: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      isVerified: true
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

// Şifre sıfırlama kodu gönder
router.post('/forgot-password', [
  body('email').isEmail().withMessage('Geçerli e-posta adresi giriniz')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  
  const { email } = req.body;
  
  try {
    // Kullanıcı kontrolü
    const user = await findUserByEmail(email);
    if (!user) {
      // Güvenlik için kullanıcı yoksa bile başarılı mesajı dön
      return res.json({ message: 'Şifre sıfırlama kodu gönderildi', email });
    }
    
    // Cooldown kontrolü
    const cooldownCheck = checkEmailCooldown(email);
    if (!cooldownCheck.allowed) {
      return res.status(429).json({ 
        error: `Lütfen ${cooldownCheck.remainingSeconds} saniye bekleyin`,
        remainingSeconds: cooldownCheck.remainingSeconds
      });
    }
    
    // 6 haneli kod oluştur
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store'a kaydet (15 dakika geçerli)
    verificationStore.set(`reset_${email}`, { 
      code, 
      expiresAt: Date.now() + 15 * 60 * 1000,
      type: 'password_reset'
    });
    
    // Cooldown kaydet
    emailCooldown.set(email, Date.now());
    
    // E-posta gönder
    try {
      const { sendMail } = require('../services/emailService');
      await sendMail({
        to: email,
        subject: 'UniCampus - Şifre Sıfırlama Kodu',
        text: `Merhaba,\n\nŞifrenizi sıfırlamak için kod: ${code}\n\nBu kod 15 dakika geçerlidir.\n\nİyi günler,\nUniCampus Ekibi`,
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <h2 style="color: #dc2626;">UniCampus Şifre Sıfırlama</h2>
            <p>Merhaba,</p>
            <p>Şifrenizi sıfırlamak için aşağıdaki kodu kullanın:</p>
            <div style="background-color: #fef2f2; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 5px; margin: 20px 0; color: #dc2626;">
              ${code}
            </div>
            <p style="color: #6b7280; font-size: 14px;">Bu kod 15 dakika geçerlidir.</p>
            <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 20px 0;">
            <p style="color: #9ca3af; font-size: 12px;">Bu işlemi siz yapmadıysanız, lütfen dikkate almayın ve şifrenizi değiştirin.</p>
          </div>
        `
      });
      console.log(`📧 Şifre sıfırlama kodu gönderildi (${email}): ${code}`);
    } catch (emailError) {
      console.error('❌ E-posta gönderilemedi:', emailError);
      console.log(`📧 [FALLBACK] Şifre sıfırlama kodu (${email}): ${code}`);
    }
    
    res.json({ message: 'Şifre sıfırlama kodu e-posta adresinize gönderildi', email });
  } catch (error) {
    console.error('❌ Şifre sıfırlama hatası:', error);
    res.status(500).json({ error: 'Bir hata oluştu' });
  }
});

// Şifreyi sıfırla
router.post('/reset-password', [
  body('email').isEmail(),
  body('code').isLength({ min: 6, max: 6 }),
  body('newPassword').isLength({ min: 6 }).withMessage('Şifre en az 6 karakter olmalı')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  
  const { email, code, newPassword } = req.body;
  
  try {
    // Kod kontrolü
    const record = verificationStore.get(`reset_${email}`);
    if (!record) {
      return res.status(400).json({ error: 'Geçersiz veya süresi dolmuş kod' });
    }
    
    if (record.expiresAt < Date.now()) {
      verificationStore.delete(`reset_${email}`);
      return res.status(400).json({ error: 'Kod süresi doldu' });
    }
    
    if (record.code !== code) {
      return res.status(400).json({ error: 'Yanlış kod' });
    }
    
    // Kullanıcıyı bul ve şifreyi güncelle
    const user = await findUserByEmail(email);
    if (!user) {
      return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
    }
    
    // Şifreyi güncelle (production'da bcrypt kullan!)
    await query(
      'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2',
      [newPassword, user.id]
    );
    
    // Kodu sil
    verificationStore.delete(`reset_${email}`);
    
    console.log(`✅ Şifre başarıyla sıfırlandı: ${email}`);
    res.json({ message: 'Şifreniz başarıyla güncellendi' });
  } catch (error) {
    console.error('❌ Şifre güncelleme hatası:', error);
    res.status(500).json({ error: 'Şifre güncellenirken hata oluştu' });
  }
});

// FCM Token kaydetme endpoint
router.post('/fcm-token', authenticateToken, async (req, res) => {
  try {
    const { fcmToken, platform } = req.body;
    const userId = req.user.userId;

    if (!fcmToken) {
      return res.status(400).json({ error: 'FCM token gerekli' });
    }

    // Users tablosuna fcm_token ekle/güncelle
    await query(
      `UPDATE users 
       SET fcm_token = $1, fcm_platform = $2, fcm_updated_at = NOW() 
       WHERE id = $3`,
      [fcmToken, platform || 'unknown', userId]
    );

    console.log(`✅ FCM token kaydedildi - User: ${userId}, Platform: ${platform}`);
    res.json({ message: 'FCM token başarıyla kaydedildi' });
  } catch (error) {
    console.error('❌ FCM token kaydetme hatası:', error);
    res.status(500).json({ error: 'FCM token kaydedilemedi' });
  }
});

module.exports = router;