import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  int _currentIndex = 0;

  final Color primaryColor = const Color(0xFF1565C0);
  final Color accentColor = const Color(0xFF1976D2);
  final Color backgroundColor = const Color(0xFFF5F5F5);
  final Color chipBg = const Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvedor>(context);
    final isProfessor = auth.usuarioAtual?.papel == 'professor';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text('EduMap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('content').snapshots(),
              builder: (context, contentSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('downloads')
                      .where('userId', isEqualTo: uid)
                      .where('status', isEqualTo: 'completed')
                      .snapshots(),
                  builder: (context, downloadSnapshot) {
                    final materiaisCount = contentSnapshot.hasData ? contentSnapshot.data!.docs.length : 0;
                    final salvosCount = downloadSnapshot.hasData ? downloadSnapshot.data!.docs.length : 0;
                    
                    List<ConteudoModelo> allMaterials = [];
                    if (contentSnapshot.hasData) {
                      allMaterials = contentSnapshot.data!.docs
                          .map((doc) => ConteudoModelo.fromFirestore(doc))
                          .toList();
                    }

                    final filteredMaterials = allMaterials.where((m) {
                      final query = _searchQuery.toLowerCase();
                      return m.titulo.toLowerCase().contains(query) || 
                             m.disciplina.toLowerCase().contains(query);
                    }).toList();

                    return ListView(
                      children: [
                        _buildCounters(materiaisCount, salvosCount, 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Todos os materiais', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('${filteredMaterials.length} itens', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        if (filteredMaterials.isEmpty && contentSnapshot.connectionState != ConnectionState.waiting)
                          _buildEmptyState()
                        else
                          ...filteredMaterials.map((m) => _buildMaterialCard(m)).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == (isProfessor ? 3 : 2)) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaPerfil()));
          } else if (isProfessor && index == 2) {
             Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaPublicarConteudo()));
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'Biblioteca'),
          if (isProfessor)
            const BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: 'Upload'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Pesquisar materiais ou disciplina...',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _counterItem(Icons.book, materiais.toString(), 'Materiais'),
            const VerticalDivider(thickness: 1, color: Color(0xFFEEEEEE)),
            _counterItem(Icons.bookmark, salvos.toString(), 'Salvos'),
            const VerticalDivider(thickness: 1, color: Color(0xFFEEEEEE)),
            _counterItem(Icons.history, recentes.toString(), 'Recentes'),
          ],
        ),
      ),
    );
  }

  Widget _counterItem(IconData icon, String count, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(height: 4),
          Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(ConteudoModelo m) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaDetalhesConteudo(conteudo: m))),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getIconForType(m.tipo), color: primaryColor, size: 20),
        ),
        title: Text(m.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(m.descricao, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(m.disciplina, style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Nenhum material encontrado', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf;
    if (t.contains('video') || t.contains('mp4')) return Icons.videocam;
    if (t.contains('jpg') || t.contains('png') || t.contains('image')) return Icons.image;
    return Icons.description;
  }
}
