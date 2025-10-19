const express = require('express');
const { query } = require('../db/pool');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// ==================== NOTIFICATIONS API ====================

/**
 * @route   GET /api/notifications
 * @desc    Get user's notifications
 * @access  Private
 */
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { page = 1, limit = 20, unreadOnly = false } = req.query;
    const offset = (page - 1) * limit;
    
    let sqlQuery = `
      SELECT n.id, n.user_id, n.sender_id, n.notification_type, n.title, n.message,
             n.action_type, n.target_type, n.target_id, n.data, n.image_url, n.deep_link,
             n.is_read, n.read_at, n.clicked_at, n.created_at, n.expires_at,
             u.first_name as sender_first_name, u.last_name as sender_last_name,
             u.profile_photo_url as sender_photo
      FROM notifications n
      LEFT JOIN users u ON n.sender_id = u.id
      WHERE n.user_id = $1
    `;
    
    let params = [req.user.userId];
    let paramIndex = 2;
    
    if (unreadOnly === 'true') {
      sqlQuery += ` AND n.is_read = false`;
    }
    
    sqlQuery += ` ORDER BY n.created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(parseInt(limit), parseInt(offset));
    
    const result = await query(sqlQuery, params);
    
    res.json({
      success: true,
      count: result.rows.length,
      notifications: result.rows
    });
  } catch (error) {
    console.error('❌ Notifications error:', error);
    res.status(500).json({ success: false, error: 'Bildirimler getirilemedi' });
  }
});

/**
 * @route   GET /api/notifications/unread/count
 * @desc    Get unread notifications count
 * @access  Private
 */
router.get('/unread/count', authenticateToken, async (req, res) => {
  try {
    const result = await query(
      `SELECT COUNT(*) as count FROM notifications WHERE user_id = $1 AND is_read = false`,
      [req.user.userId]
    );
    
    res.json({
      success: true,
      unreadCount: parseInt(result.rows[0].count)
    });
  } catch (error) {
    console.error('❌ Unread count error:', error);
    res.status(500).json({ success: false, error: 'Sayı getirilemedi' });
  }
});

/**
 * @route   PATCH /api/notifications/:id/read
 * @desc    Mark notification as read
 * @access  Private
 */
router.patch('/:id/read', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await query(
      `UPDATE notifications 
       SET is_read = true, read_at = NOW()
       WHERE id = $1 AND user_id = $2
       RETURNING *`,
      [id, req.user.userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Bildirim bulunamadı' });
    }
    
    res.json({ success: true, message: 'Bildirim okundu olarak işaretlendi' });
  } catch (error) {
    console.error('❌ Mark read error:', error);
    res.status(500).json({ success: false, error: 'Güncelleme başarısız' });
  }
});

/**
 * @route   POST /api/notifications/mark-all-read
 * @desc    Mark all notifications as read
 * @access  Private
 */
router.post('/mark-all-read', authenticateToken, async (req, res) => {
  try {
    await query(
      `UPDATE notifications 
       SET is_read = true, read_at = NOW()
       WHERE user_id = $1 AND is_read = false`,
      [req.user.userId]
    );
    
    res.json({ success: true, message: 'Tüm bildirimler okundu olarak işaretlendi' });
  } catch (error) {
    console.error('❌ Mark all read error:', error);
    res.status(500).json({ success: false, error: 'Güncelleme başarısız' });
  }
});

/**
 * @route   DELETE /api/notifications/:id
 * @desc    Delete notification
 * @access  Private
 */
router.delete('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await query(
      `DELETE FROM notifications WHERE id = $1 AND user_id = $2 RETURNING id`,
      [id, req.user.userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Bildirim bulunamadı' });
    }
    
    res.json({ success: true, message: 'Bildirim silindi' });
  } catch (error) {
    console.error('❌ Delete notification error:', error);
    res.status(500).json({ success: false, error: 'Silme başarısız' });
  }
});

/**
 * Helper function to create notification
 * Call this from other routes when needed
 */
async function createNotification({
  userId, senderId, notificationType, title, message,
  actionType, targetType, targetId, data, imageUrl, deepLink
}) {
  try {
    await query(
      `INSERT INTO notifications (user_id, sender_id, notification_type, title, message,
                                   action_type, target_type, target_id, data, image_url, deep_link, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())`,
      [userId, senderId || null, notificationType, title, message,
       actionType || null, targetType || null, targetId || null,
       data ? JSON.stringify(data) : null, imageUrl || null, deepLink || null]
    );
  } catch (error) {
    console.error('❌ Create notification error:', error);
  }
}

module.exports = router;
module.exports.createNotification = createNotification;
