import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../provedores/auth_provedor.dart';
import '../../dados/models/conteudo_modelo.dart';
import 'tela_detalhes_conteudo.dart';
import 'tela_publicar_conteudo.dart';
import 'tela_perfil.dart';

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  int _currentIndex  = 0;

  final Color primaryColor     = const Color(0xFF1565C0);
  final Color accentColor      = const Color(0xFF1976D2);
  final Color backgroundColor  = const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    final auth        = Provider.of<AuthProvedor>(context);
    final isProfessor = auth.usuarioAtual?.papel == 'professor';
    final supabase    = Supabase.instance.client;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text('EduMap',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            // ✅ Supabase stream em vez de Firestore
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('materiais')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Erro ao carregar dados: ${snapshot.error}'));
                }

                // ✅ fromSupabase em vez de fromFirestore
                final allMaterials = (snapshot.data ?? [])
                    .map((e) => ConteudoModelo.fromSupabase(e))
                    .toList();

                final filteredMaterials = allMaterials.where((m) {
                  final q = _searchQuery.toLowerCase();
                  return m.titulo.toLowerCase().contains(q) ||
                      m.disciplina.toLowerCase().contains(q);
                }).toList();

                return ListView(
                  children: [
                    _buildCounters(allMaterials.length, 0, 0),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Todos os materiais',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${filteredMaterials.length} itens',
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    if (filteredMaterials.isEmpty)
                      _buildEmptyState()
                    else
                      ...filteredMaterials.map((m) => _buildMaterialCard(m)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isProfessor
          ? FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.upload, color: Colors.white),
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TelaPublicarConteudo())),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 2) {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TelaPerfil()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_books), label: 'Biblioteca'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: const InputDecoration(
          hintText: 'Pesquisar materiais...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _buildCounters(int materiais, int salvos, int recentes) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _counter(Icons.book, materiais.toString(), 'Materiais'),
          _counter(Icons.bookmark, salvos.toString(), 'Salvos'),
          _counter(Icons.history, recentes.toString(), 'Recentes'),
        ],
      ),
    );
  }

  Widget _counter(IconData icon, String count, String label) {
    return Column(
      children: [
        Icon(icon, color: accentColor),
        Text(count,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMaterialCard(ConteudoModelo m) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => TelaDetalhesConteudo(conteudo: m))),
        leading: Icon(_getIconForType(m.tipo), color: primaryColor),
        title: Text(m.titulo,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(m.descricao,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(m.disciplina,
            style: TextStyle(color: primaryColor)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(
        child: Text('Nenhum material encontrado',
            style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('pdf'))    return Icons.picture_as_pdf;
    if (t.contains('video'))  return Icons.videocam;
    if (t.contains('imagem')) return Icons.image;
    return Icons.description;
  }
}