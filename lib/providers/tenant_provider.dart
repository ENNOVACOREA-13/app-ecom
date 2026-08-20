import 'package:flutter/material.dart';
import '../data/tenant_repository.dart';
import '../domain/models/tenant.dart';

class ProveedorTenants extends ChangeNotifier {
  ProveedorTenants({RepositorioTenants? repo}) : _repo = repo ?? RepositorioTenants();

  final RepositorioTenants _repo;

  List<Tenant> _tenants = [];
  bool _cargando = false;
  String? _error;

  List<Tenant> get tenants => _tenants;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargarTenants() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _tenants = await _repo.obtenerTenants();
    } catch (e) {
      _error = 'No se pudo cargar la lista de negocios.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> crearTenant({required String slug, required String businessName}) async {
    _error = null;
    try {
      await _repo.crearTenant(slug: slug, businessName: businessName);
      await cargarTenants();
      return true;
    } catch (e) {
      _error = e.toString().contains('duplicate key')
          ? 'Ese slug ya está en uso por otro negocio.'
          : 'No se pudo crear el negocio.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarStatus(String tenantId, String status) async {
    try {
      await _repo.actualizarStatus(tenantId, status);
      await cargarTenants();
      return true;
    } catch (e) {
      _error = 'No se pudo actualizar el estado del negocio.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> agregarDominio(String tenantId, String domain) async {
    _error = null;
    try {
      await _repo.agregarDominio(tenantId, domain);
      await cargarTenants();
      return true;
    } catch (e) {
      _error = e.toString().contains('duplicate key')
          ? 'Ese dominio ya está vinculado a otro negocio.'
          : 'No se pudo agregar el dominio.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarDominio(String domainId) async {
    try {
      await _repo.eliminarDominio(domainId);
      await cargarTenants();
      return true;
    } catch (e) {
      _error = 'No se pudo quitar el dominio.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarMembresia({required String userId, required String tenantId}) async {
    try {
      await _repo.eliminarMembresia(userId: userId, tenantId: tenantId);
      await cargarTenants();
      return true;
    } catch (e) {
      _error = 'No se pudo quitar el acceso de esa cuenta.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> editarPerfilAdmin({
    required String userId,
    required String nombre,
    String? telefono,
  }) async {
    try {
      await _repo.editarPerfilAdmin(userId: userId, nombre: nombre, telefono: telefono);
      await cargarTenants();
      return true;
    } catch (e) {
      _error = 'No se pudo guardar los cambios de esa cuenta.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarPerfilAdmin(String userId) async {
    try {
      await _repo.eliminarPerfilAdmin(userId);
      await cargarTenants();
      return true;
    } catch (e) {
      _error = e.toString().contains('No se puede eliminar una cuenta sysadmin')
          ? 'Las cuentas sysadmin no se pueden eliminar.'
          : 'No se pudo eliminar esa cuenta.';
      notifyListeners();
      return false;
    }
  }
}
