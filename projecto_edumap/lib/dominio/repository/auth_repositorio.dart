/// INTERFACE: Repositório de Autenticação
/// Define QUAIS operações de autenticação o sistema deve ter
/// Quem implementar esta interface (dados/repositorios/) terá que cumprir este contrato

import '../entidades/usuario_entidade.dart';

abstract class AuthRepositorio {
  /// Stream que emite mudanças no estado de autenticação
  /// Emite UsuarioEntidade quando logado, null quando deslogado
  Stream<UsuarioEntidade?> get mudancasEstadoAuth;
  
  /// Login com e-mail e senha
  Future<UsuarioEntidade?> loginComEmail(String email, String senha);
  
  /// Registrar novo usuário
  Future<UsuarioEntidade?> registrarComEmail(
    String email, 
    String senha, 
    String nome,
  );
  
  /// Login com Google
  Future<UsuarioEntidade?> loginComGoogle();
  
  /// Sair da conta
  Future<void> logout();
}