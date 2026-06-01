/// IMPLEMENTAÇÃO: Repositório de Autenticação
/// Faz a ponte entre o domínio e o Firebase

import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../dominio/repository/auth_repositorio.dart';
import '../../dominio/entidades/usuario_entidade.dart';
import '../models/usuario_modelo.dart';

class AuthRepositorioImpl implements AuthRepositorio {
  // Instâncias dos serviços Firebase
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Escuta mudanças de autenticação (login/logout)
  @override
  Stream<UsuarioEntidade?> get mudancasEstadoAuth {
    return _auth.authStateChanges().asyncMap((firebaseUsuario) async {
      if (firebaseUsuario == null) return null;

      // Busca dados extras no Firestore
      final documento = await _firestore
          .collection('users')
          .doc(firebaseUsuario.uid)
          .get();
      final dados = documento.data();

      return UsuarioEntidade(
        uid: firebaseUsuario.uid,
        nome: dados?['nome'] ?? firebaseUsuario.displayName ?? '',
        email: firebaseUsuario.email ?? '',
        papel: dados?['papel'] ?? 'aluno',
        estaAtivo: dados?['estaAtivo'] ?? true,
        classeAno: dados?['classeAno'],
      );
    });
  }

  /// Login com e-mail e senha
  @override
  Future<UsuarioEntidade?> loginComEmail(String email, String senha) async {
    try {
      // Tenta autenticar no Firebase
      final resultado = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );

      // Busca dados do Firestore
      final documento = await _firestore
          .collection('users')
          .doc(resultado.user!.uid)
          .get();
      final dados = documento.data();

      return UsuarioEntidade(
        uid: resultado.user!.uid,
        nome: dados?['nome'] ?? resultado.user!.displayName ?? '',
        email: resultado.user!.email ?? '',
        papel: dados?['papel'] ?? 'aluno',
        estaAtivo: dados?['estaAtivo'] ?? true,
        classeAno: dados?['classeAno'],
      );
    } on firebase.FirebaseAuthException catch (e) {
      throw _tratarErro(e);
    }
  }

  /// Registro de novo usuário
  @override
  Future<UsuarioEntidade?> registrarComEmail(
    String email,
    String senha,
    String nome,
  ) async {
    try {
      // 1. Cria usuário no Firebase Auth
      final resultado = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );

      // 2. Atualiza o nome de exibição
      await resultado.user?.updateDisplayName(nome);

      // 3. Cria documento no Firestore
      await _firestore.collection('users').doc(resultado.user!.uid).set({
        'nome': nome.trim(),
        'email': email.trim(),
        'papel': 'aluno',
        'estaAtivo': true,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      // 4. Retorna o usuário criado
      return UsuarioEntidade(
        uid: resultado.user!.uid,
        nome: nome.trim(),
        email: email.trim(),
        papel: 'aluno',
        estaAtivo: true,
      );
    } on firebase.FirebaseAuthException catch (e) {
      throw _tratarErro(e);
    }
  }

  /// Login com Google
  @override
  Future<UsuarioEntidade?> loginComGoogle() async {
    try {
      // 1. Abre tela de escolha de conta Google
      final GoogleSignInAccount? contaGoogle = await _googleSignIn.signIn();
      if (contaGoogle == null) return null;

      // 2. Pega as credenciais
      final GoogleSignInAuthentication authGoogle =
          await contaGoogle.authentication;

      // 3. Cria credencial para o Firebase
      final credencial = firebase.GoogleAuthProvider.credential(
        accessToken: authGoogle.accessToken,
        idToken: authGoogle.idToken,
      );

      // 4. Autentica no Firebase
      final resultado = await _auth.signInWithCredential(credencial);

      // 5. Se for primeiro login, cria documento no Firestore
      if (resultado.additionalUserInfo?.isNewUser == true) {
        await _firestore.collection('users').doc(resultado.user!.uid).set({
          'nome': resultado.user!.displayName ?? '',
          'email': resultado.user!.email ?? '',
          'papel': 'aluno',
          'estaAtivo': true,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }

      // 6. Busca dados do Firestore
      final documento = await _firestore
          .collection('users')
          .doc(resultado.user!.uid)
          .get();
      final dados = documento.data();

      return UsuarioEntidade(
        uid: resultado.user!.uid,
        nome: dados?['nome'] ?? resultado.user!.displayName ?? '',
        email: resultado.user!.email ?? '',
        papel: dados?['papel'] ?? 'aluno',
        estaAtivo: dados?['estaAtivo'] ?? true,
      );
    } catch (e) {
      throw 'Erro ao fazer login com Google';
    }
  }

  /// Logout
  @override
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// TRATAMENTO DE ERROS: converte códigos do Firebase em mensagens amigáveis
  String _tratarErro(firebase.FirebaseAuthException erro) {
    switch (erro.code) {
      case 'user-not-found':
        return 'Usuário não encontrado. Verifique seu e-mail.';
      case 'wrong-password':
        return 'Senha incorreta. Tente novamente.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'invalid-email':
        return 'E-mail inválido. Digite um e-mail válido.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      default:
        return 'Erro: ${erro.message}';
    }
  }
}
