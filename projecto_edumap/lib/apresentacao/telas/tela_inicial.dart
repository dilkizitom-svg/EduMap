/// TELA INICIAL (HOME)
/// Exibida após o login bem-sucedido

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provedores/auth_provedor.dart';
import 'tela_login.dart';

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvedor = Provider.of<AuthProvedor>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('EduMap'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await authProvedor.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const TelaLogin()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 100, color: Colors.blue),
              const SizedBox(height: 24),
              
              Text(
                'Bem-vindo(a), ${authProvedor.usuarioAtual?.nome ?? 'Aluno'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Text(
                authProvedor.usuarioAtual?.email ?? '',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Perfil: ${authProvedor.usuarioAtual?.papel ?? 'aluno'}',
                  style: TextStyle(color: Colors.blue.shade800),
                ),
              ),
              const SizedBox(height: 48),
              const Divider(),
              const SizedBox(height: 24),
              
              const Text(
                '📱 Funcionalidades em desenvolvimento',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Column(
                children: [
                  Text('📚 Conteúdos por disciplina'),
                  SizedBox(height: 8),
                  Text('📹 Vídeos offline'),
                  SizedBox(height: 8),
                  Text('📝 Exercícios interativos'),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Biblioteca'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
        currentIndex: 0,
        onTap: (index) {
          _mostrarMensagem(context, 'Em breve');
        },
      ),
    );
  }
  
  void _mostrarMensagem(BuildContext context, String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), duration: const Duration(seconds: 1)),
    );
  }
}