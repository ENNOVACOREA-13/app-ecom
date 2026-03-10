class Turno {
  final String inicio; // "HH:mm"
  final String fin;    // "HH:mm"

  const Turno({required this.inicio, required this.fin});

  factory Turno.fromMap(Map<String, dynamic> map) {
    return Turno(
      inicio: (map['slot_start'] as String).substring(0, 5),
      fin: (map['slot_end'] as String).substring(0, 5),
    );
  }

  @override
  String toString() => '$inicio – $fin';
}
