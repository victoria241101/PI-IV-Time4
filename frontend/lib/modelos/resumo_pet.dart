/// resumo de um pet para exibição em listas e cartões
class ResumoPet {
  const ResumoPet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.age,
    this.weight,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String species;
  final String? breed;
  final String? age;
  final double? weight;
  final String? photoUrl;

  factory ResumoPet.fromMap(Map<String, Object?> dados) {
    return ResumoPet(
      id: dados['id']! as String,
      name: dados['nome']! as String,
      species: dados['especie']! as String,
      breed: dados['raca'] as String?,
      age: dados['idade'] as String?,
      weight: (dados['peso'] as num?)?.toDouble(),
      photoUrl: dados['urlFoto'] as String?,
    );
  }
}
