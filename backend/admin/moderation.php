<?php
/**
 * Cola de moderación de avistamientos — backend/admin/moderation.php
 *
 * Página mínima server-rendered, fuera de la app infantil a propósito:
 * esto es una herramienta de adultos, con su propia sesión PHP y su
 * propia pantalla de login, no el mismo JWT que usa el cliente Flutter.
 *
 * Acceso: cualquier usuario con `is_moderator = 1` en la tabla `users`
 * (se activa a mano en la base — ver la migración
 * database/migrations/04_2026_sightings_social.sql). Usa la misma
 * contraseña de su cuenta de la app.
 *
 * Sin esta página, todo avistamiento se queda en 'pending' para siempre
 * y el feed comunitario nunca muestra nada — es la pieza que hace
 * cumplible la moderación previa que exige docs/PRIVACY.md.
 */

declare(strict_types=1);

session_start();

require_once __DIR__ . '/../api/config/database.php';

function h(?string $s): string
{
    return htmlspecialchars($s ?? '', ENT_QUOTES, 'UTF-8');
}

$db = getDB();
$error = null;

// ── Login ────────────────────────────────────────────────────────
if (isset($_POST['login'])) {
    $email    = trim((string) ($_POST['email'] ?? ''));
    $password = (string) ($_POST['password'] ?? '');

    $stmt = $db->prepare('SELECT * FROM users WHERE email = ?');
    $stmt->execute([$email]);
    $user = $stmt->fetch();

    if (!$user || $user['password_hash'] === null
        || !password_verify($password, $user['password_hash'])) {
        $error = 'Credenciales incorrectas.';
    } elseif (!$user['is_moderator']) {
        $error = 'Esta cuenta no tiene permisos de moderación.';
    } else {
        session_regenerate_id(true);
        $_SESSION['moderator_id'] = (int) $user['id'];
        $_SESSION['moderator_name'] = $user['name'];
    }
}

if (isset($_GET['logout'])) {
    session_destroy();
    header('Location: moderation.php');
    exit;
}

$isLoggedIn = isset($_SESSION['moderator_id']);

// Doble comprobación: la sesión pudo quedar abierta desde antes de que
// alguien le quitara `is_moderator` a la cuenta en la base.
if ($isLoggedIn) {
    $stmt = $db->prepare('SELECT is_moderator FROM users WHERE id = ?');
    $stmt->execute([$_SESSION['moderator_id']]);
    if (!(int) $stmt->fetchColumn()) {
        session_destroy();
        $isLoggedIn = false;
        $error = 'Tu permiso de moderación fue revocado.';
    }
}

// ── Acciones (aprobar / rechazar) ───────────────────────────────────
if ($isLoggedIn && isset($_POST['action'], $_POST['sighting_id'])) {
    $status = $_POST['action'] === 'approve' ? 'approved' : 'rejected';
    $id     = (int) $_POST['sighting_id'];

    $stmt = $db->prepare(
        'UPDATE sightings SET moderation_status = ?, moderated_at = NOW() WHERE id = ?'
    );
    $stmt->execute([$status, $id]);

    header('Location: moderation.php');
    exit;
}

$pending = $isLoggedIn
    ? $db->query(
        'SELECT s.id, s.quantity, s.notes, s.photo_url, s.location_name,
                s.created_at, u.name AS author_name, u.email AS author_email
           FROM sightings s
           JOIN users u ON u.id = s.user_id
          WHERE s.moderation_status = "pending"
          ORDER BY s.created_at ASC
          LIMIT 200'
    )->fetchAll()
    : [];
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Moderación de avistamientos — Guardianes de las Luciérnagas</title>
<style>
  :root { color-scheme: light dark; }
  body { font-family: system-ui, sans-serif; max-width: 900px; margin: 0 auto; padding: 24px 16px; background: #0b0f1a; color: #eef2f8; }
  h1 { font-size: 20px; }
  .muted { opacity: .65; font-size: 14px; }
  form.login { display: flex; flex-direction: column; gap: 10px; max-width: 320px; margin-top: 24px; }
  input { padding: 10px 12px; border-radius: 8px; border: 1px solid #2a3a60; background: #131929; color: inherit; }
  button { padding: 10px 14px; border-radius: 8px; border: none; font-weight: 700; cursor: pointer; }
  button.approve { background: #4caf50; color: #06210a; }
  button.reject { background: #ef5350; color: #2a0606; }
  button.login-btn { background: #f5d020; color: #241c00; }
  .error { color: #ff8a80; margin-top: 8px; }
  .topbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
  .card { background: #131929; border: 1px solid #2a3a60; border-radius: 14px; padding: 14px; margin-bottom: 14px; display: flex; gap: 14px; }
  .card img { width: 120px; height: 120px; object-fit: cover; border-radius: 10px; flex-shrink: 0; background: #1c2640; }
  .card .no-photo { width: 120px; height: 120px; border-radius: 10px; flex-shrink: 0; background: #1c2640; display: flex; align-items: center; justify-content: center; font-size: 28px; }
  .card .body { flex: 1; min-width: 0; }
  .card .actions { display: flex; gap: 8px; margin-top: 10px; }
  .empty { text-align: center; padding: 60px 20px; opacity: .6; }
  a { color: #72e26e; }
</style>
</head>
<body>

<?php if (!$isLoggedIn): ?>

  <h1>🔥 Moderación de avistamientos</h1>
  <p class="muted">Acceso solo para cuentas moderadoras.</p>
  <form class="login" method="post">
    <input type="email" name="email" placeholder="Email" required autofocus>
    <input type="password" name="password" placeholder="Contraseña" required>
    <button class="login-btn" type="submit" name="login" value="1">Entrar</button>
  </form>
  <?php if ($error): ?><p class="error"><?= h($error) ?></p><?php endif; ?>

<?php else: ?>

  <div class="topbar">
    <div>
      <h1>🔥 Cola de moderación</h1>
      <p class="muted">
        <?= count($pending) ?> pendiente<?= count($pending) === 1 ? '' : 's' ?>
        · sesión de <?= h($_SESSION['moderator_name']) ?>
        · <a href="?logout=1">Salir</a>
      </p>
    </div>
  </div>

  <?php if (empty($pending)): ?>
    <div class="empty">✨ No hay nada pendiente de revisar.</div>
  <?php endif; ?>

  <?php foreach ($pending as $s): ?>
    <div class="card">
      <?php if ($s['photo_url']): ?>
        <img src="<?= h($s['photo_url']) ?>" alt="">
      <?php else: ?>
        <div class="no-photo">✨</div>
      <?php endif; ?>
      <div class="body">
        <div><strong><?= (int) $s['quantity'] ?></strong> luciérnaga(s) · <?= h($s['location_name'] ?? 'Sin ubicación') ?></div>
        <?php if ($s['notes']): ?><div class="muted"><?= h($s['notes']) ?></div><?php endif; ?>
        <div class="muted">
          por <?= h($s['author_name']) ?> (<?= h($s['author_email']) ?>)
          · <?= h($s['created_at']) ?>
        </div>
        <form method="post" class="actions">
          <input type="hidden" name="sighting_id" value="<?= (int) $s['id'] ?>">
          <button class="approve" type="submit" name="action" value="approve">Aprobar</button>
          <button class="reject" type="submit" name="action" value="reject">Rechazar</button>
        </form>
      </div>
    </div>
  <?php endforeach; ?>

<?php endif; ?>

</body>
</html>
