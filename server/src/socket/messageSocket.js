const { Server } = require('socket.io');
const { query } = require('../db/pool');
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

  // Bağlantı sayacı
  let activeConnections = 0;

  io.on('connection', (socket) => {
    activeConnections++;
    console.log(`🔗 Yeni bağlantı: ${socket.id} | Aktif: ${activeConnections}`);

    // ==================== KULLANICI GİRİŞİ ====================
    socket.on('user_online', async (data) => {
      try {
        const { userId } = data;
        
        if (!userId) {
          socket.emit('error', { message: 'userId gerekli' });
          return;
        }

        // Socket'e userId'yi kaydet
        socket.userId = userId;
        
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

        console.log(`👤 Kullanıcı ${userId} çevrimiçi oldu`);
        
        // Başarı mesajı gönder
        socket.emit('connected', {
          success: true,
          userId,
          socketId: socket.id
        });
      } catch (error) {
        console.error('user_online error:', error);
        socket.emit('error', { message: 'Bağlantı hatası', error: error.message });
      }
    });

    // ==================== MESAJ GÖNDERME ====================
    socket.on('send_message', async (data) => {
      try {
        const { senderId, receiverId, content, conversationId } = data;

        // Validasyon
        if (!senderId || !receiverId || !content) {
          socket.emit('message_error', { 
            error: 'senderId, receiverId ve content gerekli' 
          });
          return;
        }

        // 1. PostgreSQL'e mesajı kaydet
        const result = await query(
          `INSERT INTO messages (sender_id, receiver_id, content, conversation_id, created_at, is_read)
           VALUES ($1, $2, $3, $4, NOW(), false)
           RETURNING id, sender_id, receiver_id, content, conversation_id, created_at, is_read`,
          [senderId, receiverId, content, conversationId]
        );

        const message = result.rows[0];
        console.log(`📨 Mesaj kaydedildi: ${senderId} -> ${receiverId}`);

        // 2. Alıcının çevrimiçi durumunu kontrol et
        const receiverStatus = await getUserStatus(receiverId);

        // 3. Mesajı alıcıya gönder (çevrimiçi ise)
        if (receiverStatus === 'online') {
          io.to(`user_${receiverId}`).emit('new_message', {
            ...message,
            senderStatus: 'online'
          });
          console.log(`✅ Mesaj alıcıya iletildi (çevrimiçi)`);
        } else {
          console.log(`📴 Alıcı çevrimdışı, mesaj veritabanında saklandı`);
        }

        // 4. Göndericiye onay gönder
        socket.emit('message_sent', {
          success: true,
          message,
          receiverStatus
        });

        // 5. Konuşma önbelleğini temizle (yeni mesaj geldiğinde eski cache geçersiz)
        await clearConversationCache(senderId, receiverId);

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
        const { messageId, userId } = data;

        if (!messageId || !userId) {
          return;
        }

        // Veritabanında mesajı okundu olarak işaretle
        await query(
          `UPDATE messages SET is_read = true WHERE id = $1`,
          [messageId]
        );

        // Mesaj gönderene bildir
        const messageResult = await query(
          `SELECT sender_id FROM messages WHERE id = $1`,
          [messageId]
        );

        if (messageResult.rows.length > 0) {
          const senderId = messageResult.rows[0].sender_id;
          io.to(`user_${senderId}`).emit('message_read_receipt', {
            messageId,
            readBy: userId,
            readAt: new Date().toISOString()
          });
        }

        console.log(`👁️ Mesaj ${messageId} okundu olarak işaretlendi`);
      } catch (error) {
        console.error('message_read error:', error);
      }
    });

    // ==================== KONUŞMA GEÇMİŞİ İSTEĞİ ====================
    socket.on('get_conversation', async (data) => {
      try {
        const { userId1, userId2, limit = 50, offset = 0 } = data;

        if (!userId1 || !userId2) {
          socket.emit('conversation_error', { error: 'userId1 ve userId2 gerekli' });
          return;
        }

        // Önce cache'den kontrol et
        const cached = await getCachedConversation(userId1, userId2);
        if (cached) {
          socket.emit('conversation_data', {
            messages: cached,
            fromCache: true
          });
          return;
        }

        // Cache'de yoksa veritabanından çek
        const result = await query(
          `SELECT id, sender_id, receiver_id, content, created_at, is_read
           FROM messages
           WHERE (sender_id = $1 AND receiver_id = $2)
              OR (sender_id = $2 AND receiver_id = $1)
           ORDER BY created_at DESC
           LIMIT $3 OFFSET $4`,
          [userId1, userId2, limit, offset]
        );

        const messages = result.rows;

        // Cache'e kaydet
        await cacheConversation(userId1, userId2, messages);

        socket.emit('conversation_data', {
          messages,
          fromCache: false,
          count: messages.length
        });

        console.log(`📚 Konuşma geçmişi gönderildi: ${userId1} <-> ${userId2} (${messages.length} mesaj)`);
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
