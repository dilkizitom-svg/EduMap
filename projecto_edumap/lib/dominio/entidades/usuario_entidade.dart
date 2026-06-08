class UsuarioEntidade {
  final String uid;
  final String email;
  final String nome;
  final String papel;
  final String telefone;
  final bool estaAtivo;

  UsuarioEntidade({
    required this.uid,
    required this.email,
    required this.nome,
    required this.papel,
    this.telefone = '',
    this.estaAtivo = true,
  });
}