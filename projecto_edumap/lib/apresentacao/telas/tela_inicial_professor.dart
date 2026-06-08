import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tela_disciplina_professor.dart';
import 'tela_biblioteca.dart';
import 'tela_perfil.dart';
import 'tela_publicar_conteudo.dart';

class TelaInicialProfessor extends StatefulWidget {
  const TelaInicialProfessor({super.key});

  @override
  State<TelaInicialProfessor> createState() => _TelaInicialProfessorState();
}

class _TelaInicialProfessorState extends State<TelaInicialProfessor> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeProfessorTab(),
      const TelaBiblioteca(),
      const TelaPerfil(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
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

  @override
  Widget build(BuildContext context) {
    final uid      = FirebaseAuth.instance.currentUser?.uid;
    final supabase = Supabase.instance.client;
    const primaryColor = Color(0xFF1565C0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('EduMap - Professor',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TelaPublicarConteudo())),
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Publicar Material',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Header com nome do professor
          FutureBuilder<List<Map<String, dynamic>>>(
            future: supabase.from('users').select('name').eq('id', uid ?? ''),
            builder: (context, snapshot) {
              final nome = snapshot.data?.isNotEmpty == true
                  ? snapshot.data![0]['name'] ?? 'Professor'
                  : 'Professor';
              return Container(
                width: double.infinity,
                color: primaryColor,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bem-vindo, $nome',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                    Text('Gerencie os seus materiais',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  ],
                ),
              );
            },
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.history, size: 20, color: Colors.grey),
                SizedBox(width: 8),
                Text('As Minhas Publicações',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          Expanded(
            child: uid == null
                ? const Center(child: Text('Não autenticado'))
                : StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('materiais')
                  .stream(primaryKey: ['id'])
                  .eq('user_id', uid)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final materiais = snapshot.data!;

                if (materiais.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Ainda não publicou nenhum material.',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // Agrupar por disciplina
                final Map<String, int> disciplinasCount = {};
                for (var m in materiais) {
                  final d = m['disciplina'] as String? ?? 'Sem Disciplina';
                  disciplinasCount[d] = (disciplinasCount[d] ?? 0) + 1;
                }

                final lista = disciplinasCount.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    final nome  = lista[index];
                    final count = disciplinasCount[nome]!;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => TelaDisciplinaProfessor(
                                    disciplina: nome))),
                        leading: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.menu_book,
                              color: primaryColor),
                        ),
                        title: Text(nome,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('$count materiais publicados',
                            style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}