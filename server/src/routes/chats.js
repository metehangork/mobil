const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../db/pool');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

router.use(authenticateToken);

// List current user's conversations with last message, unread count, participant ids
router.get('/', async (req, res, next) => {
  try {
    const userId = parseInt(req.user.userId, 10);
    if (Number.isNaN(userId)) return res.status(400).json({ error: 'Geçersiz kullanıcı kimliği' });
    // Conversations are tied to matches in schema; include both directions
    const sql = `
      SELECT c.id as conversation_id,
             m.user1_id, m.user2_id, m.match_type, m.status,
             c.last_message_at,
             COALESCE(lm.message_text, '') as last_message_text,
             COALESCE(unread.cnt, 0) as unread_count
      FROM conversations c
      JOIN matches m ON m.id = c.match_id
      LEFT JOIN LATERAL (
        SELECT message_text
        FROM messages msg
        WHERE msg.conversation_id = c.id
        ORDER BY msg.created_at DESC
        LIMIT 1
      ) lm ON true
      LEFT JOIN LATERAL (
        SELECT COUNT(*)::int as cnt
        FROM messages um
        WHERE um.conversation_id = c.id AND um.sender_id <> $1 AND um.is_read = false
      ) unread ON true
      WHERE (m.user1_id = $1 OR m.user2_id = $1)
      ORDER BY c.last_message_at DESC NULLS LAST, c.id DESC
    `;
    const { rows } = await query(sql, [userId]);
    res.json(rows.map(r => ({
      id: r.conversation_id,
      user1Id: r.user1_id,
      user2Id: r.user2_id,
      matchType: r.match_type,
      status: r.status,
      lastMessageAt: r.last_message_at,
      lastMessageText: r.last_message_text,
      unreadCount: r.unread_count,
      otherUserId: r.user1_id === userId ? r.user2_id : r.user1_id,
    })));
  } catch (e) { next(e); }
});

// Ensure a conversation exists between current user and target user (by userId) and return it
router.post('/ensure', [body('otherUserId').isInt()], async (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  const userId = parseInt(req.user.userId, 10);
  if (Number.isNaN(userId)) return res.status(400).json({ error: 'Geçersiz kullanıcı kimliği' });
  const otherUserId = parseInt(req.body.otherUserId, 10);
  if (userId === otherUserId) return res.status(400).json({ error: 'Kendinizle konuşma açılamaz' });
  try {
    // Try to find an existing match regardless of order
    const findExisting = await query(
      'SELECT * FROM matches WHERE (user1_id = $1 AND user2_id = $2) OR (user1_id = $2 AND user2_id = $1) LIMIT 1',
      [userId, otherUserId]
    );
    let matchId;
    if (findExisting.rows.length) {
      matchId = findExisting.rows[0].id;
    } else {
      // Create ordered pair to satisfy UNIQUE(user1_id,user2_id)
      const pair = userId < otherUserId ? [userId, otherUserId] : [otherUserId, userId];
      const insertMatch = `
        INSERT INTO matches (user1_id, user2_id, match_type, match_score, status)
        VALUES ($1, $2, 'direct', 1.0, 'accepted')
        RETURNING *
      `;
      const mres = await query(insertMatch, pair);
      matchId = mres.rows[0].id;
    }
    // Find or create conversation
    const findConv = await query('SELECT * FROM conversations WHERE match_id = $1 LIMIT 1', [matchId]);
    let conv;
    if (findConv.rows.length) {
      conv = findConv.rows[0];
    } else {
      const cins = await query('INSERT INTO conversations (match_id) VALUES ($1) RETURNING *', [matchId]);
      conv = cins.rows[0];
    }
    res.json({ id: conv.id, matchId: matchId });
  } catch (e) { next(e); }
});

// Get messages in a conversation (paginated)
router.get('/:conversationId/messages', async (req, res, next) => {
  try {
    const userId = parseInt(req.user.userId, 10);
    if (Number.isNaN(userId)) return res.status(400).json({ error: 'Geçersiz kullanıcı kimliği' });
    const conversationId = parseInt(req.params.conversationId, 10);
    const limit = Math.min(parseInt(req.query.limit || '50', 10), 100);
    const before = req.query.before ? new Date(req.query.before) : null;

    // Ensure user belongs to conversation via matches
    const own = await query(`
      SELECT 1
      FROM conversations c
      JOIN matches m ON m.id = c.match_id
      WHERE c.id = $1 AND ($2 = m.user1_id OR $2 = m.user2_id)
    `, [conversationId, userId]);
    if (!own.rows.length) return res.status(403).json({ error: 'Bu konuşmaya erişim yok' });

    const params = [conversationId];
    let whereExtra = '';
    if (before) { params.push(before); whereExtra = 'AND created_at < $2'; }
    const sql = `
      SELECT id, sender_id, message_text, message_type, is_read, created_at
      FROM messages
      WHERE conversation_id = $1 ${whereExtra}
      ORDER BY created_at DESC
      LIMIT ${limit}
    `;
    const { rows } = await query(sql, params);
    res.json(rows);
  } catch (e) { next(e); }
});

// Send a message
router.post('/:conversationId/messages', [
  body('text').isString().isLength({ min: 1 }).withMessage('Mesaj metni gerekli'),
  body('type').optional().isIn(['text','image','file'])
], async (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  try {
    const userId = parseInt(req.user.userId, 10);
    if (Number.isNaN(userId)) return res.status(400).json({ error: 'Geçersiz kullanıcı kimliği' });
    const conversationId = parseInt(req.params.conversationId, 10);
    const text = req.body.text;
    const type = req.body.type || 'text';

    const own = await query(`
      SELECT c.id FROM conversations c
      JOIN matches m ON m.id = c.match_id
      WHERE c.id = $1 AND ($2 = m.user1_id OR $2 = m.user2_id)
    `, [conversationId, userId]);
    if (!own.rows.length) return res.status(403).json({ error: 'Bu konuşmaya erişim yok' });

    const ins = await query(`
      INSERT INTO messages (conversation_id, sender_id, message_text, message_type)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [conversationId, userId, text, type]);
    await query('UPDATE conversations SET last_message_at = NOW() WHERE id = $1', [conversationId]);
    res.status(201).json(ins.rows[0]);
  } catch (e) { next(e); }
});

// Mark messages as read up to a timestamp
router.post('/:conversationId/read', [
  body('upTo').optional().isISO8601()
], async (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
  try {
    const userId = parseInt(req.user.userId, 10);
    if (Number.isNaN(userId)) return res.status(400).json({ error: 'Geçersiz kullanıcı kimliği' });
    const conversationId = parseInt(req.params.conversationId, 10);
    const upTo = req.body.upTo ? new Date(req.body.upTo) : null;

    const own = await query(`
      SELECT c.id FROM conversations c
      JOIN matches m ON m.id = c.match_id
      WHERE c.id = $1 AND ($2 = m.user1_id OR $2 = m.user2_id)
    `, [conversationId, userId]);
    if (!own.rows.length) return res.status(403).json({ error: 'Bu konuşmaya erişim yok' });

    const params = [conversationId, userId];
    let whereExtra = '';
    if (upTo) { params.push(upTo); whereExtra = 'AND created_at <= $3'; }
    const sql = `
      UPDATE messages
      SET is_read = true
      WHERE conversation_id = $1 AND sender_id <> $2 ${whereExtra}
    `;
    await query(sql, params);
    res.json({ ok: true });
  } catch (e) { next(e); }
});

module.exports = router;
