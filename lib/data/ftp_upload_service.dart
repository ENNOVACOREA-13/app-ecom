import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

/// Sube imágenes a Supabase Storage (bucket público `media`), bajo
/// `{tenant_id}/nombreArchivo.ext` — RLS en storage.objects exige que quien
/// escribe sea admin/sysadmin del mismo tenant del prefijo (ver migración
/// 20260819110000_storage_media_bucket_and_logo.sql). Reemplaza al viejo
/// ServicioFTP (subía a un script PHP en el Hostinger/Hetzner ya dado de
/// baja) manteniendo el mismo nombre de clase/método para no tocar cada
/// pantalla que lo llama.
class ServicioFTP {
  static Future<String?> seleccionarYSubirImagen({
    String? nombreArchivo,
    void Function(String mensaje)? onError,
  }) async {
    final tenantId = kTenantIdActivo;
    if (tenantId == null || tenantId.isEmpty) {
      onError?.call('No se pudo determinar el negocio actual.');
      return null;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) return null;

    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
      final nombreBase = (nombreArchivo != null && nombreArchivo.isNotEmpty)
          ? nombreArchivo.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
          : DateTime.now().millisecondsSinceEpoch.toString();
      final ruta = '$tenantId/$nombreBase.$ext';

      await Supabase.instance.client.storage.from('media').uploadBinary(
            ruta,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: picked.mimeType),
          );

      final url = Supabase.instance.client.storage.from('media').getPublicUrl(ruta);
      return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      onError?.call('Error al subir imagen: $e');
      return null;
    }
  }
}
