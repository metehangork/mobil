const express = require('express');
const router = express.Router();
const { query } = require('../db/pool');
const { authenticateToken } = require('../middleware/auth');

/**
 * @route   GET /api/departments
 * @desc    Get all departments or search departments
 * @access  Public
 * @query   search - Search term (min 3 chars)
 * @query   schoolId - Filter by school
 * @query   faculty - Filter by faculty
 * @query   degreeLevel - Filter by degree level
 * @query   page - Page number (default 1)
 * @query   limit - Items per page (default 100)
 */
router.get('/', async (req, res) => {
  try {
    const { search, schoolId, faculty, degreeLevel, page = 1, limit = 100 } = req.query;
    const offset = (page - 1) * limit;
    
    let sqlQuery = `
      SELECT d.id, d.name, d.faculty, d.degree_type, d.language, d.school_id,
             d.description, d.duration_years,
             s.name as school_name, s.city as school_city
      FROM departments d
      LEFT JOIN schools s ON d.school_id = s.id
      WHERE d.is_active = true
    `;
    let countQuery = `SELECT COUNT(*) FROM departments d WHERE d.is_active = true`;
    let params = [];
    let countParams = [];
    let paramIndex = 1;
    
    // School filter
    if (schoolId) {
      sqlQuery += ` AND d.school_id = $${paramIndex}`;
      countQuery += ` AND d.school_id = $${paramIndex}`;
      params.push(parseInt(schoolId));
      countParams.push(parseInt(schoolId));
      paramIndex++;
    }
    
    // Faculty filter
    if (faculty && faculty.trim().length > 0) {
      sqlQuery += ` AND d.faculty ILIKE $${paramIndex}`;
      countQuery += ` AND d.faculty ILIKE $${paramIndex}`;
      params.push(`%${faculty.trim()}%`);
      countParams.push(`%${faculty.trim()}%`);
      paramIndex++;
    }
    
    // Degree level filter
    if (degreeLevel && degreeLevel.trim().length > 0) {
      sqlQuery += ` AND d.degree_level = $${paramIndex}`;
      countQuery += ` AND d.degree_level = $${paramIndex}`;
      params.push(degreeLevel.trim());
      countParams.push(degreeLevel.trim());
      paramIndex++;
    }
    
    // Search filter
    if (search && search.trim().length >= 3) {
      const searchTerm = search.trim().toLowerCase()
        .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u')
        .replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c');
      
      sqlQuery += ` AND (
        LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(d.name, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $${paramIndex}
        OR LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(d.faculty, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $${paramIndex}
        OR LOWER(d.name) LIKE LOWER($${paramIndex + 1})
        OR LOWER(d.faculty) LIKE LOWER($${paramIndex + 1})
        OR d.code ILIKE $${paramIndex + 1}
      )`;
      
      countQuery += ` AND (
        LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(d.name, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $${paramIndex}
        OR LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(d.faculty, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $${paramIndex}
        OR LOWER(d.name) LIKE LOWER($${paramIndex + 1})
        OR LOWER(d.faculty) LIKE LOWER($${paramIndex + 1})
        OR d.code ILIKE $${paramIndex + 1}
      )`;
      
      params.push(`%${searchTerm}%`, `%${search.trim()}%`);
      countParams.push(`%${searchTerm}%`, `%${search.trim()}%`);
      paramIndex += 2;
      
      sqlQuery += ` ORDER BY 
        CASE 
          WHEN LOWER(d.name) LIKE LOWER($${paramIndex}) THEN 1
          WHEN d.code ILIKE $${paramIndex} THEN 2
          WHEN LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(d.name, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $${paramIndex + 1} THEN 3
          WHEN LOWER(d.name) LIKE LOWER($${paramIndex + 2}) THEN 4
          WHEN LOWER(d.faculty) LIKE LOWER($${paramIndex + 2}) THEN 5
          ELSE 6
        END, d.name ASC`;
      params.push(`${search.trim()}%`, `${searchTerm}%`, `%${search.trim()}%`);
      paramIndex += 3;
    } else {
      sqlQuery += ` ORDER BY d.faculty ASC, d.name ASC`;
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
    console.error('❌ Departments API error:', error);
    res.status(500).json({
      success: false,
      error: 'Bölümler yüklenirken bir hata oluştu'
    });
  }
});

/**
 * @route   GET /api/departments/:id
 * @desc    Get single department by ID
 * @access  Public
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await query(
      `SELECT d.id, d.name, d.code, d.faculty, d.degree_level, d.language,
              d.school_id, s.name as school_name, s.city as school_city,
              d.duration_years, d.is_active, d.created_at
       FROM departments d
       LEFT JOIN schools s ON d.school_id = s.id
       WHERE d.id = $1`,
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Bölüm bulunamadı'
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Department detail error:', error);
    res.status(500).json({
      success: false,
      error: 'Bölüm bilgisi yüklenemedi'
    });
  }
});

/**
 * @route   GET /api/departments/:id/courses
 * @desc    Get all courses of a department
 * @access  Public
 */
router.get('/:id/courses', async (req, res) => {
  try {
    const { id } = req.params;
    const { semester } = req.query;
    
    let sqlQuery = `
      SELECT c.id, c.code, c.name, c.credits, c.ects, c.semester,
             c.instructor_name, c.description, c.is_mandatory, c.language
      FROM courses c
      WHERE c.department_id = $1 AND c.is_active = true
    `;
    
    let params = [id];
    
    if (semester) {
      sqlQuery += ` AND c.semester = $2`;
      params.push(parseInt(semester));
    }
    
    sqlQuery += ` ORDER BY c.semester ASC, c.code ASC`;
    
    const result = await query(sqlQuery, params);
    
    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows
    });
  } catch (error) {
    console.error('❌ Department courses error:', error);
    res.status(500).json({
      success: false,
      error: 'Bölüm dersleri yüklenemedi'
    });
  }
});

/**
 * @route   POST /api/departments
 * @desc    Create new department (Admin only)
 * @access  Private (Admin)
 */
router.post('/', authenticateToken, async (req, res) => {
  try {
    // TODO: Add admin check middleware
    
    const { name, code, faculty, degreeLevel, language, schoolId, durationYears } = req.body;
    
    if (!name || !faculty || !schoolId) {
      return res.status(400).json({
        success: false,
        error: 'Ad, fakülte ve okul zorunludur'
      });
    }
    
    const result = await query(
      `INSERT INTO departments (name, code, faculty, degree_level, language, school_id, duration_years)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [name, code || null, faculty, degreeLevel || 'bachelor', language || 'TR', schoolId, durationYears || 4]
    );
    
    res.status(201).json({
      success: true,
      message: 'Bölüm oluşturuldu',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Create department error:', error);
    res.status(500).json({
      success: false,
      error: 'Bölüm oluşturulamadı'
    });
  }
});

module.exports = router;
