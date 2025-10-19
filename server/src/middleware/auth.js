const jwt = require('jsonwebtoken');

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Token gerekli' });
  jwt.verify(token, process.env.JWT_SECRET || 'development_secret', (err, user) => {
    if (err) return res.status(403).json({ error: 'Geçersiz token' });
    req.user = user; // { userId, email }
    next();
  });
}

module.exports = { authenticateToken };
