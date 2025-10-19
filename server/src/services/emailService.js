
const nodemailer = require('nodemailer');
const { google } = require('googleapis');
const https = require('https');
const http = require('http');

const getSmtpCredentials = () => {
  const user = process.env.GMAIL_USER || process.env.SMTP_USER;
  const pass = process.env.GMAIL_PASS || process.env.SMTP_PASSWORD || process.env.SMTP_PASS;

  if (!user || !pass) {
    throw new Error('Email credentials are missing. Set GMAIL_USER/GMAIL_PASS or SMTP_USER/SMTP_PASSWORD in your environment.');
  }

  return { user, pass };
};

const buildTransportConfig = (credentials) => {
  if (process.env.SMTP_HOST) {
    const port = parseInt(process.env.SMTP_PORT || '587', 10);
    return {
      host: process.env.SMTP_HOST,
      port,
      secure: process.env.SMTP_SECURE === 'true' || port === 465,
      auth: credentials,
    };
  }

  return {
    service: process.env.SMTP_SERVICE || 'gmail',
    auth: credentials,
  };
};

// Gmail API üzerinden gönderim (SMTP kısıtlarını aşmak için HTTPS/443 kullanır)
async function sendViaGmailApi({ to, subject, text, html }) {
  const clientId = process.env.GMAIL_CLIENT_ID;
  const clientSecret = process.env.GMAIL_CLIENT_SECRET;
  const refreshToken = process.env.GMAIL_REFRESH_TOKEN;
  const sender = process.env.GMAIL_SENDER || process.env.MAIL_FROM || process.env.GMAIL_USER;

  if (!clientId || !clientSecret || !refreshToken || !sender) {
    throw new Error('Gmail API credentials missing. Set GMAIL_CLIENT_ID, GMAIL_CLIENT_SECRET, GMAIL_REFRESH_TOKEN and GMAIL_SENDER/MAIL_FROM.');
  }

  const oauth2Client = new google.auth.OAuth2(clientId, clientSecret);
  oauth2Client.setCredentials({ refresh_token: refreshToken });
  const gmail = google.gmail({ version: 'v1', auth: oauth2Client });

  // MIME mesajını oluştur
  const fromHeader = typeof sender === 'string' ? sender : `${sender.name} <${sender.email}>`;
  const isHtml = !!html;
  const body = html || text || '';
  const headers = [
    `From: ${fromHeader}`,
    `To: ${to}`,
    `Subject: ${subject}`,
    'MIME-Version: 1.0',
    isHtml ? 'Content-Type: text/html; charset="UTF-8"' : 'Content-Type: text/plain; charset="UTF-8"',
    '',
    body,
  ].join('\n');

  const raw = Buffer.from(headers)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');

  const res = await gmail.users.messages.send({
    userId: 'me',
    requestBody: { raw },
  });

  if (process.env.NODE_ENV !== 'production') {
    console.log('📧 Gmail API sent', { to, id: res.data?.id });
  }

  return { messageId: res.data?.id, response: 'GMAIL_API_SENT' };
}

// HTTP Relay (diğer sunucu üzerinden gönderim)
async function sendViaHttpRelay({ to, subject, text, html }) {
  const relayUrl = process.env.RELAY_MAIL_URL;
  const relayKey = process.env.RELAY_API_KEY;
  
  if (!relayUrl || !relayKey) {
    throw new Error('RELAY_MAIL_URL and RELAY_API_KEY required for HTTP relay.');
  }

  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ to, subject, body: html || text });
    const url = new URL(relayUrl);
    const client = url.protocol === 'https:' ? https : http;
    
    const req = client.request(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
        'X-API-Key': relayKey,
      },
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          const response = JSON.parse(data);
          console.log('📧 HTTP Relay sent', { to, messageId: response.messageId });
          resolve({ messageId: response.messageId, response: 'RELAY_SENT' });
        } else {
          reject(new Error(`HTTP Relay failed: ${res.statusCode} ${data}`));
        }
      });
    });
    
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

const sendMail = async ({ to, subject, text, html, attachments }) => {
  if (!to || !subject || (!text && !html)) {
    throw new Error('Missing required email fields: to, subject and text or html.');
  }

  // Önce HTTP Relay seçeneği var mı bak
  if (process.env.RELAY_MAIL_URL) {
    try {
      return await sendViaHttpRelay({ to, subject, text, html });
    } catch (e) {
      console.error('❌ HTTP Relay send failed, falling back to Gmail API/SMTP:', e?.message || e);
    }
  }

  // Önce Gmail API seçeneği var mı bak
  if (process.env.GMAIL_API === '1') {
    try {
      return await sendViaGmailApi({ to, subject, text, html });
    } catch (e) {
      console.error('❌ Gmail API send failed, falling back to SMTP:', e?.message || e);
      // Devam edip SMTP ile deneyelim
    }
  }

  const credentials = getSmtpCredentials();
  const transporter = nodemailer.createTransport(buildTransportConfig(credentials));

  const mailOptions = {
    from: process.env.MAIL_FROM || credentials.user,
    to,
    subject,
    text,
    html,
    attachments,
  };

  const info = await transporter.sendMail(mailOptions);

  if (process.env.NODE_ENV !== 'production') {
    console.log('📧 Email sent', {
      messageId: info.messageId,
      to,
      response: info.response,
    });
  }

  return info;
};

module.exports = { sendMail };
