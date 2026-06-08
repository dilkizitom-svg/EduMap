import '../../dominio/entidades/usuario_entidade.dart';

class UsuarioModelo extends UsuarioEntidade {
  final DateTime? criadoEm;

  UsuarioModelo({
    required super.uid,
    required super.email,
    required super.nome,
    required super.papel,
    super.telefone,
    super.estaAtivo,
    this.criadoEm,
  });

  // ✅ Supabase — campos em português
  factory UsuarioModelo.fromSupabase(Map<String, dynamic> data) {
    return UsuarioModelo(
      uid:       data['id']        ?? '',
      email:     data['email']     ?? '',
      nome:      data['name']      ?? '',
      papel:     data['role']      ?? 'estudante',
      telefone:  data['phone']     ?? '',
      estaAtivo: data['is_active'] ?? true,
      criadoEm:  data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'name':       nome,
      'email':      email,
      'role':       papel,
      'phone':      telefone,
      'is_active':  estaAtivo,
      'created_at': criadoEm?.toIso8601String(),
    };
  }
}