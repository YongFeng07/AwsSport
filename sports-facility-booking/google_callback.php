<?php
require 'config.php';
require 'auth.php';

function google_request(string $url, ?array $postFields = null, array $extraHeaders = []): array {
    if (!function_exists('curl_init')) {
        throw new RuntimeException('The PHP cURL extension is required for Google login.');
    }
    $curl = curl_init($url);
    curl_setopt_array($curl, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
        CURLOPT_HTTPHEADER => array_merge(['Accept: application/json'], $extraHeaders),
    ]);
    if ($postFields !== null) {
        curl_setopt($curl, CURLOPT_POST, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, http_build_query($postFields));
    }
    $body = curl_exec($curl);
    $status = (int)curl_getinfo($curl, CURLINFO_HTTP_CODE);
    $curlError = curl_error($curl);
    curl_close($curl);
    $data = is_string($body) ? json_decode($body, true) : null;
    if ($curlError !== '' || $status < 200 || $status >= 300 || !is_array($data)) {
        throw new RuntimeException('Google authentication request failed.');
    }
    return $data;
}

try {
    if (!google_login_enabled()) {
        throw new RuntimeException('Google login is not configured.');
    }
    $state = $_GET['state'] ?? '';
    $expectedState = $_SESSION['google_oauth_state'] ?? '';
    unset($_SESSION['google_oauth_state']);
    if ($state === '' || $expectedState === '' || !hash_equals($expectedState, $state)) {
        throw new RuntimeException('Invalid OAuth state. Please try again.');
    }
    $code = $_GET['code'] ?? '';
    if ($code === '') {
        throw new RuntimeException('Google login was cancelled or denied.');
    }
    $token = google_request('https://oauth2.googleapis.com/token', [
        'code' => $code,
        'client_id' => getenv('GOOGLE_CLIENT_ID'),
        'client_secret' => getenv('GOOGLE_CLIENT_SECRET'),
        'redirect_uri' => getenv('GOOGLE_REDIRECT_URI'),
        'grant_type' => 'authorization_code',
    ]);
    if (empty($token['access_token'])) {
        throw new RuntimeException('Google did not return an access token.');
    }
    $profile = google_request(
        'https://openidconnect.googleapis.com/v1/userinfo',
        null,
        ['Authorization: Bearer ' . $token['access_token']]
    );
    if (empty($profile['sub']) || empty($profile['email']) || empty($profile['email_verified'])) {
        throw new RuntimeException('A verified Google email address is required.');
    }
    $googleSub = (string)$profile['sub'];
    $email = strtolower(trim((string)$profile['email']));
    $name = trim((string)($profile['name'] ?? $email));

    $stmt = $conn->prepare('SELECT id, name, is_admin, google_sub FROM users WHERE google_sub = ? OR email = ? LIMIT 1');
    $stmt->bind_param('ss', $googleSub, $email);
    $stmt->execute();
    $user = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    if ($user) {
        if ($user['google_sub'] !== null && !hash_equals((string)$user['google_sub'], $googleSub)) {
            throw new RuntimeException('This email is already linked to another Google account.');
        }
        if ($user['google_sub'] === null) {
            $stmt = $conn->prepare('UPDATE users SET google_sub = ? WHERE id = ?');
            $stmt->bind_param('si', $googleSub, $user['id']);
            $stmt->execute();
            $stmt->close();
        }
    } else {
        $stmt = $conn->prepare('INSERT INTO users (name, email, password_hash, google_sub) VALUES (?, ?, NULL, ?)');
        $stmt->bind_param('sss', $name, $email, $googleSub);
        if (!$stmt->execute()) {
            throw new RuntimeException('Could not create the Google account.');
        }
        $user = ['id' => $stmt->insert_id, 'name' => $name, 'is_admin' => 0];
        $stmt->close();
    }
    session_regenerate_id(true);
    $_SESSION['user_id'] = (int)$user['id'];
    $_SESSION['user_name'] = $user['name'];
    $_SESSION['is_admin'] = (bool)$user['is_admin'];
    header('Location: ' . ($user['is_admin'] ? 'admin/facilities.php' : 'index.php'));
    exit;
} catch (Throwable $e) {
    error_log('Google OAuth error: ' . $e->getMessage());
    http_response_code(400);
    $error = $e->getMessage();
    $pageTitle = 'Google Login Error';
    require 'partials/header.php';
    echo '<div class="auth-card"><h1>Google Login Failed</h1><p class="alert alert-error">' . htmlspecialchars($error) . '</p><p><a href="login.php">Return to login</a></p></div>';
    require 'partials/footer.php';
}
