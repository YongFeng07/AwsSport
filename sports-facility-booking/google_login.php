<?php
require 'config.php';
require 'auth.php';

if (!google_login_enabled()) {
    http_response_code(503);
    die('Google login is not configured.');
}

$state = bin2hex(random_bytes(32));
$_SESSION['google_oauth_state'] = $state;
$params = http_build_query([
    'client_id' => getenv('GOOGLE_CLIENT_ID'),
    'redirect_uri' => getenv('GOOGLE_REDIRECT_URI'),
    'response_type' => 'code',
    'scope' => 'openid email profile',
    'state' => $state,
    'prompt' => 'select_account',
]);
header('Location: https://accounts.google.com/o/oauth2/v2/auth?' . $params);
exit;
