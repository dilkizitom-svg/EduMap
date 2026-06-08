import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;  // ← alias
import 'package:supabase_flutter/supabase_flutter.dart';
import 'telas/tela_login.dart';
import 'telas/tela_inicial_admin.dart';
import 'telas/tela_inicial_professor.dart';
import 'telas/tela_inicial_estudante.dart';
import 'telas/tela_aguardando_aprovacao.dart';

class WidgetRoteador extends StatelessWidget {
  const WidgetRoteador({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Firebase Auth para sessão — usa fb.FirebaseAuth e fb.User
    return StreamBuilder<fb.User?>(
      stream: fb.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator(color: Color(0xFF1565C0))),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const TelaLogin();
        }

        final uid = snapshot.data!.uid;

        // ✅ Supabase para buscar o role
        return FutureBuilder<Map<String, dynamic>?>(
          future: Supabase.instance.client
              .from('users')
              .select()
              .eq('id', uid)
              .maybeSingle(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                    child: CircularProgressIndicator(color: Color(0xFF1565C0))),
              );
            }

            final data = userSnapshot.data;

            if (data == null) {
              fb.FirebaseAuth.instance.signOut();
              return const TelaLogin();
            }

            final role     = data['role']      ?? 'estudante';
            final isActive = data['is_active'] ?? true;

            if (role == 'pendente' || !isActive) {
              return const TelaAguardandoAprovacao();
            }

            switch (role.toLowerCase()) {
              case 'admin':     return const TelaInicialAdmin();
              case 'professor': return const TelaInicialProfessor();
              default:          return const TelaInicialEstudante();
            }
          },
        );
      },
    );
  }
}