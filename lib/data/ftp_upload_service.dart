import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Sube imágenes al servidor Hostinger vía HTTP multipart.
/// El script PHP (server/upload.php) debe estar en public_html/upload.php.
class ServicioFTP {
  static const _urlSubida = 'https://prettycore.xyz/upload.php';
  static const _claveApi = 'Prettycore13.';

  /// Abre la galería, sube la imagen al servidor y retorna la URL pública.
  /// [nombreArchivo] se usa como nombre en el servidor (ej: "afeitadora").
  /// Si se repite el nombre, sobreescribe el archivo anterior (sin duplicados).
  /// Retorna null si el usuario cancela o si ocurre un error.
  static Future<String?> seleccionarYSubirImagen({
    String? nombreArchivo,
    void Function(String mensaje)? onError,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) return null;

    try {
      // XFile.readAsBytes() funciona en Android, iOS y Web
      final bytes = await picked.readAsBytes();
      final fileName = picked.name;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_urlSubida),
      );
      request.fields['key'] = _claveApi;
      if (nombreArchivo != null && nombreArchivo.isNotEmpty) {
        request.fields['filename'] = nombreArchivo;
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        return data['url'] as String?;
      } else {
        final data = jsonDecode(body) as Map<String, dynamic>;
        onError?.call(data['error']?.toString() ?? 'Error ${streamed.statusCode}');
        return null;
      }
    } catch (e) {
      onError?.call('Error al subir imagen: $e');
      return null;
    }
  }
}
