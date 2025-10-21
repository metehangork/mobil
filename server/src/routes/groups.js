const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../db/pool');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// ==================== STUDY GROUPS API ====================

/**
 * @route   GET /api/groups
 * @desc    Get all groups or search groups
 * @access  Private
 */
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { search, groupType, courseId, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    
    let sqlQuery = `
      SELECT g.id, g.name, g.description, g.group_type, g.course_id, g.created_by,
             g.max_members, g.current_members_count, g.cover_image_url, g.is_active, g.created_at,
             c.name as course_name, c.code as course_code,
             u.first_name as creator_first_name, u.last_name as creator_last_name
      FROM study_groups g
      LEFT JOIN courses c ON g.course_id = c.id
      LEFT JOIN users u ON g.created_by = u.id
      WHERE g.is_active = true
    `;
    
    let params = [];
    let paramIndex = 1;
    
    if (groupType) {
      sqlQuery += ` AND g.group_type = $${paramIndex}`;
      params.push(groupType);
      paramIndex++;
    }
    
    if (courseId) {
      sqlQuery += ` AND g.course_id = $${paramIndex}`;
      params.push(parseInt(courseId));
      paramIndex++;
    }
    
    if (search && search.trim().length >= 2) {
      sqlQuery += ` AND (g.name ILIKE $${paramIndex} OR g.description ILIKE $${paramIndex})`;
      params.push(`%${search.trim()}%`);
      paramIndex++;
    }
    
    sqlQuery += ` ORDER BY g.created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(parseInt(limit), parseInt(offset));
    
    const result = await query(sqlQuery, params);
    
    res.json({
      success: true,
      count: result.rows.length,
      groups: result.rows
    });
  } catch (error) {
    console.error('❌ Groups list error:', error);
    res.status(500).json({ success: false, error: 'Gruplar getirilemedi' });
  }
});

/**
 * @route   POST /api/groups
 * @desc    Create new study group
 * @access  Private
 */
router.post('/', [
  authenticateToken,
  body('name').trim().isLength({ min: 3, max: 100 }).withMessage('Grup adı 3-100 karakter olmalı'),
  body('description').optional().isLength({ max: 500 }),
  body('groupType').isIn(['public', 'private', 'course_specific']),
  body('courseId').optional().isInt(),
  body('maxMembers').optional().isInt({ min: 2, max: 100 })
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { name, description, groupType, courseId, maxMembers, meetingLink, coverImageUrl } = req.body;
    
    const result = await query(
      `INSERT INTO study_groups (name, description, created_by, course_id, group_type,
                                  max_members, current_members_count, cover_image_url, meeting_link, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, 1, $7, $8, NOW())
       RETURNING *`,
      [name, description || null, req.user.userId, courseId || null, groupType,
       maxMembers || 50, coverImageUrl || null, meetingLink || null]
    );
    
    const groupId = result.rows[0].id;
    
    // Add creator as admin member
    await query(
      `INSERT INTO group_members (group_id, user_id, role, invitation_status, joined_at)
       VALUES ($1, $2, 'admin', 'accepted', NOW())`,
      [groupId, req.user.userId]
    );
    
    res.status(201).json({
      success: true,
      message: 'Grup oluşturuldu',
      group: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Create group error:', error);
    res.status(500).json({ success: false, error: 'Grup oluşturulamadı' });
  }
});

/**
 * @route   GET /api/groups/:id
 * @desc    Get single group details
 * @access  Private
 */
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await query(
      `SELECT g.*, c.name as course_name, c.code as course_code,
              u.first_name as creator_first_name, u.last_name as creator_last_name
       FROM study_groups g
       LEFT JOIN courses c ON g.course_id = c.id
       LEFT JOIN users u ON g.created_by = u.id
       WHERE g.id = $1`,
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Grup bulunamadı' });
    }
    
    res.json({ success: true, group: result.rows[0] });
  } catch (error) {
    console.error('❌ Group detail error:', error);
    res.status(500).json({ success: false, error: 'Grup detayı getirilemedi' });
  }
});

/**
 * @route   POST /api/groups/:id/join
 * @desc    Join a study group
 * @access  Private
 */
router.post('/:id/join', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    
    // Check if group exists and has space
    const groupResult = await query(
      `SELECT * FROM study_groups WHERE id = $1 AND is_active = true`,
      [id]
    );
    
    if (groupResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Grup bulunamadı' });
    }
    
    const group = groupResult.rows[0];
    
    if (group.current_members_count >= group.max_members) {
      return res.status(400).json({ success: false, error: 'Grup dolu' });
    }
    
    // Check if already member
    const memberCheck = await query(
      `SELECT id FROM group_members WHERE group_id = $1 AND user_id = $2`,
      [id, userId]
    );
    
    if (memberCheck.rows.length > 0) {
      return res.status(400).json({ success: false, error: 'Zaten üyesiniz' });
    }
    
    // Add member
    await query(
      `INSERT INTO group_members (group_id, user_id, role, invitation_status, joined_at)
       VALUES ($1, $2, 'member', 'accepted', NOW())`,
      [id, userId]
    );
    
    // Update member count
    await query(
      `UPDATE study_groups SET current_members_count = current_members_count + 1 WHERE id = $1`,
      [id]
    );
    
    res.json({ success: true, message: 'Gruba katıldınız' });
  } catch (error) {
    console.error('❌ Join group error:', error);
    res.status(500).json({ success: false, error: 'Gruba katılınamadı' });
  }
});

/**
 * @route   POST /api/groups/:id/leave
 * @desc    Leave a study group
 * @access  Private
 */
router.post('/:id/leave', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    
    const result = await query(
      `DELETE FROM group_members WHERE group_id = $1 AND user_id = $2 RETURNING id`,
      [id, userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Üyelik bulunamadı' });
    }
    
    // Update member count
    await query(
      `UPDATE study_groups SET current_members_count = current_members_count - 1 WHERE id = $1`,
      [id]
    );
    
    res.json({ success: true, message: 'Gruptan ayrıldınız' });
  } catch (error) {
    console.error('❌ Leave group error:', error);
    res.status(500).json({ success: false, error: 'Gruptan ayrılınamadı' });
  }
});

/**
 * @route   GET /api/groups/:id/members
 * @desc    Get group members
 * @access  Private
 */
router.get('/:id/members', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await query(
      `SELECT gm.role, gm.joined_at,
              u.id, u.email, u.first_name, u.last_name, u.profile_photo_url
       FROM group_members gm
       JOIN users u ON gm.user_id = u.id
       WHERE gm.group_id = $1
       ORDER BY 
         CASE gm.role
           WHEN 'admin' THEN 1
           WHEN 'moderator' THEN 2
           ELSE 3
         END,
         gm.joined_at ASC`,
      [id]
    );
    
    res.json({ success: true, count: result.rows.length, members: result.rows });
  } catch (error) {
    console.error('❌ Group members error:', error);
    res.status(500).json({ success: false, error: 'Üyeler getirilemedi' });
  }
});

module.exports = router;
