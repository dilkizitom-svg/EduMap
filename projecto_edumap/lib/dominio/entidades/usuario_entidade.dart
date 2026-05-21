/// ENTIDADE: Usuário
/// Representa o conceito de usuário no sistema (negócio puro)
/// Não depende de nenhuma biblioteca externa

class UsuarioEntidade {
  // ID único do usuário (Firebase Auth)
  final String uid;
  
  // Nome completo
  final String nome;
  
  // E-mail para login
  final String email;
  
  // Papel: 'aluno', 'professor' ou 'admin'
  final String papel;
  
  // Conta está ativa? (admin pode desativar)
  final bool estaAtivo;
  
  // Classe escolar (7ª a 12ª) - só para alunos
  final int? classeAno;
  
  // Data de criação da conta
  final DateTime? criadoEm;
  
  // Construtor
  UsuarioEntidade({
    required this.uid,
    required this.nome,
    required this.email,
    this.papel = 'aluno',
    this.estaAtivo = true,
    this.classeAno,
    this.criadoEm,
  });
}