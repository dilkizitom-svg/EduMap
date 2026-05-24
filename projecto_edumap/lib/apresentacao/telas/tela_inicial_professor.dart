import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../provedores/auth_provedor.dart';
import 'package:projecto_edumap/apresentacao/telas/tela_disciplina_professor.dart';
import 'package:projecto_edumap/apresentacao/telas/tela_biblioteca.dart';
import 'package:projecto_edumap/apresentacao/telas/tela_perfil.dart';

class TelaInicialProfessor extends StatefulWidget {
  const TelaInicialProfessor({super.key});

  @override
  State<TelaInicialProfessor> createState() => _TelaInicialProfessorState();
}

class _TelaInicialProfessorState extends State<TelaInicialProfessor> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Removido 'const' para evitar erro de expressão não constante
    final List<Widget> pages = [
      HomeProfessorTab(),
      TelaBiblioteca(),
      TelaPerfil(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Biblioteca'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class HomeProfessorTab extends StatelessWidget {
  const HomeProfessorTab({super.key});

  final List<String> disciplinas = const [
    'Álgebra Linear',
    'Matemática Discreta',
    'Programação I',
    'Electrónica Digital',
    'PRDM'
  ];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final primaryColor = const Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('EduMap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(context, primaryColor, uid),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('As Minhas Disciplinas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...disciplinas.map((d) => _buildDisciplinaCard(context, d, primaryColor)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color color, String? uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        String nome = "Professor";
        if (snapshot.hasData && snapshot.data!.exists) {
          nome = (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? "Professor";
        }
        return Container(
          width: double.infinity,
          color: color,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bem-vindo, $nome', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              Text('Área do Professor', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisciplinaCard(BuildContext context, String nome, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaDisciplinaProfessor(disciplina: nome))),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.menu_book, color: color),
        ),
        title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('content').where('subject', isEqualTo: nome).snapshots(),
          builder: (context, snapshot) {
            int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
            return Text('$count materiais', style: const TextStyle(fontSize: 12));
          },
        ),
        trailing: IconButton(
          icon: Icon(Icons.add_circle, color: color),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaDisciplinaProfessor(disciplina: nome, abrirUpload: true))),
        ),
      ),
    );
  }
}
