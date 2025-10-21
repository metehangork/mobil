const express = require('express');
const router = express.Router();
const { query } = require('../db/pool');
const { authenticateToken } = require('../middleware/auth');

/**
 * @route   GET /api/schools
 * @desc    Get all schools or search schools
 * @access  Public
 * @query   search - Search term (min 3 chars)
 * @query   city - Filter by city
 * @query   type - Filter by type (public/private)
 * @query   page - Page number (default 1)
 * @query   limit - Items per page (default 50)
 */
router.get('/', async (req, res) => {
  try {
    const { search, city, type, page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;
    
    let sqlQuery = `SELECT id, name, city, type, logo_url, website, student_count, ranking, established_year FROM schools WHERE is_active = true`;
    let countQuery = `SELECT COUNT(*) FROM schools WHERE is_active = true`;
    let params = [];
    let countParams = [];
    let paramIndex = 1;
    
    // City filter
    if (city && city.trim().length > 0) {
      sqlQuery += ` AND city ILIKE $${paramIndex}`;
      countQuery += ` AND city ILIKE $${paramIndex}`;
      params.push(`%${city.trim()}%`);
      countParams.push(`%${city.trim()}%`);
      paramIndex++;
    }
    
    // Type filter
    if (type && (type === 'public' || type === 'private')) {
      sqlQuery += ` AND type = $${paramIndex}`;
      countQuery += ` AND type = $${paramIndex}`;
      params.push(type);
      countParams.push(type);
      paramIndex++;
    }
    
    // Search filter
    if (search && search.trim().length >= 3) {
      const searchTerm = search.trim().toLowerCase()
        .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u')
        .replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c');
      
      sqlQuery += ` AND (
        LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(name, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $${paramIndex}
        OR LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(city, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $${paramIndex}
        OR LOWER(name) LIKE LOWER($${paramIndex + 1})
        OR LOWER(city) LIKE LOWER($${paramIndex + 1})
      )`;
      
      countQuery += ` AND (
        LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(name, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $${paramIndex}
        OR LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(city, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $${paramIndex}
        OR LOWER(name) LIKE LOWER($${paramIndex + 1})
        OR LOWER(city) LIKE LOWER($${paramIndex + 1})
      )`;
      
      params.push(`%${searchTerm}%`, `%${search.trim()}%`);
      countParams.push(`%${searchTerm}%`, `%${search.trim()}%`);
      paramIndex += 2;
      
      sqlQuery += ` ORDER BY 
        CASE 
          WHEN LOWER(name) LIKE LOWER($${paramIndex}) THEN 1
          WHEN LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(name, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $${paramIndex + 1} THEN 2
          WHEN LOWER(name) LIKE LOWER($${paramIndex + 2}) THEN 3
          WHEN LOWER(city) LIKE LOWER($${paramIndex + 2}) THEN 4
          ELSE 5
        END, ranking ASC NULLS LAST, name ASC`;
      params.push(`${search.trim()}%`, `${searchTerm}%`, `%${search.trim()}%`);
      paramIndex += 3;
    } else {
      sqlQuery += ` ORDER BY ranking ASC NULLS LAST, name ASC`;
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
    console.error('❌ Schools API error:', error);
    res.status(500).json({
      success: false,
      error: 'Üniversiteler yüklenirken bir hata oluştu'
    });
  }
});

/**
 * @route   GET /api/schools/:id
 * @desc    Get single school by ID
 * @access  Public
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await query(
      `SELECT id, name, city, type, logo_url, website, address, phone, email,
              description, student_count, ranking, established_year, 
              latitude, longitude, is_active, created_at
       FROM schools
       WHERE id = $1`,
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Üniversite bulunamadı'
      });
    }
    
    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('❌ School detail error:', error);
    res.status(500).json({
      success: false,
      error: 'Üniversite bilgisi yüklenemedi'
    });
  }
});

/**
 * @route   GET /api/schools/:id/departments
 * @desc    Get all departments of a school
 * @access  Public
 */
router.get('/:id/departments', async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await query(
      `SELECT d.id, d.name, d.code, d.faculty, d.degree_level, d.language
       FROM departments d
       WHERE d.school_id = $1 AND d.is_active = true
       ORDER BY d.faculty ASC, d.name ASC`,
      [id]
    );
    
    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows
    });
  } catch (error) {
    console.error('❌ School departments error:', error);
    res.status(500).json({
      success: false,
      error: 'Bölümler yüklenemedi'
    });
  }
});

/**
 * @route   GET /api/schools/:id/courses
 * @desc    Get all courses of a school
 * @access  Public
 */
router.get('/:id/courses', async (req, res) => {
  try {
    const { id } = req.params;
    const { semester, departmentId } = req.query;
    
    let sqlQuery = `
      SELECT c.id, c.code, c.name, c.credits, c.ects, c.semester,
             c.department_id, d.name as department_name,
             c.instructor_name, c.description, c.is_mandatory, c.language
      FROM courses c
      LEFT JOIN departments d ON c.department_id = d.id
      WHERE c.school_id = $1 AND c.is_active = true
    `;
    
    let params = [id];
    let paramIndex = 2;
    
    if (semester) {
      sqlQuery += ` AND c.semester = $${paramIndex}`;
      params.push(parseInt(semester));
      paramIndex++;
    }
    
    if (departmentId) {
      sqlQuery += ` AND c.department_id = $${paramIndex}`;
      params.push(parseInt(departmentId));
      paramIndex++;
    }
    
    sqlQuery += ` ORDER BY c.semester ASC, c.code ASC`;
    
    const result = await query(sqlQuery, params);
    
    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows
    });
  } catch (error) {
    console.error('❌ School courses error:', error);
    res.status(500).json({
      success: false,
      error: 'Dersler yüklenemedi'
    });
  }
});

/**
 * @route   POST /api/schools
 * @desc    Create new school (Admin only)
 * @access  Private (Admin)
 */
router.post('/', authenticateToken, async (req, res) => {
  try {
    // TODO: Add admin check middleware
    
    const {
      name, city, type, logoUrl, website, address, phone, email,
      description, studentCount, ranking, establishedYear, latitude, longitude
    } = req.body;
    
    if (!name || !city || !type) {
      return res.status(400).json({
        success: false,
        error: 'Ad, şehir ve tip zorunludur'
      });
    }
    
    const result = await query(
      `INSERT INTO schools (name, city, type, logo_url, website, address, phone, email,
                            description, student_count, ranking, established_year, latitude, longitude)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
       RETURNING *`,
      [name, city, type, logoUrl || null, website || null, address || null, 
       phone || null, email || null, description || null, studentCount || null,
       ranking || null, establishedYear || null, latitude || null, longitude || null]
    );
    
    res.status(201).json({
      success: true,
      message: 'Üniversite oluşturuldu',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Create school error:', error);
    res.status(500).json({
      success: false,
      error: 'Üniversite oluşturulamadı'
    });
  }
});

/**
 * @route   PATCH /api/schools/:id
 * @desc    Update school (Admin only)
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
      'name', 'city', 'type', 'logoUrl', 'website', 'address', 'phone', 'email',
      'description', 'studentCount', 'ranking', 'establishedYear', 'latitude', 'longitude', 'isActive'
    ];
    
    const fieldMap = {
      logoUrl: 'logo_url',
      studentCount: 'student_count',
      establishedYear: 'established_year',
      isActive: 'is_active'
    };
    
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        const dbField = fieldMap[field] || field.replace(/([A-Z])/g, '_$1').toLowerCase();
        updates.push(`${dbField} = $${valueIndex++}`);
        values.push(req.body[field]);
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
      `UPDATE schools SET ${updates.join(', ')}, updated_at = NOW()
       WHERE id = $${valueIndex}
       RETURNING *`,
      values
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Üniversite bulunamadı'
      });
    }
    
    res.json({
      success: true,
      message: 'Üniversite güncellendi',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('❌ Update school error:', error);
    res.status(500).json({
      success: false,
      error: 'Üniversite güncellenemedi'
    });
  }
});

module.exports = router;
