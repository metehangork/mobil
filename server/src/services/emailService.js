
const nodemailer = require('nodemailer');

const resolveCredentials = () => {
  const user = process.env.SMTP_USER || process.env.GMAIL_USER;
  const pass = process.env.SMTP_PASSWORD || process.env.SMTP_PASS || process.env.GMAIL_PASS;

  if (!user || !pass) {
    throw new Error('SMTP credentials missing. Set SMTP_USER/SMTP_PASSWORD (or GMAIL_USER/GMAIL_PASS) in the environment.');
  }

  return { user, pass };
};

const buildTransportOptions = (credentials) => {
  const host = process.env.SMTP_HOST || 'smtp.gmail.com';
  const port = parseInt(process.env.SMTP_PORT || '587', 10);
  const secure = process.env.SMTP_SECURE === 'true' || port === 465;

  return {
    host,
    port,
    secure,
    auth: credentials,
  };
};

const sendMail = async ({ to, subject, text, html, attachments }) => {
  if (!to || !subject || (!text && !html)) {
    throw new Error('Missing required email fields: to, subject and text or html.');
  }

  const credentials = resolveCredentials();
  const transportOptions = buildTransportOptions(credentials);
  const transporter = nodemailer.createTransport(transportOptions);

  try {
    const info = await transporter.sendMail({
      from: process.env.MAIL_FROM || credentials.user,
      to,
      subject,
      text,
      html,
      attachments,
    });

    if (process.env.NODE_ENV !== 'production') {
      console.log('📧 Email sent', {
        to,
        messageId: info.messageId,
        response: info.response,
      });
    }

    return info;
  } catch (error) {
    console.error('❌ SMTP send failed:', error);
    throw error;
  }
};

module.exports = { sendMail };
