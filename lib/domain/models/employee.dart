class Empleado {
  final String id;
  final String userId;
  final String alias;
  Empleado({required this.id, required this.userId, required this.alias});
  factory Empleado.fromMap(Map<String, dynamic> m) => Empleado(id: m['id'], userId: m['user_id'], alias: m['alias']);
}
