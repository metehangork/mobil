const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 5432,
  database: process.env.DB_NAME || 'unicampus_dev',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('connect', () => {
  console.log('✅ PostgreSQL: bağlantı kuruldu');
});

pool.on('error', (err) => {
  console.error('❌ PostgreSQL havuz hatası:', err);
});

async function query(text, params) {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    if (process.env.NODE_ENV === 'development') {
      console.log('📝 SQL', { text, duration: duration + 'ms' });
    }
    return res;
  } catch (err) {
    console.error('SQL Hatası:', {
      text,
      params,
      message: err.message,
      code: err.code,
      detail: err.detail,
      hint: err.hint,
      stack: err.stack && err.stack.split('\n').slice(0,4).join('\n')
    });
    throw err;
  }
}

module.exports = { pool, query };
