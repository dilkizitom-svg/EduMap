
/// PROVEDOR: Gerencia o estado da autenticação na interface
/// Usa ChangeNotifier + Provider para notificar as telas

import 'package:flutter/material.dart';
import '../../dominio/entidades/usuario_entidade.dart';
import '../../dominio/repository/auth_repositorio.dart';
import '../../dados/repository/auth_repositorio_impl.dart';

class AuthProvedor extends ChangeNotifier {
  // Instância do repositório
  final AuthRepositorio _authRepositorio = AuthRepositorioImpl();
  
  // Estado atual
  UsuarioEntidade? _usuarioAtual;
  bool _estaCarregando = false;
  String? _mensagemErro;
  
  // Construtor: começa a escutar mudanças
  AuthProvedor() {
    _escutarMudancasAuth();
  }
  
  // Getters (acessíveis pelas telas)
  UsuarioEntidade? get usuarioAtual => _usuarioAtual;
  bool get estaCarregando => _estaCarregando;
  String? get mensagemErro => _mensagemErro;
  
  /// Escuta mudanças de autenticação (login/logout)
  void _escutarMudancasAuth() {
    _authRepositorio.mudancasEstadoAuth.listen((usuario) {
      _usuarioAtual = usuario;
      notifyListeners();  // Avisa as telas para atualizar
    });
  }
  
  /// Login com e-mail e senha
  Future<bool> login(String email, String senha) async {
    _setCarregando(true);
    _limparErro();
    
    try {
      final usuario = await _authRepositorio.loginComEmail(email, senha);
      _setCarregando(false);
      return usuario != null;
    } catch (e) {
      _setErro(e.toString());
      _setCarregando(false);
      return false;
    }
  }
  
  /// Registrar novo usuário
  Future<bool> registrar(String email, String senha, String nome) async {
    _setCarregando(true);
    _limparErro();
    
    try {
      final usuario = await _authRepositorio.registrarComEmail(email, senha, nome);
      _setCarregando(false);
      return usuario != null;
    } catch (e) {
      _setErro(e.toString());
      _setCarregando(false);
      return false;
    }
  }
  
  /// Login com Google
  Future<bool> loginComGoogle() async {
    _setCarregando(true);
    _limparErro();
    
    try {
      final usuario = await _authRepositorio.loginComGoogle();
      _setCarregando(false);
      return usuario != null;
    } catch (e) {
      _setErro(e.toString());
      _setCarregando(false);
      return false;
    }
  }
  
  /// Sair da conta
  Future<void> logout() async {
    await _authRepositorio.logout();
  }
  
  // Métodos privados para gerenciar estado
  void _setCarregando(bool valor) {
    _estaCarregando = valor;
    notifyListeners();
  }
  
  void _setErro(String mensagem) {
    _mensagemErro = mensagem;
    notifyListeners();
  }
  
  void _limparErro() {
    _mensagemErro = null;
    notifyListeners();
  }
}