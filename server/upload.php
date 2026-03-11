<?php
// ── upload.php ─────────────────────────────────────────────────
// Sube este archivo a: public_html/upload.php  (Hostinger)
// Las imágenes se guardan en: public_html/FLUTTER/APP1/
// URL pública resultante: https://prettycore.xyz/FLUTTER/APP1/nombre.jpg
// ───────────────────────────────────────────────────────────────

header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

// Clave secreta — debe coincidir con _claveApi en ServicioFTP
$claveSecreta = 'Prettycore13.';

if (!isset($_POST['key']) || $_POST['key'] !== $claveSecreta) {
    http_response_code(401);
    echo json_encode(['error' => 'No autorizado']);
    exit;
}

if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(['error' => 'Sin archivo o error de subida: ' . ($_FILES['image']['error'] ?? 'ninguno')]);
    exit;
}

// Carpeta destino (dentro de public_html para ser accesible vía HTTP)
$carpeta = __DIR__ . '/FLUTTER/APP1/';
if (!is_dir($carpeta)) {
    mkdir($carpeta, 0755, true);
}

// Crear .htaccess con CORS para que las imágenes carguen desde Flutter Web
$htaccess = $carpeta . '.htaccess';
if (!file_exists($htaccess)) {
    file_put_contents($htaccess,
        "<IfModule mod_headers.c>\n" .
        "    Header set Access-Control-Allow-Origin \"*\"\n" .
        "</IfModule>\n"
    );
}

$ext = strtolower(pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION));
$permitidos = ['jpg', 'jpeg', 'png', 'webp'];

if (!in_array($ext, $permitidos)) {
    http_response_code(400);
    echo json_encode(['error' => 'Tipo de archivo no permitido: ' . $ext]);
    exit;
}

// Usar nombre provisto (slug del producto/servicio) o generar uno único
if (!empty($_POST['filename'])) {
    // Sanear: minúsculas, solo letras/números/guiones, sin espacios
    $slug = strtolower(trim($_POST['filename']));
    $slug = preg_replace('/[^a-z0-9]+/', '_', $slug);
    $slug = trim($slug, '_');
    $nombre = ($slug ?: 'img') . '.' . $ext;
} else {
    $nombre = uniqid('img_', true) . '.' . $ext;
}

$destino = $carpeta . $nombre;

if (move_uploaded_file($_FILES['image']['tmp_name'], $destino)) {
    echo json_encode([
        'url' => 'https://prettycore.xyz/FLUTTER/APP1/' . $nombre . '?v=' . time()
    ]);
} else {
    http_response_code(500);
    echo json_encode(['error' => 'Error al guardar el archivo en el servidor']);
}
