import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../provedores/auth_provedor.dart';
import 'tela_login.dart';

class TelaPerfil extends StatelessWidget {
  const TelaPerfil({super.key});

  final Color primaryColor = const Color(0xFF1565C0);
  final Color logoutColor = const Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvedor>(context);
    final uid = auth.usuarioAtual?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Perfil', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Erro ao carregar perfil'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String nome = userData['name'] ?? 'Utilizador';
          final String email = userData['email'] ?? '';
          final String papel = userData['role'] ?? 'aluno';
          final String classe = userData['classYear'] ?? 'N/A';
          final Timestamp? criadoEm = userData['createdAt'] as Timestamp?;
          final String dataCriacao = criadoEm != null 
              ? "${criadoEm.toDate().day}/${criadoEm.toDate().month}/${criadoEm.toDate().year}" 
              : "---";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildHeader(nome, papel),
                const SizedBox(height: 32),
                _buildInfoCard("Informações da Conta", {
                  "Nome": nome,
                  "E-mail": email,
                  "Tipo de Conta": papel.toUpperCase(),
                  "Classe": classe,
                  "Membro desde": dataCriacao,
                }),
                const SizedBox(height: 20),
                _buildSettingsCard(context, papel),
                const SizedBox(height: 40),
                _buildLogoutButton(context, auth),
                const SizedBox(height: 40),
                const Text('EduMap v1.0 · 2026', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String nome, String papel) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: primaryColor,
          child: const Icon(Icons.person, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            papel.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, Map<String, String> items) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(height: 24),
            ...items.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key, style: const TextStyle(color: Colors.grey)),
                  Text(e.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, String papel) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Editar Perfil'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          if (papel == 'professor')
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Meus Materiais'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvedor auth) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          await auth.logout();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const TelaLogin()),
              (route) => false,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: logoutColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Sair da Conta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
