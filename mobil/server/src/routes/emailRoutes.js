
const express = require('express');
const router = express.Router();
const { sendMail } = require('../services/emailService');

router.get('/send-test-email', async (req, res) => {
  const { to, subject, text, html } = req.query;

  if (!to || !subject || (!text && !html)) {
    return res.status(400).json({
      error: 'Missing required query parameters: to, subject and either text or html',
    });
  }

  try {
    const info = await sendMail({ to, subject, text, html });
    res.json({
      message: 'Email sent successfully',
      messageId: info.messageId,
      accepted: info.accepted,
      response: info.response,
    });
  } catch (error) {
    console.error('❌ Email sending failed:', error);
    res.status(500).json({
      error: 'Email could not be sent',
      message: error.message,
    });
  }
});

module.exports = router;
