import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'telas/tela_login.dart';
import 'telas/tela_inicial_admin.dart';
import 'telas/tela_inicial_professor.dart';
import 'telas/tela_inicial_estudante.dart';

class WidgetRoteador extends StatelessWidget {
  const WidgetRoteador({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Se a conexão ainda está sendo estabelecida
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            ),
          );
        }

        // Se o utilizador não está autenticado
        if (!snapshot.hasData || snapshot.data == null) {
          return const TelaLogin();
        }

        // Se o utilizador está autenticado, verifica o role no Firestore
        final User user = snapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                ),
              );
            }

            if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
              // Se houver erro ao ler os dados do utilizador, força o logout para segurança
              FirebaseAuth.instance.signOut();
              return const TelaLogin();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final String role = userData['role'] ?? 'estudante';

            switch (role.toLowerCase()) {
              case 'admin':
                return const TelaInicialAdmin();
              case 'professor':
                return const TelaInicialProfessor();
              case 'estudante':
              default:
                return const TelaInicialEstudante();
            }
          },
        );
      },
    );
  }
}
