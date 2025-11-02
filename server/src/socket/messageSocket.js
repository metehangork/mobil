const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const { query } = require('../db/pool');
const fcmService = require('../services/fcmService');
const {
  setUserOnline,
  getUserStatus,
  removeUserOnline,
  cacheConversation,
  getCachedConversation,
  clearConversationCache,
  setUserTyping
} = require('../config/redis');

/**
 * Socket.io bağlantısını başlat ve mesajlaşma olaylarını yönet
 * @param {Object} server - HTTP sunucu instance
 * @returns {Object} Socket.io instance
 */
function initializeSocket(server) {
  const io = new Server(server, {
    cors: {
      origin: '*', // Geliştirme ortamı için - production'da spesifik domainler ekle
      methods: ['GET', 'POST'],
      credentials: true
    },
    pingTimeout: 60000,
    pingInterval: 25000
  });

  // ==================== JWT AUTHENTICATION MIDDLEWARE ====================
  io.use((socket, next) => {
    const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.split(' ')[1];
    
    if (!token) {
      console.log('❌ Socket bağlantısı reddedildi: Token yok');
      return next(new Error('Authentication error: Token gerekli'));
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = decoded.userId; // Token'dan userId'yi al
      socket.userEmail = decoded.email; // Email'i de ekleyelim
      console.log(`✅ Socket authentication başarılı: User ${decoded.userId} (${decoded.email})`);
      next();
    } catch (error) {
      console.log('❌ Socket bağlantısı reddedildi: Geçersiz token');
      return next(new Error('Authentication error: Geçersiz token'));
    }
  });

  // Bağlantı sayacı
  let activeConnections = 0;

  io.on('connection', (socket) => {
    activeConnections++;
    console.log(`🔗 Yeni bağlantı: ${socket.id} | User: ${socket.userId} | Aktif: ${activeConnections}`);

    // ==================== KULLANICI GİRİŞİ ====================
    // Otomatik olarak kullanıcıyı çevrimiçi yap (JWT'den userId geldi)
    (async () => {
      try {
        const userId = socket.userId;
        
        // Kullanıcıyı kendi odasına ekle
        socket.join(`user_${userId}`);
        
        // Redis'e kaydet
        await setUserOnline(userId, socket.id);
        
        // Tüm kullanıcılara bildir
        io.emit('status_change', {
          userId,
          status: 'online',
          timestamp: new Date().toISOString()
        });

        console.log(`👤 Kullanıcı ${userId} (${socket.userEmail}) çevrimiçi oldu`);
        
        // Başarı mesajı gönder
        socket.emit('connected', {
          success: true,
          userId,
          email: socket.userEmail,
          socketId: socket.id
        });
      } catch (error) {
        console.error('Auto user_online error:', error);
        socket.emit('error', { message: 'Bağlantı hatası', error: error.message });
      }
    })();

    // ==================== MESAJ GÖNDERME ====================
    socket.on('send_message', async (data) => {
      try {
        const { conversationId, text } = data;

        // JWT'den gelen userId'yi kullan (güvenlik!)
        const senderId = socket.userId;

        // Validasyon
        if (!conversationId || !text) {
          socket.emit('message_error', { 
            error: 'conversationId ve text gerekli' 
          });
          return;
        }

        // Güvenlik: Kullanıcının bu conversation'a erişimi var mı kontrol et
        const accessCheck = await query(`
          SELECT c.id, m.user1_id, m.user2_id
          FROM conversations c
          JOIN matches m ON m.id = c.match_id
          WHERE c.id = $1 AND ($2 = m.user1_id OR $2 = m.user2_id)
        `, [conversationId, senderId]);

        if (!accessCheck.rows.length) {
          console.log(`❌ Erişim reddedildi: User ${senderId} conversation ${conversationId}'ye erişemez`);
          socket.emit('message_error', { 
            error: 'Bu konuşmaya erişim yetkiniz yok' 
          });
          return;
        }

        // Alıcı ID'sini bul
        const match = accessCheck.rows[0];
        const receiverId = match.user1_id === parseInt(senderId) 
          ? match.user2_id 
          : match.user1_id;

        // 1. PostgreSQL'e mesajı kaydet
        const result = await query(
          `INSERT INTO messages (conversation_id, sender_id, message_text, message_type, is_read, created_at)
           VALUES ($1, $2, $3, 'text', false, NOW())
           RETURNING id, conversation_id, sender_id, message_text, message_type, is_read, created_at`,
          [conversationId, senderId, text]
        );

        const message = result.rows[0];
        console.log(`📨 Mesaj kaydedildi: ${senderId} -> ${receiverId} (conversation: ${conversationId})`);

        // 2. Conversation'ı güncelle (last_message_at)
        await query('UPDATE conversations SET last_message_at = NOW() WHERE id = $1', [conversationId]);

        // 3. Alıcının çevrimiçi durumunu kontrol et
        const receiverStatus = await getUserStatus(receiverId.toString());

        // 4. Mesajı alıcıya gönder (çevrimiçi ise)
        if (receiverStatus === 'online') {
          io.to(`user_${receiverId}`).emit('new_message', {
            ...message,
            senderStatus: 'online'
          });
          console.log(`✅ Mesaj alıcıya iletildi (çevrimiçi)`);
        } else {
          console.log(`📴 Alıcı çevrimdışı, push notification gönderiliyor...`);
          
          // Push notification gönder (çevrimdışı kullanıcıya)
          try {
            // Gönderenin adını al
            const senderResult = await query(
              'SELECT first_name, last_name FROM users WHERE id = $1',
              [senderId]
            );
            const senderName = senderResult.rows.length > 0
              ? `${senderResult.rows[0].first_name} ${senderResult.rows[0].last_name}`
              : 'Birisi';

            // FCM notification gönder
            await fcmService.sendMessageNotification(receiverId, {
              senderName,
              messageText: text,
              conversationId,
              senderId,
              messageId: message.id,
            });
          } catch (fcmError) {
            console.error('FCM notification error:', fcmError);
            // FCM hatası mesaj gönderimini engellemez
          }
        }

        // 5. Göndericiye onay gönder
        socket.emit('message_sent', {
          success: true,
          message,
          receiverStatus
        });

        // 6. Konuşma önbelleğini temizle (yeni mesaj geldiğinde eski cache geçersiz)
        await clearConversationCache(senderId.toString(), receiverId.toString());

      } catch (error) {
        console.error('send_message error:', error);
        socket.emit('message_error', {
          error: 'Mesaj gönderilemedi',
          details: error.message
        });
      }
    });

    // ==================== YAZIYOR BİLDİRİMİ ====================
    socket.on('typing', async (data) => {
      try {
        const { senderId, receiverId, isTyping } = data;

        if (!senderId || !receiverId) {
          return;
        }

        // Redis'e kaydet
        if (isTyping) {
          await setUserTyping(senderId, receiverId);
        }

        // Alıcıya bildir
        io.to(`user_${receiverId}`).emit('user_typing', {
          userId: senderId,
          isTyping,
          timestamp: new Date().toISOString()
        });

        console.log(`✍️ ${senderId} ${isTyping ? 'yazıyor' : 'yazma durdurdu'} -> ${receiverId}`);
      } catch (error) {
        console.error('typing error:', error);
      }
    });

    // ==================== MESAJ OKUNDU BİLDİRİMİ ====================
    socket.on('message_read', async (data) => {
      try {
        const { messageId } = data;
        const userId = socket.userId; // JWT'den gelen kullanıcı

        if (!messageId) {
          return;
        }

        // Veritabanında mesajı okundu olarak işaretle ve read_at timestamp ekle
        const updateResult = await query(
          `UPDATE messages 
           SET is_read = true, read_at = NOW() 
           WHERE id = $1 AND is_read = false
           RETURNING sender_id, conversation_id`,
          [messageId]
        );

        if (updateResult.rows.length === 0) {
          // Mesaj bulunamadı veya zaten okunmuş
          return;
        }

        const { sender_id, conversation_id } = updateResult.rows[0];

        // Mesaj gönderene bildir (çevrimiçiyse)
        io.to(`user_${sender_id}`).emit('message_read_receipt', {
          messageId,
          conversationId: conversation_id,
          readBy: userId,
          readAt: new Date().toISOString()
        });

        console.log(`👁️ Mesaj ${messageId} okundu: ${userId} tarafından, ${sender_id}'ye bildirildi`);
      } catch (error) {
        console.error('message_read error:', error);
      }
    });

    // ==================== KONUŞMA GEÇMİŞİ İSTEĞİ ====================
    socket.on('get_conversation', async (data) => {
      try {
        const { conversationId, limit = 50, offset = 0 } = data;
        const userId = socket.userId; // JWT'den gelen kullanıcı

        if (!conversationId) {
          socket.emit('conversation_error', { error: 'conversationId gerekli' });
          return;
        }

        // Güvenlik: Kullanıcının bu conversation'a erişimi var mı kontrol et
        const accessCheck = await query(`
          SELECT c.id, m.user1_id, m.user2_id
          FROM conversations c
          JOIN matches m ON m.id = c.match_id
          WHERE c.id = $1 AND ($2 = m.user1_id OR $2 = m.user2_id)
        `, [conversationId, userId]);

        if (!accessCheck.rows.length) {
          console.log(`❌ Erişim reddedildi: User ${userId} conversation ${conversationId}'ye erişemez`);
          socket.emit('conversation_error', { 
            error: 'Bu konuşmaya erişim yetkiniz yok' 
          });
          return;
        }

        // Cache key için user ID'lerini kullan
        const match = accessCheck.rows[0];
        const otherUserId = match.user1_id === parseInt(userId) 
          ? match.user2_id 
          : match.user1_id;

        // Önce cache'den kontrol et
        const cached = await getCachedConversation(userId.toString(), otherUserId.toString());
        if (cached) {
          socket.emit('conversation_data', {
            messages: cached,
            fromCache: true
          });
          return;
        }

        // Cache'de yoksa veritabanından çek
        const result = await query(
          `SELECT id, conversation_id, sender_id, message_text, message_type, is_read, read_at, created_at
           FROM messages
           WHERE conversation_id = $1
           ORDER BY created_at DESC
           LIMIT $2 OFFSET $3`,
          [conversationId, limit, offset]
        );

        const messages = result.rows;

        // Cache'e kaydet
        await cacheConversation(userId.toString(), otherUserId.toString(), messages);

        socket.emit('conversation_data', {
          messages,
          fromCache: false,
          count: messages.length
        });

        console.log(`📚 Konuşma geçmişi gönderildi: conversation ${conversationId} (${messages.length} mesaj)`);
      } catch (error) {
        console.error('get_conversation error:', error);
        socket.emit('conversation_error', {
          error: 'Konuşma geçmişi alınamadı',
          details: error.message
        });
      }
    });

    // ==================== ÇEVRİMİÇİ KULLANICILAR ====================
    socket.on('get_online_users', async (data) => {
      try {
        const { userIds } = data; // Kontrol edilecek kullanıcı ID'leri

        if (!userIds || !Array.isArray(userIds)) {
          socket.emit('online_users_error', { error: 'userIds array gerekli' });
          return;
        }

        const onlineStatus = {};
        for (const userId of userIds) {
          const status = await getUserStatus(userId);
          onlineStatus[userId] = status;
        }

        socket.emit('online_users_data', onlineStatus);
        console.log(`👥 Çevrimiçi kullanıcı durumları gönderildi (${userIds.length} kullanıcı)`);
      } catch (error) {
        console.error('get_online_users error:', error);
        socket.emit('online_users_error', {
          error: 'Kullanıcı durumları alınamadı',
          details: error.message
        });
      }
    });

    // ==================== BAĞLANTI KOPTU ====================
    socket.on('disconnect', async () => {
      activeConnections--;
      console.log(`❌ Bağlantı koptu: ${socket.id} | Aktif: ${activeConnections}`);

      try {
        if (socket.userId) {
          // Redis'ten sil
          await removeUserOnline(socket.userId);

          // Tüm kullanıcılara bildir
          io.emit('status_change', {
            userId: socket.userId,
            status: 'offline',
            timestamp: new Date().toISOString()
          });

          console.log(`👤 Kullanıcı ${socket.userId} çevrimdışı oldu`);
        }
      } catch (error) {
        console.error('disconnect error:', error);
      }
    });

    // ==================== MANUEL ÇIKIŞ ====================
    socket.on('user_logout', async (data) => {
      try {
        const { userId } = data;
        
        if (userId) {
          await removeUserOnline(userId);
          
          io.emit('status_change', {
            userId,
            status: 'offline',
            timestamp: new Date().toISOString()
          });

          console.log(`🚪 Kullanıcı ${userId} çıkış yaptı`);
          
          socket.disconnect(true);
        }
      } catch (error) {
        console.error('user_logout error:', error);
      }
    });

    // ==================== HATA YÖNETİMİ ====================
    socket.on('error', (error) => {
      console.error('Socket error:', error);
    });
  });

  // Socket.io instance'ını döndür (gerekirse başka yerlerden kullanmak için)
  return io;
}

module.exports = initializeSocket;
