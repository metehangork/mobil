const express = require('express');
const router = express.Router();
const { query } = require('../db/pool');
const jwt = require('jsonwebtoken');

// JWT doğrulama middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Token gerekli' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: 'Geçersiz token' });
    }
    req.user = user;
    next();
  });
};

// ==================== KONUŞMA LİSTESİ ====================

/**
 * GET /api/conversations
 * Kullanıcının tüm konuşmalarını getir
 */
router.get('/', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const { limit = 20, offset = 0 } = req.query;

    const result = await query(
      `SELECT DISTINCT ON (c.id)
              c.id, c.conversation_type, c.name, c.last_message_at, c.is_archived, c.is_pinned,
              c.created_at,
              -- Son mesaj
              m.message_text as last_message,
              m.sender_id as last_message_sender_id,
              m.created_at as last_message_time,
              -- Karşı kullanıcı bilgileri (direct conversation için)
              other_user.id as other_user_id,
              other_user.first_name as other_user_first_name,
              other_user.last_name as other_user_last_name,
              other_user.profile_image_url as other_user_profile_image,
              -- Okunmamış mesaj sayısı
              (SELECT COUNT(*) 
               FROM messages m2 
               WHERE m2.conversation_id = c.id 
               AND m2.sender_id != $1
               AND m2.deleted_at IS NULL
               AND (cp.last_read_message_id IS NULL OR m2.id > cp.last_read_message_id)
              ) as unread_count
       FROM conversations c
       INNER JOIN conversation_participants cp ON c.id = cp.conversation_id
       LEFT JOIN messages m ON m.id = (
         SELECT id FROM messages 
         WHERE conversation_id = c.id AND deleted_at IS NULL 
         ORDER BY created_at DESC LIMIT 1
       )
       LEFT JOIN conversation_participants cp_other ON c.id = cp_other.conversation_id 
         AND cp_other.user_id != $1 AND c.conversation_type = 'direct'
       LEFT JOIN users other_user ON cp_other.user_id = other_user.id
       WHERE cp.user_id = $1 AND cp.left_at IS NULL
       ORDER BY c.id, c.last_message_at DESC NULLS LAST
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    res.json({
      success: true,
      conversations: result.rows,
      count: result.rows.length
    });

  } catch (error) {
    console.error('Get conversations error:', error);
    res.status(500).json({ error: 'Konuşmalar getirilemedi', details: error.message });
  }
});

// ==================== TEK KONUŞMA DETAYI ====================

/**
 * GET /api/conversations/:conversationId
 * Belirli bir konuşmanın detaylarını getir
 */
router.get('/:conversationId', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.id;

    // Kullanıcı bu conversation'ın katılımcısı mı?
    const participant = await query(
      `SELECT id FROM conversation_participants 
       WHERE conversation_id = $1 AND user_id = $2 AND left_at IS NULL`,
      [conversationId, userId]
    );

    if (participant.rows.length === 0) {
      return res.status(403).json({ error: 'Bu konuşmaya erişim yetkiniz yok' });
    }

    // Konuşma detayları
    const conversation = await query(
      `SELECT c.id, c.conversation_type, c.name, c.last_message_at, 
              c.is_archived, c.is_pinned, c.created_at
       FROM conversations c
       WHERE c.id = $1`,
      [conversationId]
    );

    if (conversation.rows.length === 0) {
      return res.status(404).json({ error: 'Konuşma bulunamadı' });
    }

    // Katılımcılar
    const participants = await query(
      `SELECT cp.id, cp.user_id, cp.role, cp.joined_at,
              u.first_name, u.last_name, u.profile_image_url, u.email
       FROM conversation_participants cp
       INNER JOIN users u ON cp.user_id = u.id
       WHERE cp.conversation_id = $1 AND cp.left_at IS NULL`,
      [conversationId]
    );

    res.json({
      success: true,
      conversation: {
        ...conversation.rows[0],
        participants: participants.rows
      }
    });

  } catch (error) {
    console.error('Get conversation detail error:', error);
    res.status(500).json({ error: 'Konuşma detayı getirilemedi', details: error.message });
  }
});

// ==================== YENİ KONUŞMA OLUŞTUR ====================

/**
 * POST /api/conversations
 * Yeni konuşma oluştur (grup veya direkt)
 */
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { type = 'direct', name, participantIds } = req.body;
    const userId = req.user.id;

    if (!participantIds || participantIds.length === 0) {
      return res.status(400).json({ error: 'Katılımcı ID\'leri gerekli' });
    }

    // Grup konuşması ise isim gerekli
    if (type === 'group' && !name) {
      return res.status(400).json({ error: 'Grup konuşması için isim gerekli' });
    }

    // Direct conversation ise sadece 1 katılımcı olmalı
    if (type === 'direct' && participantIds.length !== 1) {
      return res.status(400).json({ error: 'Direct konuşma için sadece 1 katılımcı gerekli' });
    }

    // Direct conversation zaten var mı kontrol et
    if (type === 'direct') {
      const existingConv = await query(
        `SELECT c.id FROM conversations c
         INNER JOIN conversation_participants cp1 ON c.id = cp1.conversation_id
         INNER JOIN conversation_participants cp2 ON c.id = cp2.conversation_id
         WHERE cp1.user_id = $1 AND cp2.user_id = $2 
         AND c.conversation_type = 'direct'
         AND cp1.left_at IS NULL AND cp2.left_at IS NULL
         LIMIT 1`,
        [userId, participantIds[0]]
      );

      if (existingConv.rows.length > 0) {
        return res.status(200).json({
          success: true,
          conversation: { id: existingConv.rows[0].id },
          message: 'Konuşma zaten mevcut'
        });
      }
    }

    // Yeni conversation oluştur
    const conversation = await query(
      `INSERT INTO conversations (conversation_type, name, created_at, last_message_at)
       VALUES ($1, $2, NOW(), NOW())
       RETURNING id, conversation_type, name, created_at`,
      [type, name]
    );

    const conversationId = conversation.rows[0].id;

    // Oluşturan kullanıcıyı ekle (admin olarak)
    await query(
      `INSERT INTO conversation_participants (conversation_id, user_id, role, joined_at)
       VALUES ($1, $2, $3, NOW())`,
      [conversationId, userId, type === 'group' ? 'admin' : 'member']
    );

    // Diğer katılımcıları ekle
    for (const participantId of participantIds) {
      await query(
        `INSERT INTO conversation_participants (conversation_id, user_id, role, joined_at)
         VALUES ($1, $2, 'member', NOW())`,
        [conversationId, participantId]
      );
    }

    res.status(201).json({
      success: true,
      conversation: conversation.rows[0]
    });

  } catch (error) {
    console.error('Create conversation error:', error);
    res.status(500).json({ error: 'Konuşma oluşturulamadı', details: error.message });
  }
});

// ==================== KONUŞMAYI ARŞİVLE ====================

/**
 * PUT /api/conversations/:conversationId/archive
 * Konuşmayı arşivle veya arşivden çıkar
 */
router.put('/:conversationId/archive', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { isArchived = true } = req.body;
    const userId = req.user.id;

    // Kullanıcı bu conversation'ın katılımcısı mı?
    const participant = await query(
      `SELECT id FROM conversation_participants 
       WHERE conversation_id = $1 AND user_id = $2 AND left_at IS NULL`,
      [conversationId, userId]
    );

    if (participant.rows.length === 0) {
      return res.status(403).json({ error: 'Bu konuşmaya erişim yetkiniz yok' });
    }

    await query(
      `UPDATE conversations SET is_archived = $1 WHERE id = $2`,
      [isArchived, conversationId]
    );

    res.json({
      success: true,
      message: isArchived ? 'Konuşma arşivlendi' : 'Konuşma arşivden çıkarıldı'
    });

  } catch (error) {
    console.error('Archive conversation error:', error);
    res.status(500).json({ error: 'İşlem başarısız', details: error.message });
  }
});

// ==================== KONUŞMAYI SABİTLE ====================

/**
 * PUT /api/conversations/:conversationId/pin
 * Konuşmayı sabitle veya sabitlemeden çıkar
 */
router.put('/:conversationId/pin', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { isPinned = true } = req.body;
    const userId = req.user.id;

    // Kullanıcı bu conversation'ın katılımcısı mı?
    const participant = await query(
      `SELECT id FROM conversation_participants 
       WHERE conversation_id = $1 AND user_id = $2 AND left_at IS NULL`,
      [conversationId, userId]
    );

    if (participant.rows.length === 0) {
      return res.status(403).json({ error: 'Bu konuşmaya erişim yetkiniz yok' });
    }

    await query(
      `UPDATE conversations SET is_pinned = $1 WHERE id = $2`,
      [isPinned, conversationId]
    );

    res.json({
      success: true,
      message: isPinned ? 'Konuşma sabitlendi' : 'Konuşma sabitlemeden çıkarıldı'
    });

  } catch (error) {
    console.error('Pin conversation error:', error);
    res.status(500).json({ error: 'İşlem başarısız', details: error.message });
  }
});

// ==================== KONUŞMADAN AYRIL ====================

/**
 * DELETE /api/conversations/:conversationId/leave
 * Konuşmadan ayrıl
 */
router.delete('/:conversationId/leave', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user.id;

    // Katılımcı bilgilerini al
    const participant = await query(
      `SELECT id, role FROM conversation_participants 
       WHERE conversation_id = $1 AND user_id = $2 AND left_at IS NULL`,
      [conversationId, userId]
    );

    if (participant.rows.length === 0) {
      return res.status(404).json({ error: 'Bu konuşmada değilsiniz' });
    }

    // Ayrıl
    await query(
      `UPDATE conversation_participants 
       SET left_at = NOW() 
       WHERE conversation_id = $1 AND user_id = $2`,
      [conversationId, userId]
    );

    res.json({
      success: true,
      message: 'Konuşmadan ayrıldınız'
    });

  } catch (error) {
    console.error('Leave conversation error:', error);
    res.status(500).json({ error: 'İşlem başarısız', details: error.message });
  }
});

// ==================== GRUP KONUŞMASINA KATILIMCI EKLE ====================

/**
 * POST /api/conversations/:conversationId/participants
 * Grup konuşmasına yeni katılımcı ekle
 */
router.post('/:conversationId/participants', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { userIds } = req.body;
    const userId = req.user.id;

    if (!userIds || userIds.length === 0) {
      return res.status(400).json({ error: 'Kullanıcı ID\'leri gerekli' });
    }

    // Conversation tipini ve kullanıcı yetkisini kontrol et
    const convCheck = await query(
      `SELECT c.conversation_type, cp.role
       FROM conversations c
       INNER JOIN conversation_participants cp ON c.id = cp.conversation_id
       WHERE c.id = $1 AND cp.user_id = $2 AND cp.left_at IS NULL`,
      [conversationId, userId]
    );

    if (convCheck.rows.length === 0) {
      return res.status(403).json({ error: 'Bu konuşmaya erişim yetkiniz yok' });
    }

    if (convCheck.rows[0].conversation_type !== 'group') {
      return res.status(400).json({ error: 'Sadece grup konuşmalarına katılımcı eklenebilir' });
    }

    if (convCheck.rows[0].role !== 'admin') {
      return res.status(403).json({ error: 'Sadece adminler katılımcı ekleyebilir' });
    }

    // Katılımcıları ekle
    for (const newUserId of userIds) {
      await query(
        `INSERT INTO conversation_participants (conversation_id, user_id, role, joined_at)
         VALUES ($1, $2, 'member', NOW())
         ON CONFLICT DO NOTHING`,
        [conversationId, newUserId]
      );
    }

    res.json({
      success: true,
      message: 'Katılımcılar eklendi'
    });

  } catch (error) {
    console.error('Add participants error:', error);
    res.status(500).json({ error: 'Katılımcılar eklenemedi', details: error.message });
  }
});

module.exports = router;
