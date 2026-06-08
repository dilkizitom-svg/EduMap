import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../dominio/entidades/usuario_entidade.dart';
import '../../dominio/repository/auth_repositorio.dart';
import '../models/usuario_modelo.dart';

class AuthRepositorioImpl implements AuthRepositorio {
  final _auth     = fb.FirebaseAuth.instance;
  final _supabase = Supabase.instance.client;

  @override
  Stream<UsuarioEntidade?> get mudancasEstadoAuth =>
      _auth.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        try {
          final data = await _supabase
              .from('users')
              .select()
              .eq('id', user.uid)
              .maybeSingle();

          if (data == null) return null;

          // ← Não faz signOut — widget_roteador decide o redirecionamento
          return UsuarioModelo.fromSupabase(data);
        } catch (e) {
          debugPrint('❌ mudancasEstadoAuth erro: $e');
          return null;
        }
      });

  @override
  Future<UsuarioEntidade?> loginComEmail(String email, String senha) async {
    try {
      debugPrint('1️⃣ Login Firebase Auth...');
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: senha,
      );

      final user = result.user;
      if (user == null) return null;
      debugPrint('2️⃣ Firebase Auth OK: ${user.uid}');

      // ✅ Buscar perfil no Supabase
      final data = await _supabase
          .from('users')
          .select()
          .eq('id', user.uid)
          .maybeSingle();

      if (data == null) return null;

      final usuario = UsuarioModelo.fromSupabase(data);

      if (!usuario.estaAtivo) {
        await _auth.signOut();
        throw 'A sua conta foi desativada pelo administrador.';
      }

      debugPrint('3️⃣ Login OK. Role: ${usuario.papel}');
      return usuario;

    } on fb.FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuth erro: ${e.code}');
      throw _traduzirErro(e.code);
    }
  }

  @override
  Future<UsuarioEntidade?> registrarComEmail(
      String email,
      String senha,
      String nome, {
        required String role,
        required String phone,
        File? documento,
      }) async {
    try {
      debugPrint('1️⃣ Criando conta Firebase Auth...');
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: senha,
      );

      final user = result.user;
      if (user == null) throw 'Utilizador não criado';
      debugPrint('2️⃣ Conta criada: ${user.uid}');

      await Future.delayed(const Duration(seconds: 1));

      // ✅ 3. Guardar perfil no Supabase
      debugPrint('3️⃣ Gravando perfil no Supabase...');
      await _supabase.from('users').insert({
        'id':          user.uid,
        'name':        nome.trim(),
        'email':       email.trim().toLowerCase(),
        'role':        role,
        'phone':       phone,
        'is_active':   role != 'pendente',
        'created_at':  DateTime.now().toIso8601String(),
      });
      debugPrint('4️⃣ Perfil gravado');

      // ✅ 4. Upload documento no Supabase Storage
      String? documentoUrl;
      if (documento != null) {
        debugPrint('5️⃣ Upload documento...');
        final ext      = documento.path.split('.').last.toLowerCase();
        final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final path     = 'documentos/professores/$fileName';

        await _supabase.storage.from('documentos').upload(path, documento);
        documentoUrl = _supabase.storage.from('documentos').getPublicUrl(path);
        debugPrint('6️⃣ Upload OK: $documentoUrl');

        await _supabase
            .from('users')
            .update({'documento_url': documentoUrl})
            .eq('id', user.uid);
      }

      // ✅ 5. Criar solicitação para professor
      if (role == 'pendente') {
        debugPrint('7️⃣ Criando solicitação...');
        await _supabase.from('solicitacoes_professor').insert({
          'user_id':       user.uid,
          'name':          nome.trim(),
          'email':         email.trim().toLowerCase(),
          'phone':         phone,
          'documento_url': documentoUrl ?? '',
          'status':        'pendente',
          'created_at':    DateTime.now().toIso8601String(),
        });
        debugPrint('8️⃣ Solicitação criada');

        // Não faz signOut — widget_roteador redireciona para TelaAguardandoAprovacao
        return UsuarioEntidade(
          uid:       user.uid,
          email:     email,
          nome:      nome,
          papel:     'pendente',
          telefone:  phone,
          estaAtivo: false,
        );
      }

      debugPrint('✅ Registo completo');
      return UsuarioModelo(
        uid:       user.uid,
        nome:      nome,
        email:     email.trim().toLowerCase(),
        papel:     role,
        telefone:  phone,
        estaAtivo: true,
        criadoEm:  DateTime.now(),
      );

    } on fb.FirebaseAuthException catch (e) {
      debugPrint('❌ Auth erro: ${e.code}');
      throw _traduzirErro(e.code);
    } catch (e) {
      debugPrint('❌ Erro geral: $e');
      rethrow;
    }
  }

  @override
  Future<void> uploadDocumentoProfessor(String uid, File documento) async {
    try {
      final ext      = documento.path.split('.').last.toLowerCase();
      final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path     = 'documentos/professores/$fileName';

      await _supabase.storage.from('documentos').upload(path, documento);
      final url = _supabase.storage.from('documentos').getPublicUrl(path);

      await _supabase
          .from('users')
          .update({'documento_url': url})
          .eq('id', uid);

      final query = await _supabase
          .from('solicitacoes_professor')
          .select()
          .eq('user_id', uid);

      if (query.isNotEmpty) {
        await _supabase
            .from('solicitacoes_professor')
            .update({'documento_url': url})
            .eq('user_id', uid);
      }

      await _auth.signOut();
    } catch (e) {
      debugPrint('❌ Upload erro: $e');
      rethrow;
    }
  }

  @override
  Future<UsuarioEntidade?> loginComGoogle() async => null;

  @override
  Future<void> logout() async => _auth.signOut();

  String _traduzirErro(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Email já está em uso.';
      case 'weak-password':        return 'Senha fraca (mínimo 6 caracteres).';
      case 'invalid-email':        return 'Email inválido.';
      case 'user-not-found':       return 'Utilizador não encontrado.';
      case 'wrong-password':       return 'Senha incorreta.';
      case 'invalid-credential':   return 'Credenciais inválidas.';
      default:                     return 'Erro: $code';
    }
  }
}