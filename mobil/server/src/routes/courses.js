const express = require('express');
const { body, query: queryValidator, validationResult } = require('express-validator');
const { query } = require('../db/pool');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// ==================== COURSES API ====================

/**
 * @route   GET /api/courses
 * @desc    Get all courses or search courses
 * @access  Public
 * @query   search - Search term (min 3 chars)
 * @query   schoolId - Filter by school
 * @query   departmentId - Filter by department
 * @query   semester - Filter by semester
 * @query   isMandatory - Filter by mandatory status (true/false)
 * @query   page - Page number (default 1)
 * @query   limit - Items per page (default 50)
 */
router.get('/', async (req, res) => {
  try {
    const { search, schoolId, departmentId, semester, isMandatory, page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;
    
    let sqlQuery = `
      SELECT c.id, c.code, c.name, c.credits, c.ects, c.semester,
             c.school_id, s.name as school_name,
             c.department_id, d.name as department_name, d.faculty,
             c.instructor_name, c.description, c.is_mandatory, c.language,
             c.prerequisites
      FROM courses c
      LEFT JOIN schools s ON c.school_id = s.id
      LEFT JOIN departments d ON c.department_id = d.id
      WHERE c.is_active = true
    `;
    let countQuery = `SELECT COUNT(*) FROM courses c WHERE c.is_active = true`;
    let params = [];
    let countParams = [];
    let paramIndex = 1;
    
    // School filter
    if (schoolId) {
      sqlQuery += ` AND c.school_id = $${paramIndex}`;
      countQuery += ` AND c.school_id = $${paramIndex}`;
      params.push(parseInt(schoolId));
      countParams.push(parseInt(schoolId));
      paramIndex++;
    }
    
    // Department filter
    if (departmentId) {
      sqlQuery += ` AND c.department_id = $${paramIndex}`;
      countQuery += ` AND c.department_id = $${paramIndex}`;
      params.push(parseInt(departmentId));
      countParams.push(parseInt(departmentId));
      paramIndex++;
    }
    
    // Semester filter
    if (semester) {
      sqlQuery += ` AND c.semester = $${paramIndex}`;
      countQuery += ` AND c.semester = $${paramIndex}`;
      params.push(parseInt(semester));
      countParams.push(parseInt(semester));
      paramIndex++;
    }
    
    // Mandatory filter
    if (isMandatory !== undefined) {
      sqlQuery += ` AND c.is_mandatory = $${paramIndex}`;
      countQuery += ` AND c.is_mandatory = $${paramIndex}`;
      params.push(isMandatory === 'true');
      countParams.push(isMandatory === 'true');
      paramIndex++;
    }
    
    // Search filter
    if (search && search.trim().length >= 2) {
      const searchPattern = `%${search.trim()}%`;
      sqlQuery += ` AND (
        c.code ILIKE $${paramIndex}
        OR c.name ILIKE $${paramIndex}
        OR c.instructor_name ILIKE $${paramIndex}
      )`;
      countQuery += ` AND (
        c.code ILIKE $${paramIndex}
        OR c.name ILIKE $${paramIndex}
        OR c.instructor_name ILIKE $${paramIndex}
      )`;
      params.push(searchPattern);
      countParams.push(searchPattern);
      paramIndex++;
      
      sqlQuery += ` ORDER BY 
        CASE 
          WHEN c.code ILIKE $${paramIndex} THEN 1
          WHEN c.name ILIKE $${paramIndex + 1} THEN 2
          WHEN c.code ILIKE $${paramIndex + 2} THEN 3
          WHEN c.name ILIKE $${paramIndex + 2} THEN 4
          ELSE 5
        END, c.semester ASC, c.code ASC`;
      params.push(`${search.trim()}%`, `${search.trim()}%`, searchPattern);
      paramIndex += 3;
    } else {
      sqlQuery += ` ORDER BY c.semester ASC, c.code ASC`;
    }
    
    // Pagination
    sqlQuery += ` LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(parseInt(limit), parseInt(offset));

    const [result, countResult] = await Promise.all([
      query(sqlQuery, params),
      query(countQuery, countParams)
    ]);
    
    const total = parseInt(countResult.rows[0].count);
    const totalPages = Math.ceil(total / limit);
    
    res.json({
      success: true,
      count: result.rows.length,
      total,
      page: parseInt(page),
      totalPages,
      data: result.rows
    });
  } catch (error) {
    console.error('❌ Courses API error:', error);
    res.status(500).json({
      success: false,
      error: 'Dersler yüklenirken hata oluştu'
    });
  }
});

/**
 * @route   GET /api/courses/:id
 * @desc    Get single course by ID
 * @access  Public
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await query(
      `SELECT c.id, c.code, c.name, c.credits, c.ects, c.semester,
              c.school_id, s.name as school_name, s.city as school_city,
              c.department_id, d.name as department_name, d.faculty,
              c.instructor_name, c.description, c.is_mandatory, c.language,
              c.prerequisites, c.is_active, c.created_at
       FROM courses c
       LEFT JOIN schools s ON c.school_id = s.id
       LEFT JOIN departments d ON c.department_id = d.id
       WHERE c.id = $1`,
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Ders bulunamadı'
      });
    }
    
    // Get enrolled students count
    const enrolledCount = await query(
      'SELECT COUNT(*) FROM user_courses WHERE course_id = $1 AND status = $2',
      [id, 'taking']
    );
    
    res.json({
      success: true,
      data: {
        ...result.rows[0],
        enrolledCount: parseInt(enrolledCount.rows[0].count)
      }
    });
  } catch (error) {
    console.error('❌ Course detail error:', error);
    res.status(500).json({
      success: false,
      error: 'Ders bilgisi yüklenemedi'
    });
  }
});

/**
 * @route   POST /api/courses
 * @desc    Create new course (Admin only)
 * @access  Private (Admin)
 */
router.post('/', [
  authenticateToken,
  body('code').notEmpty().withMessage('Ders kodu zorunlu'),
  body('name').notEmpty().withMessage('Ders adı zorunlu'),
  body('schoolId').isInt().withMessage('Okul ID zorunlu'),
  body('departmentId').isInt().withMessage('Bölüm ID zorunlu'),
  body('credits').optional().isInt({ min: 0, max: 20 }),
  body('ects').optional().isInt({ min: 0, max: 30 }),
  body('semester').optional().isInt({ min: 1, max: 12 })
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  try {
    // TODO: Add admin check middleware
    
    const {
      code, name, schoolId, departmentId, credits, ects, semester,
      instructorName, description, isMandatory, language, prerequisites
    } = req.body;
    
    const result = await query(
      `INSERT INTO courses (code, name, school_id, department_id, credits, ects, semester,
                            instructor_name, description, is_mandatory, language, prerequisites)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
       RETURNING *`,
      [code, name, schoolId, departmentId, credits || 3, ects || 6, semester || 1,
       instructorName || null, description || null, isMandatory || false, 
       language || 'TR', prerequisites ? JSON.stringify(prerequisites) : null]
    );
    
    res.status(201).json({
      success: true,
      message: 'Ders oluşturuldu',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Create course error:', error);
    res.status(500).json({
      success: false,
      error: 'Ders oluşturulamadı'
    });
  }
});

/**
 * @route   PATCH /api/courses/:id
 * @desc    Update course (Admin only)
 * @access  Private (Admin)
 */
router.patch('/:id', authenticateToken, async (req, res) => {
  try {
    // TODO: Add admin check middleware
    
    const { id } = req.params;
    const updates = [];
    const values = [];
    let valueIndex = 1;
    
    const allowedFields = [
      'code', 'name', 'credits', 'ects', 'semester', 'instructorName',
      'description', 'isMandatory', 'language', 'prerequisites', 'isActive'
    ];
    
    const fieldMap = {
      instructorName: 'instructor_name',
      isMandatory: 'is_mandatory',
      isActive: 'is_active'
    };
    
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        const dbField = fieldMap[field] || field.replace(/([A-Z])/g, '_$1').toLowerCase();
        updates.push(`${dbField} = $${valueIndex++}`);
        
        // Special handling for JSON fields
        if (field === 'prerequisites' && req.body[field]) {
          values.push(JSON.stringify(req.body[field]));
        } else {
          values.push(req.body[field]);
        }
      }
    }
    
    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Güncellenecek alan yok'
      });
    }
    
    values.push(id);
    
    const result = await query(
      `UPDATE courses SET ${updates.join(', ')}, updated_at = NOW()
       WHERE id = $${valueIndex}
       RETURNING *`,
      values
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Ders bulunamadı'
      });
    }
    
    res.json({
      success: true,
      message: 'Ders güncellendi',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Update course error:', error);
    res.status(500).json({
      success: false,
      error: 'Ders güncellenemedi'
    });
  }
});

// Kullanıcının derslerini getir (mevcut kod - düzenli)
router.get('/my-courses', authenticateToken, async (req, res) => {
  try {
    const result = await query(
      `SELECT c.id, c.code, c.name, c.department_id, c.credits, c.professor, 
              uc.semester, uc.enrolled_at
       FROM user_courses uc
       JOIN courses c ON uc.course_id = c.id
       WHERE uc.user_id = $1
       ORDER BY c.code`,
      [req.user.userId]
    );
    
    res.json({ courses: result.rows });
  } catch (error) {
    console.error('❌ Kullanıcı dersleri hatası:', error);
    res.status(500).json({ error: 'Dersler getirilemedi' });
  }
});

// Ders ekleme (mevcut kod - düzenli)
router.post('/enroll', [
  authenticateToken,
  body('courseId').notEmpty().withMessage('Ders ID gerekli'),
  body('semester').optional().isString()
], async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  
  try {
    const { courseId, semester } = req.body;
    
    // Ders var mı kontrol et
    const courseCheck = await query('SELECT id FROM courses WHERE id = $1', [courseId]);
    if (courseCheck.rows.length === 0) {
      return res.status(404).json({ error: 'Ders bulunamadı' });
    }
    
    // Zaten ekli mi kontrol et
    const enrollCheck = await query(
      'SELECT id FROM user_courses WHERE user_id = $1 AND course_id = $2',
      [req.user.userId, courseId]
    );
    
    if (enrollCheck.rows.length > 0) {
      return res.status(400).json({ error: 'Bu derse zaten kayıtlısınız' });
    }
    
    // Ders ekle
    await query(
      `INSERT INTO user_courses (user_id, course_id, semester, enrolled_at)
       VALUES ($1, $2, $3, NOW())`,
      [req.user.userId, courseId, semester || '2024-2025 Bahar']
    );
    
    res.json({ message: 'Ders başarıyla eklendi' });
  } catch (error) {
    console.error('❌ Ders ekleme hatası:', error);
    res.status(500).json({ error: 'Ders eklenemedi' });
  }
});

// Ders çıkarma (mevcut kod)
router.delete('/unenroll/:courseId', authenticateToken, async (req, res) => {
  try {
    const { courseId } = req.params;
    
    const result = await query(
      'DELETE FROM user_courses WHERE user_id = $1 AND course_id = $2 RETURNING id',
      [req.user.userId, courseId]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Ders kaydı bulunamadı' });
    }
    
    res.json({ message: 'Ders başarıyla çıkarıldı' });
  } catch (error) {
    console.error('❌ Ders çıkarma hatası:', error);
    res.status(500).json({ error: 'Ders çıkarılamadı' });
  }
});

// Ders arkadaşı eşleştirme (emiletör - mevcut kod)
router.get('/matches', authenticateToken, async (req, res) => {
  try {
    const { minCommonCourses = 1, limit = 20 } = req.query;
    
    // Ortak dersleri olan kullanıcıları bul
    const result = await query(
      `WITH my_courses AS (
        SELECT course_id FROM user_courses WHERE user_id = $1
      ),
      common_course_users AS (
        SELECT 
          uc.user_id,
          COUNT(DISTINCT uc.course_id) as common_count,
          ARRAY_AGG(DISTINCT c.code) as common_course_codes,
          ARRAY_AGG(DISTINCT c.name) as common_course_names
        FROM user_courses uc
        JOIN courses c ON uc.course_id = c.id
        WHERE uc.course_id IN (SELECT course_id FROM my_courses)
          AND uc.user_id != $1
        GROUP BY uc.user_id
        HAVING COUNT(DISTINCT uc.course_id) >= $2
      )
      SELECT 
        u.id,
        u.email,
        u.first_name,
        u.last_name,
        u.school_id,
        ccu.common_count,
        ccu.common_course_codes,
        ccu.common_course_names,
        (ccu.common_count::float / NULLIF((SELECT COUNT(*) FROM my_courses), 0)) as compatibility_score
      FROM common_course_users ccu
      JOIN users u ON ccu.user_id = u.id
      WHERE u.is_verified = true
      ORDER BY ccu.common_count DESC, u.email
      LIMIT $3`,
      [req.user.userId, minCommonCourses, limit]
    );
    
    const matches = result.rows.map(row => ({
      id: row.id,
      matchedUser: {
        id: row.id,
        email: row.email,
        firstName: row.first_name || '',
        lastName: row.last_name || '',
        schoolId: row.school_id
      },
      commonCourses: row.common_course_codes || [],
      commonCourseNames: row.common_course_names || [],
      commonCourseCount: parseInt(row.common_count),
      compatibilityScore: parseFloat((row.compatibility_score * 100).toFixed(1)),
      status: 'pending'
    }));
    
    res.json({ matches });
  } catch (error) {
    console.error('❌ Eşleştirme hatası:', error);
    res.status(500).json({ error: 'Eşleştirme yapılamadı' });
  }
});

// Belirli bir ders için arkadaş bul (mevcut kod)
router.get('/course/:courseId/matches', authenticateToken, async (req, res) => {
  try {
    const { courseId } = req.params;
    
    const result = await query(
      `SELECT 
        u.id,
        u.email,
        u.first_name,
        u.last_name,
        u.school_id,
        c.code as course_code,
        c.name as course_name
       FROM user_courses uc
       JOIN users u ON uc.user_id = u.id
       JOIN courses c ON uc.course_id = c.id
       WHERE uc.course_id = $1
         AND uc.user_id != $2
         AND u.is_verified = true
       ORDER BY u.email
       LIMIT 50`,
      [courseId, req.user.userId]
    );
    
    const matches = result.rows.map(row => ({
      matchedUser: {
        id: row.id,
        email: row.email,
        firstName: row.first_name || '',
        lastName: row.last_name || ''
      },
      course: {
        code: row.course_code,
        name: row.course_name
      }
    }));
    
    res.json({ matches });
  } catch (error) {
    console.error('❌ Ders arkadaşı bulma hatası:', error);
    res.status(500).json({ error: 'Arkadaş bulunamadı' });
  }
});

module.exports = router;
