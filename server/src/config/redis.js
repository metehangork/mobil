const redis = require('redis');

// Redis client oluştur
const redisClient = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    // Bağlantı hatalarını yakala
    reconnectStrategy: (retries) => {
      if (retries > 10) {
        console.error('❌ Redis bağlantısı 10 denemeden sonra başarısız oldu');
        return new Error('Redis bağlantısı kurulamadı');
      }
      // Her 500ms'de bir tekrar dene
      return retries * 500;
    }
  }
});

// Event listeners
redisClient.on('error', (err) => {
  console.error('❌ Redis Error:', err.message);
});

redisClient.on('connect', () => {
  console.log('🔗 Redis bağlanıyor...');
});

redisClient.on('ready', () => {
  console.log('✅ Redis hazır ve çalışıyor');
});

redisClient.on('end', () => {
  console.log('🔌 Redis bağlantısı kapandı');
});

// ==================== KULLANICI DURUM YÖNETİMİ ====================

/**
 * Kullanıcıyı çevrimiçi olarak işaretle
 * @param {string} userId - Kullanıcı ID
 * @param {string} socketId - Socket bağlantı ID
 */
const setUserOnline = async (userId, socketId) => {
  try {
    // Kullanıcı durumunu 1 saat boyunca sakla
    await redisClient.setEx(`online:${userId}`, 3600, socketId);
    console.log(`👤 Kullanıcı ${userId} çevrimiçi oldu`);
    return true;
  } catch (error) {
    console.error('Redis setUserOnline error:', error);
    return false;
  }
};

/**
 * Kullanıcının çevrimiçi durumunu kontrol et
 * @param {string} userId - Kullanıcı ID
 * @returns {Promise<string>} 'online' veya 'offline'
 */
const getUserStatus = async (userId) => {
  try {
    const socketId = await redisClient.get(`online:${userId}`);
    return socketId ? 'online' : 'offline';
  } catch (error) {
    console.error('Redis getUserStatus error:', error);
    return 'offline';
  }
};

/**
 * Kullanıcıyı çevrimdışı yap
 * @param {string} userId - Kullanıcı ID
 */
const removeUserOnline = async (userId) => {
  try {
    await redisClient.del(`online:${userId}`);
    console.log(`👤 Kullanıcı ${userId} çevrimdışı oldu`);
    return true;
  } catch (error) {
    console.error('Redis removeUserOnline error:', error);
    return false;
  }
};

/**
 * Tüm çevrimiçi kullanıcıları getir
 * @returns {Promise<Array>} Çevrimiçi kullanıcı ID'leri
 */
const getAllOnlineUsers = async () => {
  try {
    const keys = await redisClient.keys('online:*');
    const userIds = keys.map(key => key.replace('online:', ''));
    return userIds;
  } catch (error) {
    console.error('Redis getAllOnlineUsers error:', error);
    return [];
  }
};

// ==================== MESAJ ÖNBELLEKLEMİ ====================

/**
 * Konuşma geçmişini önbellekle (performans için)
 * @param {string} userId1 - İlk kullanıcı ID
 * @param {string} userId2 - İkinci kullanıcı ID
 * @param {Array} messages - Mesaj dizisi
 */
const cacheConversation = async (userId1, userId2, messages) => {
  try {
    // Konuşma anahtarını standartlaştır (küçük ID önce)
    const conversationKey = `chat:${Math.min(userId1, userId2)}_${Math.max(userId1, userId2)}`;
    
    // 10 dakika boyunca önbellekte tut
    await redisClient.setEx(conversationKey, 600, JSON.stringify(messages));
    console.log(`💾 Konuşma önbelleğe alındı: ${conversationKey}`);
    return true;
  } catch (error) {
    console.error('Redis cacheConversation error:', error);
    return false;
  }
};

/**
 * Önbellekteki konuşmayı getir
 * @param {string} userId1 - İlk kullanıcı ID
 * @param {string} userId2 - İkinci kullanıcı ID
 * @returns {Promise<Array|null>} Mesaj dizisi veya null
 */
const getCachedConversation = async (userId1, userId2) => {
  try {
    const conversationKey = `chat:${Math.min(userId1, userId2)}_${Math.max(userId1, userId2)}`;
    const cached = await redisClient.get(conversationKey);
    
    if (cached) {
      console.log(`📦 Konuşma önbellekten geldi: ${conversationKey}`);
      return JSON.parse(cached);
    }
    return null;
  } catch (error) {
    console.error('Redis getCachedConversation error:', error);
    return null;
  }
};

/**
 * Konuşma önbelleğini temizle
 * @param {string} userId1 - İlk kullanıcı ID
 * @param {string} userId2 - İkinci kullanıcı ID
 */
const clearConversationCache = async (userId1, userId2) => {
  try {
    const conversationKey = `chat:${Math.min(userId1, userId2)}_${Math.max(userId1, userId2)}`;
    await redisClient.del(conversationKey);
    console.log(`🗑️ Konuşma önbelleği temizlendi: ${conversationKey}`);
    return true;
  } catch (error) {
    console.error('Redis clearConversationCache error:', error);
    return false;
  }
};

// ==================== YAZIYOR BİLDİRİMİ ====================

/**
 * Kullanıcının yazma durumunu kaydet
 * @param {string} userId - Yazan kullanıcı ID
 * @param {string} receiverId - Alıcı kullanıcı ID
 */
const setUserTyping = async (userId, receiverId) => {
  try {
    const key = `typing:${userId}:${receiverId}`;
    // 5 saniye sonra otomatik sil
    await redisClient.setEx(key, 5, 'true');
    return true;
  } catch (error) {
    console.error('Redis setUserTyping error:', error);
    return false;
  }
};

/**
 * Kullanıcının yazma durumunu kontrol et
 * @param {string} userId - Kontrol edilecek kullanıcı ID
 * @param {string} receiverId - Alıcı kullanıcı ID
 */
const isUserTyping = async (userId, receiverId) => {
  try {
    const key = `typing:${userId}:${receiverId}`;
    const result = await redisClient.get(key);
    return result === 'true';
  } catch (error) {
    console.error('Redis isUserTyping error:', error);
    return false;
  }
};

module.exports = {
  redisClient,
  // Kullanıcı durum yönetimi
  setUserOnline,
  getUserStatus,
  removeUserOnline,
  getAllOnlineUsers,
  // Mesaj önbellekleme
  cacheConversation,
  getCachedConversation,
  clearConversationCache,
  // Yazıyor bildirimi
  setUserTyping,
  isUserTyping
};
