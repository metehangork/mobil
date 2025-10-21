const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../db/pool');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// ==================== MATCH ALGORITHM ====================

/**
 * @route   POST /api/matches/find
 * @desc    Find matches based on courses, school, department, interests
 * @access  Private
 */
router.post('/find', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    
    // Get user's profile and preferences
    const userProfile = await query(
      `SELECT u.id, u.school_id, u.department_id, u.gender, u.birth_date, u.city,
              u.study_level, u.graduation_year,
              mp.prefer_same_gender, mp.prefer_same_city, mp.prefer_same_year,
              mp.min_compatibility_score, mp.max_distance_km, mp.match_types, mp.is_active,
              up.interests, up.hobbies, up.location
       FROM users u
       LEFT JOIN match_preferences mp ON u.id = mp.user_id
       LEFT JOIN user_profiles up ON u.id = up.user_id
       WHERE u.id = $1`,
      [userId]
    );
    
    if (userProfile.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Kullanıcı bulunamadı'
      });
    }
    
    const user = userProfile.rows[0];
    const preferences = {
      preferSameGender: user.prefer_same_gender !== false,
      preferSameCity: user.prefer_same_city !== false,
      preferSameYear: user.prefer_same_year !== false,
      minCompatibility: user.min_compatibility_score || 0,
      matchTypes: user.match_types || ['course_based', 'hobby_based']
    };
    
    // Get user's courses
    const userCourses = await query(
      `SELECT course_id FROM user_courses 
       WHERE user_id = $1 AND status = 'taking'`,
      [userId]
    );
    
    const courseIds = userCourses.rows.map(r => r.course_id);
    
    if (courseIds.length === 0) {
      return res.json({
        success: true,
        message: 'Önce ders eklemelisiniz',
        matches: []
      });
    }
    
    // Complex matching query
    const matchQuery = `
      WITH user_courses_list AS (
        SELECT course_id FROM user_courses WHERE user_id = $1 AND status = 'taking'
      ),
      potential_matches AS (
        SELECT 
          u.id,
          u.email,
          u.first_name,
          u.last_name,
          u.gender,
          u.birth_date,
          u.profile_photo_url,
          u.school_id,
          u.department_id,
          u.city,
          u.study_level,
          u.graduation_year,
          s.name as school_name,
          d.name as department_name,
          up.interests,
          up.hobbies,
          -- Count common courses
          (SELECT COUNT(*) FROM user_courses uc 
           WHERE uc.user_id = u.id 
           AND uc.status = 'taking'
           AND uc.course_id IN (SELECT course_id FROM user_courses_list)
          ) as common_course_count,
          -- Get common course IDs
          ARRAY(
            SELECT uc.course_id FROM user_courses uc
            WHERE uc.user_id = u.id 
            AND uc.status = 'taking'
            AND uc.course_id IN (SELECT course_id FROM user_courses_list)
          ) as common_course_ids
        FROM users u
        LEFT JOIN schools s ON u.school_id = s.id
        LEFT JOIN departments d ON u.department_id = d.id
        LEFT JOIN user_profiles up ON u.id = up.user_id
        WHERE u.id != $1
          AND u.is_verified = true
          AND EXISTS (
            SELECT 1 FROM user_courses uc 
            WHERE uc.user_id = u.id 
            AND uc.status = 'taking'
            AND uc.course_id IN (SELECT course_id FROM user_courses_list)
          )
          ${user.school_id ? 'AND u.school_id = $2' : ''}
          ${preferences.preferSameGender && user.gender ? 'AND u.gender = $3' : ''}
          ${preferences.preferSameCity && user.city ? 'AND u.city = $4' : ''}
          ${preferences.preferSameYear && user.graduation_year ? 'AND u.graduation_year = $5' : ''}
      ),
      match_scores AS (
        SELECT 
          pm.*,
          -- Course compatibility (0-100)
          (pm.common_course_count::float / NULLIF((SELECT COUNT(*) FROM user_courses_list), 0) * 100) as course_compatibility,
          -- Calculate interest overlap (simple JSON array overlap)
          CASE 
            WHEN pm.interests IS NOT NULL AND $6::jsonb IS NOT NULL THEN
              (SELECT COUNT(*) FROM jsonb_array_elements_text(pm.interests) interest
               WHERE interest IN (SELECT jsonb_array_elements_text($6::jsonb)))
            ELSE 0
          END as common_interests_count,
          -- Same school bonus
          CASE WHEN pm.school_id = $7 THEN 20 ELSE 0 END as school_bonus,
          -- Same department bonus
          CASE WHEN pm.department_id = $8 THEN 15 ELSE 0 END as department_bonus,
          -- Same study level bonus
          CASE WHEN pm.study_level = $9 THEN 10 ELSE 0 END as study_level_bonus
        FROM potential_matches pm
      )
      SELECT 
        ms.*,
        -- Final compatibility score (weighted average)
        LEAST(100, ROUND(
          (ms.course_compatibility * 0.5) +  -- 50% weight on courses
          (ms.common_interests_count * 5) +   -- 5 points per common interest
          ms.school_bonus +
          ms.department_bonus +
          ms.study_level_bonus
        )) as compatibility_score
      FROM match_scores ms
      WHERE ms.course_compatibility >= $10
      ORDER BY compatibility_score DESC, common_course_count DESC
      LIMIT 50
    `;
    
    const params = [
      userId,
      user.school_id || null,
      user.gender || null,
      user.city || null,
      user.graduation_year || null,
      user.interests || null,
      user.school_id || null,
      user.department_id || null,
      user.study_level || null,
      preferences.minCompatibility
    ];
    
    const matchResults = await query(matchQuery, params);
    
    // Get course details for matched courses
    const matches = await Promise.all(matchResults.rows.map(async (match) => {
      const coursesResult = await query(
        `SELECT c.id, c.code, c.name 
         FROM courses c 
         WHERE c.id = ANY($1::int[])`,
        [match.common_course_ids]
      );
      
      return {
        id: match.id,
        user: {
          id: match.id,
          email: match.email,
          firstName: match.first_name,
          lastName: match.last_name,
          gender: match.gender,
          profilePhotoUrl: match.profile_photo_url,
          schoolName: match.school_name,
          departmentName: match.department_name,
          studyLevel: match.study_level,
          graduationYear: match.graduation_year
        },
        compatibilityScore: parseInt(match.compatibility_score),
        commonCourseCount: parseInt(match.common_course_count),
        commonCourses: coursesResult.rows,
        commonInterestsCount: parseInt(match.common_interests_count || 0),
        matchReason: generateMatchReason(match),
        matchedAt: new Date().toISOString()
      };
    }));
    
    // Save matches to database
    for (const match of matches) {
      try {
        await query(
          `INSERT INTO matches (user1_id, user2_id, matching_algorithm_version, matched_courses,
                                compatibility_score, common_interests, match_reason, status, created_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
           ON CONFLICT (user1_id, user2_id) 
           DO UPDATE SET 
             compatibility_score = $5,
             matched_courses = $4,
             common_interests = $6,
             match_reason = $7,
             updated_at = NOW()`,
          [
            userId,
            match.id,
            '1.0',
            JSON.stringify(match.commonCourses.map(c => c.id)),
            match.compatibilityScore,
            JSON.stringify([]),
            match.matchReason,
            'pending'
          ]
        );
      } catch (err) {
        console.error('❌ Match kaydetme hatası:', err);
      }
    }
    
    res.json({
      success: true,
      count: matches.length,
      matches
    });
  } catch (error) {
    console.error('❌ Match finding error:', error);
    res.status(500).json({
      success: false,
      error: 'Eşleştirme yapılamadı'
    });
  }
});

/**
 * @route   GET /api/matches
 * @desc    Get all matches for current user
 * @access  Private
 */
router.get('/', authenticateToken, async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const userId = req.user.userId;
    
    let sqlQuery = `
      SELECT 
        m.id,
        m.user1_id,
        m.user2_id,
        m.compatibility_score,
        m.matched_courses,
        m.common_interests,
        m.match_reason,
        m.status,
        m.viewed_by_user1,
        m.viewed_by_user2,
        m.user1_feedback,
        m.user2_feedback,
        m.created_at,
        u.id as matched_user_id,
        u.email,
        u.first_name,
        u.last_name,
        u.profile_photo_url,
        u.school_id,
        s.name as school_name,
        u.department_id,
        d.name as department_name,
        u.bio,
        up.interests,
        up.hobbies
      FROM matches m
      JOIN users u ON (
        CASE 
          WHEN m.user1_id = $1 THEN m.user2_id
          WHEN m.user2_id = $1 THEN m.user1_id
        END = u.id
      )
      LEFT JOIN schools s ON u.school_id = s.id
      LEFT JOIN departments d ON u.department_id = d.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      WHERE (m.user1_id = $1 OR m.user2_id = $1)
    `;
    
    let params = [userId];
    let paramIndex = 2;
    
    if (status) {
      sqlQuery += ` AND m.status = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }
    
    sqlQuery += ` ORDER BY m.compatibility_score DESC, m.created_at DESC`;
    sqlQuery += ` LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(parseInt(limit), parseInt(offset));
    
    const result = await query(sqlQuery, params);
    
    // Get course details
    const matches = await Promise.all(result.rows.map(async (row) => {
      const courseIds = row.matched_courses || [];
      const coursesResult = await query(
        `SELECT id, code, name FROM courses WHERE id = ANY($1::int[])`,
        [courseIds]
      );
      
      return {
        id: row.id,
        matchedUser: {
          id: row.matched_user_id,
          email: row.email,
          firstName: row.first_name,
          lastName: row.last_name,
          profilePhotoUrl: row.profile_photo_url,
          schoolName: row.school_name,
          departmentName: row.department_name,
          bio: row.bio,
          interests: row.interests,
          hobbies: row.hobbies
        },
        compatibilityScore: parseInt(row.compatibility_score),
        commonCourses: coursesResult.rows,
        matchReason: row.match_reason,
        status: row.status,
        viewedByMe: row.user1_id === userId ? row.viewed_by_user1 : row.viewed_by_user2,
        myFeedback: row.user1_id === userId ? row.user1_feedback : row.user2_feedback,
        createdAt: row.created_at
      };
    }));
    
    res.json({
      success: true,
      count: matches.length,
      matches
    });
  } catch (error) {
    console.error('❌ Get matches error:', error);
    res.status(500).json({
      success: false,
      error: 'Eşleşmeler getirilemedi'
    });
  }
});

/**
 * @route   PATCH /api/matches/:id/action
 * @desc    Accept or reject a match
 * @access  Private
 */
router.patch('/:id/action', [
  authenticateToken,
  body('action').isIn(['accept', 'reject', 'block']).withMessage('Geçersiz aksiyon')
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { id } = req.params;
    const { action } = req.body;
    const userId = req.user.userId;
    
    // Get match
    const matchResult = await query(
      `SELECT * FROM matches WHERE id = $1 AND (user1_id = $2 OR user2_id = $2)`,
      [id, userId]
    );
    
    if (matchResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Eşleşme bulunamadı'
      });
    }
    
    const match = matchResult.rows[0];
    const isUser1 = match.user1_id === userId;
    const feedbackField = isUser1 ? 'user1_feedback' : 'user2_feedback';
    const viewedField = isUser1 ? 'viewed_by_user1' : 'viewed_by_user2';
    
    let newStatus = match.status;
    if (action === 'accept') {
      // Check if other user also accepted
      const otherFeedback = isUser1 ? match.user2_feedback : match.user1_feedback;
      if (otherFeedback === 'accepted') {
        newStatus = 'matched';
        
        // Create conversation if both accepted
        const convResult = await query(
          `INSERT INTO conversations (match_id, conversation_type, created_at)
           VALUES ($1, 'direct', NOW())
           RETURNING id`,
          [match.id]
        );
        
        const conversationId = convResult.rows[0].id;
        
        // Add both users as participants
        await query(
          `INSERT INTO conversation_participants (conversation_id, user_id, role, joined_at)
           VALUES ($1, $2, 'member', NOW()), ($1, $3, 'member', NOW())`,
          [conversationId, match.user1_id, match.user2_id]
        );
      }
    } else if (action === 'reject') {
      newStatus = 'rejected';
    } else if (action === 'block') {
      newStatus = 'blocked';
      
      // Add to blocked users
      await query(
        `INSERT INTO blocked_users (blocker_id, blocked_user_id, blocked_at)
         VALUES ($1, $2, NOW())
         ON CONFLICT DO NOTHING`,
        [userId, isUser1 ? match.user2_id : match.user1_id]
      );
    }
    
    // Update match
    await query(
      `UPDATE matches 
       SET ${feedbackField} = $1,
           ${viewedField} = true,
           status = $2,
           updated_at = NOW()
       WHERE id = $3`,
      [action === 'accept' ? 'accepted' : 'rejected', newStatus, id]
    );
    
    // Record action in match_history
    await query(
      `INSERT INTO match_history (match_id, action_type, actor_user_id, action_at)
       VALUES ($1, $2, $3, NOW())`,
      [id, action, userId]
    );
    
    res.json({
      success: true,
      message: `Eşleşme ${action === 'accept' ? 'kabul edildi' : action === 'reject' ? 'reddedildi' : 'engellendi'}`,
      status: newStatus
    });
  } catch (error) {
    console.error('❌ Match action error:', error);
    res.status(500).json({
      success: false,
      error: 'İşlem başarısız'
    });
  }
});

/**
 * @route   GET /api/matches/:id
 * @desc    Get single match detail
 * @access  Private
 */
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    
    const result = await query(
      `SELECT 
        m.*,
        u.id as matched_user_id,
        u.email,
        u.first_name,
        u.last_name,
        u.profile_photo_url,
        u.bio,
        u.school_id,
        s.name as school_name,
        u.department_id,
        d.name as department_name,
        up.about_me,
        up.interests,
        up.hobbies,
        up.skills
       FROM matches m
       JOIN users u ON (
         CASE 
           WHEN m.user1_id = $2 THEN m.user2_id
           WHEN m.user2_id = $2 THEN m.user1_id
         END = u.id
       )
       LEFT JOIN schools s ON u.school_id = s.id
       LEFT JOIN departments d ON u.department_id = d.id
       LEFT JOIN user_profiles up ON u.id = up.user_id
       WHERE m.id = $1 AND (m.user1_id = $2 OR m.user2_id = $2)`,
      [id, userId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Eşleşme bulunamadı'
      });
    }
    
    const row = result.rows[0];
    
    // Mark as viewed
    const isUser1 = row.user1_id === userId;
    const viewedField = isUser1 ? 'viewed_by_user1' : 'viewed_by_user2';
    await query(
      `UPDATE matches SET ${viewedField} = true, updated_at = NOW() WHERE id = $1`,
      [id]
    );
    
    // Get course details
    const courseIds = row.matched_courses || [];
    const coursesResult = await query(
      `SELECT id, code, name, semester, credits 
       FROM courses WHERE id = ANY($1::int[])`,
      [courseIds]
    );
    
    res.json({
      success: true,
      match: {
        id: row.id,
        matchedUser: {
          id: row.matched_user_id,
          email: row.email,
          firstName: row.first_name,
          lastName: row.last_name,
          profilePhotoUrl: row.profile_photo_url,
          bio: row.bio,
          schoolName: row.school_name,
          departmentName: row.department_name,
          aboutMe: row.about_me,
          interests: row.interests,
          hobbies: row.hobbies,
          skills: row.skills
        },
        compatibilityScore: parseInt(row.compatibility_score),
        commonCourses: coursesResult.rows,
        matchReason: row.match_reason,
        status: row.status,
        createdAt: row.created_at
      }
    });
  } catch (error) {
    console.error('❌ Match detail error:', error);
    res.status(500).json({
      success: false,
      error: 'Eşleşme detayı getirilemedi'
    });
  }
});

// Helper function to generate match reason
function generateMatchReason(match) {
  const reasons = [];
  
  if (match.common_course_count > 0) {
    reasons.push(`${match.common_course_count} ortak ders`);
  }
  
  if (match.school_bonus > 0) {
    reasons.push('Aynı okul');
  }
  
  if (match.department_bonus > 0) {
    reasons.push('Aynı bölüm');
  }
  
  if (match.common_interests_count > 0) {
    reasons.push(`${match.common_interests_count} ortak ilgi alanı`);
  }
  
  return reasons.join(', ') || 'Ortak dersler';
}

module.exports = router;
