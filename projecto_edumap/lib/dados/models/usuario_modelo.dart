/// MODELO: Usuário (Camada de Dados)
/// Extende a entidade e adiciona métodos para conversão com Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dominio/entidades/usuario_entidade.dart';

class UsuarioModelo extends UsuarioEntidade {
  // Construtor chama a classe pai
  UsuarioModelo({
    required super.uid,
    required super.nome,
    required super.email,
    super.papel,
    super.estaAtivo,
    super.classeAno,
    super.criadoEm,
  });
  
  /// Cria um UsuarioModelo a partir de um documento do Firestore
  factory UsuarioModelo.fromFirestore(DocumentSnapshot documento) {
    final dados = documento.data() as Map<String, dynamic>;
    
    return UsuarioModelo(
      uid: documento.id,
      nome: dados['nome'] ?? '',
      email: dados['email'] ?? '',
      papel: dados['papel'] ?? 'aluno',
      estaAtivo: dados['estaAtivo'] ?? true,
      classeAno: dados['classeAno'],
      criadoEm: (dados['criadoEm'] as Timestamp?)?.toDate(),
    );
  }
  
  /// Converte para Map que vai para o Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'email': email,
      'papel': papel,
      'estaAtivo': estaAtivo,
      'classeAno': classeAno,
      'criadoEm': FieldValue.serverTimestamp(),
    };
  }
}