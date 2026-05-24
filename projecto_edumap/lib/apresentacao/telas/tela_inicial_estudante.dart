import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projecto_edumap/apresentacao/telas/tela_disciplina_estudante.dart';
import 'package:projecto_edumap/apresentacao/telas/tela_biblioteca.dart';
import 'package:projecto_edumap/apresentacao/telas/tela_perfil.dart';

class TelaInicialEstudante extends StatefulWidget {
  const TelaInicialEstudante({super.key});

  @override
  State<TelaInicialEstudante> createState() => _TelaInicialEstudanteState();
}

class _TelaInicialEstudanteState extends State<TelaInicialEstudante> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeEstudanteTab(),
      const TelaBiblioteca(),
      const TelaPerfil(),
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

class HomeEstudanteTab extends StatefulWidget {
  const HomeEstudanteTab({super.key});

  @override
  State<HomeEstudanteTab> createState() => _HomeEstudanteTabState();
}

class _HomeEstudanteTabState extends State<HomeEstudanteTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final List<String> disciplinas = const [
    'Álgebra Linear',
    'Matemática Discreta',
    'Programação I',
    'Electrónica Tembe',
    'PRDM'
  ];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final primaryColor = const Color(0xFF1565C0);

    final filteredDisciplinas = disciplinas
        .where((d) => d.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('EduMap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(primaryColor, uid),
          _buildSearchBar(primaryColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Disciplinas disponíveis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${disciplinas.length} disciplinas', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                ...filteredDisciplinas.map((d) => _buildDisciplinaCard(context, d, primaryColor)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color color, String? uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        String nome = "Estudante";
        if (snapshot.hasData && snapshot.data!.exists) {
          nome = (snapshot.data!.data() as Map<String, dynamic>)['name'] ?? "Estudante";
        }
        return Container(
          width: double.infinity,
          color: color,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bem-vindo, $nome', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              Text('Bons estudos!', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Pesquisar disciplina...',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: primaryColor),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDisciplinaCard(BuildContext context, String nome, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaDisciplinaEstudante(disciplina: nome))),
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
            return Text('$count materiais disponíveis', style: const TextStyle(fontSize: 12));
          },
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}
