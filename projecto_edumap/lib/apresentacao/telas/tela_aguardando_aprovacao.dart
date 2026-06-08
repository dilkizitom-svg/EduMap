import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provedores/auth_provedor.dart';
import 'tela_login.dart';

class TelaAguardandoAprovacao extends StatelessWidget {
  const TelaAguardandoAprovacao({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvedor = Provider.of<AuthProvedor>(context, listen: false);
    
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              size: 100,
              color: Color(0xFF1565C0),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aguardando Aprovação',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sua solicitação para ser professor está sendo analisada pela nossa equipe. Você receberá um e-mail assim que for aprovado.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () async {
                  await authProvedor.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const TelaLogin()),
                      (route) => false,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sair da Conta',
                  style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
