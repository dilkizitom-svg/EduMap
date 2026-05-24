import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../dados/models/conteudo_modelo.dart';
import 'tela_detalhes_conteudo.dart';
import 'tela_visualizador_pdf.dart';
import 'tela_visualizador_video.dart';

class TelaBiblioteca extends StatefulWidget {
  const TelaBiblioteca({super.key});

  @override
  State<TelaBiblioteca> createState() => _TelaBibliotecaState();
}

class _TelaBibliotecaState extends State<TelaBiblioteca> {
  String _filtroTipo = 'Todos';
  final Color _primaryColor = const Color(0xFF1565C0);
  final Color _chipBg = const Color(0xFFE3F2FD);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Minha Biblioteca', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('downloads')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final downloads = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: downloads.length,
                  itemBuilder: (context, index) {
                    final data = downloads[index].data() as Map<String, dynamic>;
                    final contentId = data['contentId'];
                    final localPath = data['localPath'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('content').doc(contentId).get(),
                      builder: (context, contentSnapshot) {
                        if (!contentSnapshot.hasData || !contentSnapshot.data!.exists) return const SizedBox.shrink();
                        
                        final conteudo = ConteudoModelo.fromFirestore(contentSnapshot.data!);
                        
                        // Filtragem por tipo
                        if (_filtroTipo != 'Todos' && !conteudo.tipo.toLowerCase().contains(_filtroTipo.toLowerCase())) {
                          return const SizedBox.shrink();
                        }

                        return _buildLibraryCard(conteudo, localPath, downloads[index].id);
                      },
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

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _filterChip('Todos'),
          _filterChip('PDF'),
          _filterChip('Video'),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _filtroTipo == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _filtroTipo = label),
      selectedColor: _primaryColor,
      labelStyle: TextStyle(color: isSelected ? Colors.white : _primaryColor),
      backgroundColor: _chipBg,
    );
  }

  Widget _buildLibraryCard(ConteudoModelo conteudo, String localPath, String downloadDocId) {
    final fileExists = File(localPath).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        onTap: () {
          if (fileExists) {
             _abrirVisualizador(conteudo, localPath);
          } else {
             Navigator.push(context, MaterialPageRoute(builder: (_) => TelaDetalhesConteudo(conteudo: conteudo)));
          }
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: _chipBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(_getIconForType(conteudo.tipo), color: _primaryColor),
        ),
        title: Text(conteudo.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Row(
          children: [
            Icon(fileExists ? Icons.offline_pin : Icons.error_outline, 
                 size: 14, color: fileExists ? Colors.green : Colors.red),
            const SizedBox(width: 4),
            Text(fileExists ? 'Disponível offline' : 'Ficheiro não encontrado', 
                 style: TextStyle(fontSize: 12, color: fileExists ? Colors.green : Colors.red)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmarExclusao(downloadDocId, localPath),
        ),
      ),
    );
  }

  void _abrirVisualizador(ConteudoModelo conteudo, String path) {
    if (conteudo.tipo.toLowerCase().contains('pdf')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TelaVisualizadorPdf(path: path, titulo: conteudo.titulo)));
    } else if (conteudo.tipo.toLowerCase().contains('video') || conteudo.tipo.toLowerCase().contains('mp4')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TelaVisualizadorVideo(path: path, titulo: conteudo.titulo)));
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Sua biblioteca está vazia', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf;
    if (t.contains('video') || t.contains('mp4')) return Icons.videocam;
    return Icons.description;
  }

  void _confirmarExclusao(String docId, String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Download?'),
        content: const Text('O ficheiro será apagado do seu dispositivo para libertar espaço.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              final file = File(path);
              if (await file.exists()) await file.delete();
              await FirebaseFirestore.instance.collection('downloads').doc(docId).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
