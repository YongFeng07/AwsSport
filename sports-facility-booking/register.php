<?php
require 'config.php';
require 'auth.php';
require 'helpers.php';
$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $name          = trim($_POST['name'] ?? '');
    $email         = trim($_POST['email'] ?? '');
    $password      = $_POST['password'] ?? '';
    $confirm       = $_POST['confirm_password'] ?? '';
    $id_number     = trim($_POST['id_number'] ?? '');
    $faculty       = trim($_POST['faculty'] ?? '');
    $date_of_birth = trim($_POST['date_of_birth'] ?? '');
    $captcha       = trim($_POST['captcha'] ?? '');

    $birthDate = DateTimeImmutable::createFromFormat('!Y-m-d', $date_of_birth);
    $birthDateValid = $birthDate !== false
        && $birthDate->format('Y-m-d') === $date_of_birth
        && $birthDate <= new DateTimeImmutable('today');

    if (!verify_captcha($captcha)) {
        $error = 'Incorrect CAPTCHA answer. Please try again.';
    } elseif ($name === '' || $email === '' || $password === '' || $date_of_birth === '' || $id_number === '' || $faculty === '') {
        $error = 'All fields are required.';
    } elseif (!$birthDateValid) {
        $error = 'Date of birth must be a valid date and cannot be in the future.';
    } elseif ($password !== $confirm) {
        $error = 'Passwords do not match.';
    } elseif (strlen($password) < 6) {
        $error = 'Password must be at least 6 characters.';
    } else {
        $stmt = $conn->prepare('SELECT id FROM users WHERE email = ?');
        $stmt->bind_param('s', $email);
        $stmt->execute();
        $exists = $stmt->get_result()->fetch_assoc();
        $stmt->close();

        if ($exists) {
            $error = 'An account with this email already exists.';
        } else {
            $password_hash = password_hash($password, PASSWORD_DEFAULT);
            $stmt = $conn->prepare('INSERT INTO users (name, email, password_hash, id_number, faculty, date_of_birth) VALUES (?, ?, ?, ?, ?, ?)');
            $stmt->bind_param('ssssss', $name, $email, $password_hash, $id_number, $faculty, $date_of_birth);
            $stmt->execute();
            $user_id = $stmt->insert_id;
            $stmt->close();

            session_regenerate_id(true);
            $_SESSION['user_id'] = $user_id;
            $_SESSION['user_name'] = $name;
            $_SESSION['is_admin'] = false;
            header('Location: index.php');
            exit;
        }
    }
}

$pageTitle = 'Register';
require 'partials/header.php';
?>
<div class="auth-card">
<h1>Create an Account</h1>
<?php if ($error): ?><p class="alert alert-error"><?= htmlspecialchars($error) ?></p><?php endif; ?>
<form method="post">
<label>Full Name <span class="required-mark">*</span> <input type="text" name="name" value="<?= htmlspecialchars($_POST['name'] ?? '') ?>" required></label>
<label>Email <span class="required-mark">*</span> <input type="email" name="email" value="<?= htmlspecialchars($_POST['email'] ?? '') ?>" required></label>
<label>Student ID / Staff ID <span class="required-mark">*</span> <input type="text" name="id_number" value="<?= htmlspecialchars($_POST['id_number'] ?? '') ?>" required></label>
<label>Faculty <span class="required-mark">*</span>
<select name="faculty" required>
<option value="">-- Select Faculty / Centre --</option>
<?php foreach (tarumt_faculties() as $f): ?>
<option value="<?= htmlspecialchars($f) ?>" <?= ($_POST['faculty'] ?? '') === $f ? 'selected' : '' ?>><?= htmlspecialchars($f) ?></option>
<?php endforeach; ?>
</select>
</label>
<label>Date of Birth <span class="required-mark">*</span> <input id="date-of-birth" type="date" name="date_of_birth" value="<?= htmlspecialchars($_POST['date_of_birth'] ?? '') ?>" max="<?= date('Y-m-d') ?>" required></label>
<label>Password <span class="required-mark">*</span>
<div class="password-field">
<input type="password" name="password" required>
<button type="button" class="password-toggle" tabindex="-1" aria-label="Show password"></button>
</div>
</label>
<label>Confirm Password <span class="required-mark">*</span>
<div class="password-field">
<input type="password" name="confirm_password" required>
<button type="button" class="password-toggle" tabindex="-1" aria-label="Show password"></button>
</div>
</label>
<label>Robot check: What is <?= htmlspecialchars(captcha_question()) ?>? <span class="required-mark">*</span>
<input type="number" name="captcha" inputmode="numeric" autocomplete="off" required>
</label>
<button type="submit">Register</button>
</form>
<?php if (google_login_enabled()): ?>
<div class="auth-divider"><span>or</span></div>
<a class="google-login-button" href="google_login.php">Continue with Google</a>
<?php endif; ?>
<p>Already have an account? <a href="login.php">Login here</a></p>
</div>
<script>
(function () {
    const input = document.getElementById('date-of-birth');
    const now = new Date();
    const deviceToday = [now.getFullYear(), String(now.getMonth() + 1).padStart(2, '0'), String(now.getDate()).padStart(2, '0')].join('-');
    if (deviceToday < input.max) input.max = deviceToday;
})();
</script>
<?php require 'partials/footer.php'; ?>
