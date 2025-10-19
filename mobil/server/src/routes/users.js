const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../db/pool');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// ==================== USER PROFILE ROUTES ====================

/**
 * @route   GET /api/users/me
 * @desc    Get current user's full profile
 * @access  Private
 */
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const result = await query(
      `SELECT 
        u.id, u.email, u.first_name, u.last_name, u.gender, u.birth_date,
        u.phone_number, u.profile_photo_url, u.cover_image_url, u.bio,
        u.school_id, s.name as school_name, s.city as school_city,
        u.department_id, d.name as department_name,
        u.student_number, u.university_email, u.graduation_year, u.enrollment_year,
        u.study_level, u.is_verified, u.is_premium, u.premium_expires_at,
        u.last_seen_at, u.is_online, u.language, u.timezone,
        u.created_at, u.updated_at,
        up.about_me, up.interests, up.hobbies, up.skills, up.social_links,
        up.website, up.location, up.blood_type, up.hometown,
        us.privacy_profile, us.privacy_courses, us.privacy_phone, us.privacy_email,
        us.notification_match, us.notification_message, us.notification_comment,
        us.notification_email, us.notification_push, us.theme_mode, us.language_preference
      FROM users u
      LEFT JOIN schools s ON u.school_id = s.id
      LEFT JOIN departments d ON u.department_id = d.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN user_settings us ON u.id = us.user_id
      WHERE u.id = $1`,
      [req.user.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
    }

    res.json({ user: result.rows[0] });
  } catch (error) {
    console.error('❌ Profil getirme hatası:', error);
    res.status(500).json({ error: 'Profil yüklenemedi' });
  }
});

/**
 * @route   GET /api/users/:id
 * @desc    Get another user's public profile
 * @access  Private
 */
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    // Check privacy settings first
    const privacyCheck = await query(
      `SELECT 
        u.id, u.email, u.first_name, u.last_name, u.profile_photo_url,
        u.school_id, u.department_id, u.bio, u.is_verified,
        us.privacy_profile
      FROM users u
      LEFT JOIN user_settings us ON u.id = us.user_id
      WHERE u.id = $1`,
      [id]
    );

    if (privacyCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Kullanıcı bulunamadı' });
    }

    const privacySetting = privacyCheck.rows[0].privacy_profile || 'everyone';

    // If privacy is 'none', only return basic info
    if (privacySetting === 'none') {
      return res.json({
        user: {
          id: privacyCheck.rows[0].id,
          firstName: privacyCheck.rows[0].first_name,
          lastName: privacyCheck.rows[0].last_name,
          profilePhotoUrl: privacyCheck.rows[0].profile_photo_url,
          isVerified: privacyCheck.rows[0].is_verified
        }
      });
    }

    // TODO: If privacy is 'friends', check if users are connected
    // For now, show full public profile

    const result = await query(
      `SELECT 
        u.id, u.email, u.first_name, u.last_name, u.gender, u.birth_date,
        u.profile_photo_url, u.cover_image_url, u.bio,
        u.school_id, s.name as school_name, s.city as school_city,
        u.department_id, d.name as department_name,
        u.student_number, u.graduation_year, u.enrollment_year,
        u.study_level, u.is_verified, u.is_premium,
        u.created_at,
        up.about_me, up.interests, up.hobbies, up.skills, up.social_links,
        up.website, up.location, up.hometown,
        ustat.total_matches, ustat.total_courses, ustat.total_study_groups,
        ustat.helpful_count, ustat.rating_average
      FROM users u
      LEFT JOIN schools s ON u.school_id = s.id
      LEFT JOIN departments d ON u.department_id = d.id
      LEFT JOIN user_profiles up ON u.id = up.user_id
      LEFT JOIN user_statistics ustat ON u.id = ustat.user_id
      WHERE u.id = $1`,
      [id]
    );

    res.json({ user: result.rows[0] });
  } catch (error) {
    console.error('❌ Kullanıcı profili getirme hatası:', error);
    res.status(500).json({ error: 'Profil yüklenemedi' });
  }
});

/**
 * @route   PATCH /api/users/me
 * @desc    Update current user's basic info
 * @access  Private
 */
router.patch('/me', [
  authenticateToken,
  body('firstName').optional().trim().isLength({ min: 2, max: 50 }),
  body('lastName').optional().trim().isLength({ min: 2, max: 50 }),
  body('gender').optional().isIn(['male', 'female', 'other']),
  body('birthDate').optional().isISO8601(),
  body('phoneNumber').optional().matches(/^[0-9+\s-()]+$/),
  body('bio').optional().isLength({ max: 500 }),
  body('schoolId').optional().isInt(),
  body('departmentId').optional().isInt(),
  body('studentNumber').optional().isLength({ max: 20 }),
  body('universityEmail').optional().isEmail(),
  body('graduationYear').optional().isInt({ min: 2020, max: 2035 }),
  body('enrollmentYear').optional().isInt({ min: 2015, max: 2030 }),
  body('studyLevel').optional().isIn(['associate', 'bachelor', 'master', 'phd']),
  body('language').optional().isIn(['tr', 'en']),
  body('timezone').optional().isString()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const {
      firstName, lastName, gender, birthDate, phoneNumber, bio,
      schoolId, departmentId, studentNumber, universityEmail,
      graduationYear, enrollmentYear, studyLevel, language, timezone
    } = req.body;

    const updates = [];
    const values = [];
    let valueIndex = 1;

    if (firstName !== undefined) {
      updates.push(`first_name = $${valueIndex++}`);
      values.push(firstName);
    }
    if (lastName !== undefined) {
      updates.push(`last_name = $${valueIndex++}`);
      values.push(lastName);
    }
    if (gender !== undefined) {
      updates.push(`gender = $${valueIndex++}`);
      values.push(gender);
    }
    if (birthDate !== undefined) {
      updates.push(`birth_date = $${valueIndex++}`);
      values.push(birthDate);
    }
    if (phoneNumber !== undefined) {
      updates.push(`phone_number = $${valueIndex++}`);
      values.push(phoneNumber);
    }
    if (bio !== undefined) {
      updates.push(`bio = $${valueIndex++}`);
      values.push(bio);
    }
    if (schoolId !== undefined) {
      updates.push(`school_id = $${valueIndex++}`);
      values.push(schoolId);
    }
    if (departmentId !== undefined) {
      updates.push(`department_id = $${valueIndex++}`);
      values.push(departmentId);
    }
    if (studentNumber !== undefined) {
      updates.push(`student_number = $${valueIndex++}`);
      values.push(studentNumber);
    }
    if (universityEmail !== undefined) {
      updates.push(`university_email = $${valueIndex++}`);
      values.push(universityEmail);
    }
    if (graduationYear !== undefined) {
      updates.push(`graduation_year = $${valueIndex++}`);
      values.push(graduationYear);
    }
    if (enrollmentYear !== undefined) {
      updates.push(`enrollment_year = $${valueIndex++}`);
      values.push(enrollmentYear);
    }
    if (studyLevel !== undefined) {
      updates.push(`study_level = $${valueIndex++}`);
      values.push(studyLevel);
    }
    if (language !== undefined) {
      updates.push(`language = $${valueIndex++}`);
      values.push(language);
    }
    if (timezone !== undefined) {
      updates.push(`timezone = $${valueIndex++}`);
      values.push(timezone);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'Güncellenecek alan yok' });
    }

    updates.push(`updated_at = NOW()`);
    values.push(req.user.userId);

    const updateQuery = `
      UPDATE users
      SET ${updates.join(', ')}
      WHERE id = $${valueIndex}
      RETURNING *
    `;

    const result = await query(updateQuery, values);

    res.json({
      message: 'Profil güncellendi',
      user: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Profil güncelleme hatası:', error);
    res.status(500).json({ error: 'Profil güncellenemedi' });
  }
});

/**
 * @route   PATCH /api/users/me/profile
 * @desc    Update extended profile (about_me, interests, hobbies, skills, etc.)
 * @access  Private
 */
router.patch('/me/profile', [
  authenticateToken,
  body('aboutMe').optional().isLength({ max: 2000 }),
  body('interests').optional().isArray(),
  body('hobbies').optional().isArray(),
  body('skills').optional().isArray(),
  body('socialLinks').optional().isObject(),
  body('website').optional().isURL(),
  body('location').optional().isString(),
  body('bloodType').optional().isIn(['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']),
  body('hometown').optional().isString()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const {
      aboutMe, interests, hobbies, skills, socialLinks,
      website, location, bloodType, hometown
    } = req.body;

    // Check if user_profiles entry exists
    const checkProfile = await query(
      'SELECT user_id FROM user_profiles WHERE user_id = $1',
      [req.user.userId]
    );

    if (checkProfile.rows.length === 0) {
      // Insert new profile
      await query(
        `INSERT INTO user_profiles (user_id, about_me, interests, hobbies, skills, social_links, website, location, blood_type, hometown)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
        [req.user.userId, aboutMe || '', interests || [], hobbies || [], skills || [], 
         socialLinks || {}, website || null, location || null, bloodType || null, hometown || null]
      );
    } else {
      // Update existing profile
      const updates = [];
      const values = [];
      let valueIndex = 1;

      if (aboutMe !== undefined) {
        updates.push(`about_me = $${valueIndex++}`);
        values.push(aboutMe);
      }
      if (interests !== undefined) {
        updates.push(`interests = $${valueIndex++}`);
        values.push(JSON.stringify(interests));
      }
      if (hobbies !== undefined) {
        updates.push(`hobbies = $${valueIndex++}`);
        values.push(JSON.stringify(hobbies));
      }
      if (skills !== undefined) {
        updates.push(`skills = $${valueIndex++}`);
        values.push(JSON.stringify(skills));
      }
      if (socialLinks !== undefined) {
        updates.push(`social_links = $${valueIndex++}`);
        values.push(JSON.stringify(socialLinks));
      }
      if (website !== undefined) {
        updates.push(`website = $${valueIndex++}`);
        values.push(website);
      }
      if (location !== undefined) {
        updates.push(`location = $${valueIndex++}`);
        values.push(location);
      }
      if (bloodType !== undefined) {
        updates.push(`blood_type = $${valueIndex++}`);
        values.push(bloodType);
      }
      if (hometown !== undefined) {
        updates.push(`hometown = $${valueIndex++}`);
        values.push(hometown);
      }

      if (updates.length === 0) {
        return res.status(400).json({ error: 'Güncellenecek alan yok' });
      }

      values.push(req.user.userId);

      const updateQuery = `
        UPDATE user_profiles
        SET ${updates.join(', ')}
        WHERE user_id = $${valueIndex}
        RETURNING *
      `;

      await query(updateQuery, values);
    }

    res.json({ message: 'Profil detayları güncellendi' });
  } catch (error) {
    console.error('❌ Profil detayları güncelleme hatası:', error);
    res.status(500).json({ error: 'Profil detayları güncellenemedi' });
  }
});

/**
 * @route   PATCH /api/users/me/settings
 * @desc    Update user settings (privacy, notifications, theme)
 * @access  Private
 */
router.patch('/me/settings', [
  authenticateToken,
  body('privacyProfile').optional().isIn(['everyone', 'friends', 'none']),
  body('privacyCourses').optional().isIn(['everyone', 'friends', 'none']),
  body('privacyPhone').optional().isIn(['everyone', 'friends', 'none']),
  body('privacyEmail').optional().isIn(['everyone', 'friends', 'none']),
  body('notificationMatch').optional().isBoolean(),
  body('notificationMessage').optional().isBoolean(),
  body('notificationComment').optional().isBoolean(),
  body('notificationEmail').optional().isBoolean(),
  body('notificationPush').optional().isBoolean(),
  body('themeMode').optional().isIn(['light', 'dark', 'system']),
  body('languagePreference').optional().isIn(['tr', 'en'])
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const {
      privacyProfile, privacyCourses, privacyPhone, privacyEmail,
      notificationMatch, notificationMessage, notificationComment,
      notificationEmail, notificationPush, themeMode, languagePreference
    } = req.body;

    // Check if user_settings entry exists
    const checkSettings = await query(
      'SELECT user_id FROM user_settings WHERE user_id = $1',
      [req.user.userId]
    );

    if (checkSettings.rows.length === 0) {
      // Insert default settings
      await query(
        `INSERT INTO user_settings (user_id, privacy_profile, privacy_courses, privacy_phone, privacy_email,
          notification_match, notification_message, notification_comment, notification_email, notification_push,
          theme_mode, language_preference)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
        [req.user.userId, 'everyone', 'everyone', 'friends', 'friends',
         true, true, true, false, true, 'system', 'tr']
      );
    }

    // Update settings
    const updates = [];
    const values = [];
    let valueIndex = 1;

    if (privacyProfile !== undefined) {
      updates.push(`privacy_profile = $${valueIndex++}`);
      values.push(privacyProfile);
    }
    if (privacyCourses !== undefined) {
      updates.push(`privacy_courses = $${valueIndex++}`);
      values.push(privacyCourses);
    }
    if (privacyPhone !== undefined) {
      updates.push(`privacy_phone = $${valueIndex++}`);
      values.push(privacyPhone);
    }
    if (privacyEmail !== undefined) {
      updates.push(`privacy_email = $${valueIndex++}`);
      values.push(privacyEmail);
    }
    if (notificationMatch !== undefined) {
      updates.push(`notification_match = $${valueIndex++}`);
      values.push(notificationMatch);
    }
    if (notificationMessage !== undefined) {
      updates.push(`notification_message = $${valueIndex++}`);
      values.push(notificationMessage);
    }
    if (notificationComment !== undefined) {
      updates.push(`notification_comment = $${valueIndex++}`);
      values.push(notificationComment);
    }
    if (notificationEmail !== undefined) {
      updates.push(`notification_email = $${valueIndex++}`);
      values.push(notificationEmail);
    }
    if (notificationPush !== undefined) {
      updates.push(`notification_push = $${valueIndex++}`);
      values.push(notificationPush);
    }
    if (themeMode !== undefined) {
      updates.push(`theme_mode = $${valueIndex++}`);
      values.push(themeMode);
    }
    if (languagePreference !== undefined) {
      updates.push(`language_preference = $${valueIndex++}`);
      values.push(languagePreference);
    }

    if (updates.length > 0) {
      values.push(req.user.userId);

      const updateQuery = `
        UPDATE user_settings
        SET ${updates.join(', ')}
        WHERE user_id = $${valueIndex}
        RETURNING *
      `;

      await query(updateQuery, values);
    }

    res.json({ message: 'Ayarlar güncellendi' });
  } catch (error) {
    console.error('❌ Ayarlar güncelleme hatası:', error);
    res.status(500).json({ error: 'Ayarlar güncellenemedi' });
  }
});

/**
 * @route   POST /api/users/me/online
 * @desc    Update user's online status
 * @access  Private
 */
router.post('/me/online', authenticateToken, async (req, res) => {
  try {
    await query(
      `UPDATE users 
       SET is_online = true, last_seen_at = NOW()
       WHERE id = $1`,
      [req.user.userId]
    );

    res.json({ message: 'Online durumu güncellendi' });
  } catch (error) {
    console.error('❌ Online durumu güncelleme hatası:', error);
    res.status(500).json({ error: 'Durum güncellenemedi' });
  }
});

/**
 * @route   POST /api/users/me/offline
 * @desc    Set user offline
 * @access  Private
 */
router.post('/me/offline', authenticateToken, async (req, res) => {
  try {
    await query(
      `UPDATE users 
       SET is_online = false, last_seen_at = NOW()
       WHERE id = $1`,
      [req.user.userId]
    );

    res.json({ message: 'Offline durumu güncellendi' });
  } catch (error) {
    console.error('❌ Offline durumu güncelleme hatası:', error);
    res.status(500).json({ error: 'Durum güncellenemedi' });
  }
});

/**
 * @route   PATCH /api/users/me/fcm-token
 * @desc    Update FCM token for push notifications
 * @access  Private
 */
router.patch('/me/fcm-token', [
  authenticateToken,
  body('fcmToken').notEmpty()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    const { fcmToken } = req.body;

    await query(
      `UPDATE users 
       SET fcm_token = $1, updated_at = NOW()
       WHERE id = $2`,
      [fcmToken, req.user.userId]
    );

    res.json({ message: 'FCM token güncellendi' });
  } catch (error) {
    console.error('❌ FCM token güncelleme hatası:', error);
    res.status(500).json({ error: 'Token güncellenemedi' });
  }
});

module.exports = router;
