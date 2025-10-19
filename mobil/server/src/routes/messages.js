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

// ==================== MESAJ GÖNDERME ====================

/**
 * POST /api/messages/send
 * Yeni mesaj gönder
 */
router.post('/send', authenticateToken, async (req, res) => {
  try {
    const { receiverId, content, conversationId, messageType = 'text', fileUrl, fileName } = req.body;
    const senderId = req.user.id;

    // Validasyon
    if (!receiverId || !content) {
      return res.status(400).json({ error: 'receiverId ve content gerekli' });
    }

    // Conversation yoksa oluştur
    let finalConversationId = conversationId;
    
    if (!conversationId) {
      // İki kullanıcı arasında conversation var mı kontrol et
      const existingConv = await query(
        `SELECT c.id FROM conversations c
         INNER JOIN conversation_participants cp1 ON c.id = cp1.conversation_id
         INNER JOIN conversation_participants cp2 ON c.id = cp2.conversation_id
         WHERE cp1.user_id = $1 AND cp2.user_id = $2 AND c.conversation_type = 'direct'
         LIMIT 1`,
        [senderId, receiverId]
      );

      if (existingConv.rows.length > 0) {
        finalConversationId = existingConv.rows[0].id;
      } else {
        // Yeni conversation oluştur
        const newConv = await query(
          `INSERT INTO conversations (conversation_type, created_at, last_message_at)
           VALUES ('direct', NOW(), NOW())
           RETURNING id`,
          []
        );
        finalConversationId = newConv.rows[0].id;

        // Participants ekle
        await query(
          `INSERT INTO conversation_participants (conversation_id, user_id, role, joined_at)
           VALUES ($1, $2, 'member', NOW()), ($1, $3, 'member', NOW())`,
          [finalConversationId, senderId, receiverId]
        );
      }
    }

    // Mesajı kaydet
    const result = await query(
      `INSERT INTO messages 
       (conversation_id, sender_id, message_text, message_type, file_url, file_name, created_at, is_read)
       VALUES ($1, $2, $3, $4, $5, $6, NOW(), false)
       RETURNING id, conversation_id, sender_id, message_text, message_type, file_url, file_name, created_at, is_read`,
      [finalConversationId, senderId, content, messageType, fileUrl, fileName]
    );

    const message = result.rows[0];

    // Conversation'ın last_message_at'ını güncelle
    await query(
      `UPDATE conversations SET last_message_at = NOW() WHERE id = $1`,
      [finalConversationId]
    );

    // Socket.io ile alıcıya gönder
    const io = req.app.get('io');
    if (io) {
      io.to(`user_${receiverId}`).emit('new_message', message);
    }

    res.status(201).json({
      success: true,
      message,
      conversationId: finalConversationId
    });

  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ error: 'Mesaj gönderilemedi', details: error.message });
  }
});

// ==================== MESAJ LİSTESİ ====================

/**
 * GET /api/messages/conversation/:conversationId
 * Belirli bir konuşmanın mesajlarını getir
 */
router.get('/conversation/:conversationId', authenticateToken, async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { limit = 50, offset = 0 } = req.query;
    const userId = req.user.id;

    // Kullanıcı bu conversation'ın katılımcısı mı kontrol et
    const participant = await query(
      `SELECT id FROM conversation_participants 
       WHERE conversation_id = $1 AND user_id = $2 AND left_at IS NULL`,
      [conversationId, userId]
    );

    if (participant.rows.length === 0) {
      return res.status(403).json({ error: 'Bu konuşmaya erişim yetkiniz yok' });
    }

    // Mesajları getir
    const result = await query(
      `SELECT m.id, m.conversation_id, m.sender_id, m.message_text, m.message_type,
              m.file_url, m.file_name, m.file_size, m.thumbnail_url,
              m.is_read, m.is_edited, m.edited_at, m.created_at,
              m.reply_to_message_id, m.reactions,
              u.first_name, u.last_name, u.profile_image_url
       FROM messages m
       INNER JOIN users u ON m.sender_id = u.id
       WHERE m.conversation_id = $1 AND m.deleted_at IS NULL
       ORDER BY m.created_at DESC
       LIMIT $2 OFFSET $3`,
      [conversationId, limit, offset]
    );

    res.json({
      success: true,
      messages: result.rows,
      count: result.rows.length,
      conversationId: parseInt(conversationId)
    });

  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({ error: 'Mesajlar getirilemedi', details: error.message });
  }
});

// ==================== İKİ KULLANICI ARASINDAKİ MESAJLAR ====================

/**
 * GET /api/messages/user/:userId
 * Belirli bir kullanıcı ile mesajlaşmayı getir
 */
router.get('/user/:userId', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;
    const { limit = 50, offset = 0 } = req.query;
    const currentUserId = req.user.id;

    // İki kullanıcı arasındaki conversation'ı bul
    const conv = await query(
      `SELECT c.id FROM conversations c
       INNER JOIN conversation_participants cp1 ON c.id = cp1.conversation_id
       INNER JOIN conversation_participants cp2 ON c.id = cp2.conversation_id
       WHERE cp1.user_id = $1 AND cp2.user_id = $2 
       AND c.conversation_type = 'direct'
       AND cp1.left_at IS NULL AND cp2.left_at IS NULL
       LIMIT 1`,
      [currentUserId, userId]
    );

    if (conv.rows.length === 0) {
      return res.json({
        success: true,
        messages: [],
        count: 0,
        conversationId: null,
        info: 'Henüz mesajlaşma yok'
      });
    }

    const conversationId = conv.rows[0].id;

    // Mesajları getir
    const result = await query(
      `SELECT m.id, m.conversation_id, m.sender_id, m.message_text, m.message_type,
              m.file_url, m.file_name, m.is_read, m.created_at,
              u.first_name, u.last_name, u.profile_image_url
       FROM messages m
       INNER JOIN users u ON m.sender_id = u.id
       WHERE m.conversation_id = $1 AND m.deleted_at IS NULL
       ORDER BY m.created_at DESC
       LIMIT $2 OFFSET $3`,
      [conversationId, limit, offset]
    );

    res.json({
      success: true,
      messages: result.rows,
      count: result.rows.length,
      conversationId
    });

  } catch (error) {
    console.error('Get user messages error:', error);
    res.status(500).json({ error: 'Mesajlar getirilemedi', details: error.message });
  }
});

// ==================== MESAJ OKUNDU İŞARETLE ====================

/**
 * PUT /api/messages/:messageId/read
 * Mesajı okundu olarak işaretle
 */
router.put('/:messageId/read', authenticateToken, async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user.id;

    // Mesajın conversation_id'sini al
    const messageResult = await query(
      `SELECT conversation_id FROM messages WHERE id = $1`,
      [messageId]
    );

    if (messageResult.rows.length === 0) {
      return res.status(404).json({ error: 'Mesaj bulunamadı' });
    }

    const conversationId = messageResult.rows[0].conversation_id;

    // Kullanıcının last_read_message_id'sini güncelle
    await query(
      `UPDATE conversation_participants 
       SET last_read_message_id = $1
       WHERE conversation_id = $2 AND user_id = $3`,
      [messageId, conversationId, userId]
    );

    // Socket.io ile gönderene bildir
    const io = req.app.get('io');
    if (io) {
      const sender = await query(
        `SELECT sender_id FROM messages WHERE id = $1`,
        [messageId]
      );
      if (sender.rows.length > 0) {
        io.to(`user_${sender.rows[0].sender_id}`).emit('message_read_receipt', {
          messageId,
          readBy: userId,
          readAt: new Date().toISOString()
        });
      }
    }

    res.json({
      success: true,
      message: 'Mesaj okundu olarak işaretlendi'
    });

  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({ error: 'İşlem başarısız', details: error.message });
  }
});

// ==================== MESAJ SİLME ====================

/**
 * DELETE /api/messages/:messageId
 * Mesajı sil (soft delete)
 */
router.delete('/:messageId', authenticateToken, async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user.id;

    // Mesaj kullanıcının mı kontrol et
    const message = await query(
      `SELECT sender_id FROM messages WHERE id = $1`,
      [messageId]
    );

    if (message.rows.length === 0) {
      return res.status(404).json({ error: 'Mesaj bulunamadı' });
    }

    if (message.rows[0].sender_id !== userId) {
      return res.status(403).json({ error: 'Bu mesajı silme yetkiniz yok' });
    }

    // Soft delete
    await query(
      `UPDATE messages 
       SET deleted_at = NOW(), deleted_by = $1
       WHERE id = $2`,
      [userId, messageId]
    );

    res.json({
      success: true,
      message: 'Mesaj silindi'
    });

  } catch (error) {
    console.error('Delete message error:', error);
    res.status(500).json({ error: 'Mesaj silinemedi', details: error.message });
  }
});

// ==================== MESAJ DÜZENLEME ====================

/**
 * PUT /api/messages/:messageId
 * Mesajı düzenle
 */
router.put('/:messageId', authenticateToken, async (req, res) => {
  try {
    const { messageId } = req.params;
    const { content } = req.body;
    const userId = req.user.id;

    if (!content) {
      return res.status(400).json({ error: 'İçerik gerekli' });
    }

    // Mesaj kullanıcının mı kontrol et
    const message = await query(
      `SELECT sender_id FROM messages WHERE id = $1`,
      [messageId]
    );

    if (message.rows.length === 0) {
      return res.status(404).json({ error: 'Mesaj bulunamadı' });
    }

    if (message.rows[0].sender_id !== userId) {
      return res.status(403).json({ error: 'Bu mesajı düzenleme yetkiniz yok' });
    }

    // Mesajı güncelle
    const result = await query(
      `UPDATE messages 
       SET message_text = $1, is_edited = true, edited_at = NOW()
       WHERE id = $2
       RETURNING id, message_text, is_edited, edited_at`,
      [content, messageId]
    );

    res.json({
      success: true,
      message: result.rows[0]
    });

  } catch (error) {
    console.error('Edit message error:', error);
    res.status(500).json({ error: 'Mesaj düzenlenemedi', details: error.message });
  }
});

// ==================== OKUNMAMIŞ MESAJ SAYISI ====================

/**
 * GET /api/messages/unread/count
 * Kullanıcının tüm okunmamış mesaj sayısı
 */
router.get('/unread/count', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    const result = await query(
      `SELECT COUNT(DISTINCT m.id) as unread_count
       FROM messages m
       INNER JOIN conversation_participants cp ON m.conversation_id = cp.conversation_id
       WHERE cp.user_id = $1 
       AND m.sender_id != $1
       AND m.deleted_at IS NULL
       AND (cp.last_read_message_id IS NULL OR m.id > cp.last_read_message_id)`,
      [userId]
    );

    res.json({
      success: true,
      unreadCount: parseInt(result.rows[0].unread_count) || 0
    });

  } catch (error) {
    console.error('Unread count error:', error);
    res.status(500).json({ error: 'Sayı alınamadı', details: error.message });
  }
});

module.exports = router;
