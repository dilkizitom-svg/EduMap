class ConteudoModelo {
  final String id;
  final String titulo;
  final String descricao;
  final String disciplina;
  final String classe;
  final String tipo;
  final String urlArquivo;
  final String userId;

  ConteudoModelo({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.disciplina,
    required this.classe,
    required this.tipo,
    required this.urlArquivo,
    required this.userId,
  });

  // ✅ Supabase
  factory ConteudoModelo.fromSupabase(Map<String, dynamic> map) {
    return ConteudoModelo(
      id:         map['id'].toString(),
      titulo:     map['titulo']      ?? '',
      descricao:  map['descricao']   ?? '',
      disciplina: map['disciplina']  ?? '',
      classe:     map['classe']      ?? '',
      tipo:       map['tipo']        ?? '',
      urlArquivo: map['url_arquivo'] ?? '',
      userId:     map['user_id']     ?? '',
    );
  }
}