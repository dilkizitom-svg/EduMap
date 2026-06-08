import 'dart:io';
import '../entidades/usuario_entidade.dart';

abstract class AuthRepositorio {
  Stream<UsuarioEntidade?> get mudancasEstadoAuth;
  Future<UsuarioEntidade?> loginComEmail(String email, String senha);
  Future<UsuarioEntidade?> registrarComEmail(
      String email,
      String senha,
      String nome, {
        required String role,
        required String phone,
        File? documento,
      });
  Future<void> uploadDocumentoProfessor(String uid, File documento);
  Future<UsuarioEntidade?> loginComGoogle();
  Future<void> logout();
}