const express = require('express');
const router = express.Router();
const { query } = require('../db/pool');

/**
 * GET /api/departments?search=query
 * Bölüm ara - search parametresi varsa arama yapar, yoksa tümünü döner
 * İlgi düzeyine göre sıralama (isim benzerliği)
 */
router.get('/', async (req, res) => {
  try {
    const { search } = req.query;
    let sqlQuery = `SELECT id, name, faculty FROM departments WHERE is_active = true`;
    let params = [];
    
    // En az 3 karakter gerekli
    if (search && search.trim().length >= 3) {
      // Fuzzy search: Türkçe karakterleri normalize et
      const searchTerm = search.trim().toLowerCase()
        .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u')
        .replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c');
      
      sqlQuery += ` AND (
        LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(name, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $1
        OR LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(faculty, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $1
        OR LOWER(name) LIKE LOWER($2)
        OR LOWER(faculty) LIKE LOWER($2)
      ) ORDER BY 
        CASE 
          WHEN LOWER(name) LIKE LOWER($3) THEN 1
          WHEN LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(name, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $4 THEN 2
          WHEN LOWER(name) LIKE LOWER($2) THEN 3
          WHEN LOWER(faculty) LIKE LOWER($2) THEN 4
          ELSE 5
        END, name ASC
      LIMIT 50`;
      params = [`%${searchTerm}%`, `%${search.trim()}%`, `${search.trim()}%`, `${searchTerm}%`];
    } else {
      // Arama yoksa sadece isime göre sırala ve ilk 100'ü getir
      sqlQuery += ` ORDER BY name ASC LIMIT 100`;
    }

    const result = await query(sqlQuery, params);

    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows
    });
  } catch (error) {
    console.error('Departments API error:', error);
    res.status(500).json({
      success: false,
      error: 'Bölümler yüklenirken bir hata oluştu'
    });
  }
});

module.exports = router;
