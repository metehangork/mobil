<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-API-Key');

// OPTIONS preflight için
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// API Key kontrolü (ana API .env ile eşleşmeli)
$apiKey = 'unicampus_secret_2025_change_this';
if (!isset($_SERVER['HTTP_X_API_KEY']) || $_SERVER['HTTP_X_API_KEY'] !== $apiKey) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized - Invalid API Key']);
    exit;
}

// POST verisi kontrolü
$raw = file_get_contents('php://input');
$data = json_decode($raw, true);
if (!$data || !isset($data['to'], $data['subject'], $data['body'])) {
    http_response_code(400);
    echo json_encode([
        'error' => 'Missing required fields: to, subject, body',
        'received' => $raw,
    ]);
    exit;
}

// PHPMailer autoload fallback (Composer yoksa)
$autoloadOk = false;
// 1) Standart vendor/autoload
if (file_exists(__DIR__ . '/vendor/autoload.php')) {
    require __DIR__ . '/vendor/autoload.php';
    $autoloadOk = true;
}
// 2) Manuel kurulum - vendor/phpmailer/phpmailer/src
elseif (
    file_exists(__DIR__ . '/vendor/phpmailer/phpmailer/src/PHPMailer.php') &&
    file_exists(__DIR__ . '/vendor/phpmailer/phpmailer/src/SMTP.php') &&
    file_exists(__DIR__ . '/vendor/phpmailer/phpmailer/src/Exception.php')
) {
    require_once __DIR__ . '/vendor/phpmailer/phpmailer/src/PHPMailer.php';
    require_once __DIR__ . '/vendor/phpmailer/phpmailer/src/SMTP.php';
    require_once __DIR__ . '/vendor/phpmailer/phpmailer/src/Exception.php';
    $autoloadOk = true;
}
// 3) Alternatif klasör adıyla (ör: PHPMailer-6.11.1/src)
elseif (
    file_exists(__DIR__ . '/PHPMailer-6.11.1/src/PHPMailer.php') &&
    file_exists(__DIR__ . '/PHPMailer-6.11.1/src/SMTP.php') &&
    file_exists(__DIR__ . '/PHPMailer-6.11.1/src/Exception.php')
) {
    require_once __DIR__ . '/PHPMailer-6.11.1/src/PHPMailer.php';
    require_once __DIR__ . '/PHPMailer-6.11.1/src/SMTP.php';
    require_once __DIR__ . '/PHPMailer-6.11.1/src/Exception.php';
    $autoloadOk = true;
}

if (!$autoloadOk) {
    http_response_code(500);
    echo json_encode([
        'error' => 'PHPMailer not found',
        'hint' => 'Upload vendor/ with phpmailer/phpmailer or PHPMailer-<version>/src to the same directory as send-mail.php.',
        'cwd' => __DIR__
    ]);
    exit;
}

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

$mail = new PHPMailer(true);

try {
    // SMTP ayarları
    $mail->isSMTP();
    $mail->Host = 'smtp.gmail.com';
    $mail->SMTPAuth = true;
    $mail->Username = 'kafadarkampus@gmail.com';
    $mail->Password = 'mcudupyktwseyyjf'; // Gmail App Password
    $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
    $mail->Port = 587;
    $mail->CharSet = 'UTF-8';

    // Gönderici ve alıcı
    $mail->setFrom('kafadarkampus@gmail.com', 'UniCampus');
    $mail->addAddress($data['to']);

    // İçerik
    $mail->isHTML(true);
    $mail->Subject = $data['subject'];
    $mail->Body = $data['body'];
    $mail->AltBody = strip_tags($data['body']);

    // Gönder
    $mail->send();

    // Başarılı
    echo json_encode([
        'sent' => true,
        'messageId' => uniqid('msg_', true),
        'to' => $data['to'],
        'timestamp' => date('c')
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'Mail sending failed',
        'details' => $e->getMessage()
    ]);
}
