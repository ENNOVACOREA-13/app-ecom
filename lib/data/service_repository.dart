import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../domain/models/service_model.dart';

/// Ver construirPayloadProducto() en product_repository.dart — mismo motivo.
Map<String, dynamic> construirPayloadServicio({
  required String? tenantId,
  required ModeloServicio servicio,
}) {
  return {...servicio.toMap(), 'tenant_id': tenantId};
}

class RepositorioServicio {
  SupabaseClient get _client => Supabase.instance.client;

  Future<List<ModeloServicio>> obtenerServiciosActivos() async {
    final datos = await _client
        .from('services')
        .select()
        .eq('is_active', true)
        .order('name');
    return (datos as List).map((e) => ModeloServicio.fromMap(e)).toList();
  }

  Future<List<ModeloServicio>> obtenerTodosLosServicios() async {
    final datos = await _client.from('services').select().order('name');
    return (datos as List).map((e) => ModeloServicio.fromMap(e)).toList();
  }

  Future<ModeloServicio> crearServicio(ModeloServicio servicio) async {
    final datos = await _client
        .from('services')
        .insert(construirPayloadServicio(tenantId: kTenantIdActivo, servicio: servicio))
        .select()
        .single();
    return ModeloServicio.fromMap(datos);
  }

  Future<void> actualizarServicio(String id, Map<String, dynamic> actualizaciones) async {
    await _client.from('services').update(actualizaciones).eq('id', id);
  }

  Future<void> eliminarServicio(String id) async {
    await _client.from('services').update({'is_active': false}).eq('id', id);
  }

  // Servicios que puede realizar un empleado específico
  Future<List<ModeloServicio>> obtenerServiciosPorEmpleado(String idEmpleado) async {
    final datos = await _client
        .from('employee_services')
        .select('service_id, services(*)')
        .eq('employee_id', idEmpleado);
    return (datos as List)
        .map((e) => ModeloServicio.fromMap(e['services'] as Map<String, dynamic>))
        .toList();
  }

  Future<void> asignarServicioAEmpleado(String idEmpleado, String idServicio) async {
    await _client.from('employee_services').upsert({
      'employee_id': idEmpleado,
      'service_id': idServicio,
      'tenant_id': kTenantIdActivo,
    });
  }

  Future<void> quitarServicioDeEmpleado(String idEmpleado, String idServicio) async {
    await _client
        .from('employee_services')
        .delete()
        .eq('employee_id', idEmpleado)
        .eq('service_id', idServicio);
  }

  Future<String> subirImagenServicio(String idServicio, Uint8List bytes, String formato) async {
    final ruta = '$idServicio.$formato';
    await _client.storage.from('services').uploadBinary(
      ruta,
      bytes,
      fileOptions: FileOptions(upsert: true, contentType: 'image/$formato'),
    );
    return _client.storage.from('services').getPublicUrl(ruta);
  }
}
