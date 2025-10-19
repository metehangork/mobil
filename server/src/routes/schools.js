const express = require('express');
const router = express.Router();
const { query } = require('../db/pool');

/**
 * GET /api/schools?search=query  
 * Üniversite ara - search parametresi varsa arama yapar, yoksa tümünü döner
 * İlgi düzeyine göre sıralama (isim benzerliği)
 */
router.get('/', async (req, res) => {
  try {
    const { search } = req.query;
    let sqlQuery = `SELECT id, name, city, type FROM schools WHERE is_active = true`;
    let params = [];
    
    // En az 3 karakter gerekli
    if (search && search.trim().length >= 3) {
      // Fuzzy search: Türkçe karakterleri normalize et ve kısmi eşleşmeleri destekle
      const searchTerm = search.trim().toLowerCase()
        .replace(/ı/g, 'i').replace(/ğ/g, 'g').replace(/ü/g, 'u')
        .replace(/ş/g, 's').replace(/ö/g, 'o').replace(/ç/g, 'c');
      
      sqlQuery += ` AND (
        LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(name, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $1
        OR LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(city, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $1
        OR LOWER(name) LIKE LOWER($2)
        OR LOWER(city) LIKE LOWER($2)
      ) ORDER BY 
        CASE 
          WHEN LOWER(name) LIKE LOWER($3) THEN 1
          WHEN LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(name, 'ı', 'i'), 'ğ', 'g'), 'ü', 'u'), 'ş', 's'), 'ö', 'o'), 'ç', 'c')) LIKE $4 THEN 2
          WHEN LOWER(name) LIKE LOWER($2) THEN 3
          WHEN LOWER(city) LIKE LOWER($2) THEN 4
          ELSE 5
        END, name ASC
      LIMIT 50`;
      params = [`%${searchTerm}%`, `%${search.trim()}%`, `${search.trim()}%`, `${searchTerm}%`];
    } else {
      // Arama yoksa sadece isime göre sırala
      sqlQuery += ` ORDER BY name ASC`;
    }

    const result = await query(sqlQuery, params);
    
    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows
    });
  } catch (error) {
    console.error('Schools API error:', error);
    res.status(500).json({
      success: false,
      error: 'Üniversiteler yüklenirken bir hata oluştu'
    });
  }
});

module.exports = router;
