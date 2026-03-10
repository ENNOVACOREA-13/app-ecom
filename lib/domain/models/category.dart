class Categoria {
  final String id;
  final String nombre;
  Categoria({required this.id, required this.nombre});
  factory Categoria.fromMap(Map<String, dynamic> m) => Categoria(id: m['id'], nombre: m['name']);
}
