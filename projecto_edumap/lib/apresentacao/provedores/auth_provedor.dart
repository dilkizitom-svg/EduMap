import 'dart:io';
import 'package:flutter/material.dart';
import '../../dominio/entidades/usuario_entidade.dart';
import '../../dominio/repository/auth_repositorio.dart';
import '../../dados/repository/auth_repositorio_impl.dart';

class AuthProvedor extends ChangeNotifier {
  final AuthRepositorio _authRepositorio = AuthRepositorioImpl();

  UsuarioEntidade? _usuarioAtual;
  bool _estaCarregando = false;
  String? _mensagemErro;

  AuthProvedor() {
    _escutarMudancasAuth();
  }

  UsuarioEntidade? get usuarioAtual => _usuarioAtual;
  bool get estaCarregando          => _estaCarregando;
  String? get mensagemErro         => _mensagemErro;

  void _escutarMudancasAuth() {
    _authRepositorio.mudancasEstadoAuth.listen((usuario) {
      _usuarioAtual = usuario;
      notifyListeners();
    });
  }

  Future<bool> login(String email, String senha) async {
    _setCarregando(true);
    _limparErro();
    try {
      final usuario = await _authRepositorio.loginComEmail(email, senha);
      _usuarioAtual = usuario;
      notifyListeners();
      _setCarregando(false);
      return usuario != null;
    } catch (e) {
      _setErro(e.toString());
      _setCarregando(false);
      return false;
    }
  }

  Future<bool> registrar(
      String email,
      String senha,
      String nome, {
        required String role,
        required String phone,
        File? documento,
      }) async {
    _setCarregando(true);
    _limparErro();
    try {
      final usuario = await _authRepositorio.registrarComEmail(
        email, senha, nome,
        role:      role,
        phone:     phone,
        documento: documento,
      );
      // Professor pendente — não define usuário atual
      if (usuario?.papel == 'pendente') {
        _usuarioAtual = null;
      } else {
        _usuarioAtual = usuario;
      }
      notifyListeners();
      _setCarregando(false);
      return true;
    } catch (e) {
      _setErro(e.toString());
      _setCarregando(false);
      return false;
    }
  }

  Future<void> uploadDocumentoProfessor(String uid, File documento) async {
    await _authRepositorio.uploadDocumentoProfessor(uid, documento);
  }

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

  Future<void> logout() async {
    await _authRepositorio.logout();
    _usuarioAtual = null;
    notifyListeners();
  }

  void _setCarregando(bool valor) {
    _estaCarregando = valor;
    notifyListeners();
  }

  void _setErro(String msg) {
    _mensagemErro = msg;
    notifyListeners();
  }

  void _limparErro() {
    _mensagemErro = null;
    notifyListeners();
  }
}