import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../dados/models/conteudo_modelo.dart';
import 'tela_publicar_conteudo.dart';

class TelaDisciplinaProfessor extends StatelessWidget {
  final String disciplina;
  final bool abrirUpload;

  const TelaDisciplinaProfessor({
    super.key,
    required this.disciplina,
    this.abrirUpload = false,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final primaryColor = const Color(0xFF1565C0);

    // Se abrirUpload for true, navega automaticamente (após o build)
    if (abrirUpload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TelaPublicarConteudo(disciplinaPreSelecionada: disciplina),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(disciplina, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.upload, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TelaPublicarConteudo(disciplinaPreSelecionada: disciplina),
            ),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('content')
            .where('subject', isEqualTo: disciplina)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context, uid);
          }

          final materiais = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materiais.length,
            itemBuilder: (context, index) {
              final doc = materiais[index];
              final data = doc.data() as Map<String, dynamic>;
              final conteudo = ConteudoModelo.fromFirestore(doc);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  leading: Icon(_getIconForType(conteudo.tipo), color: primaryColor),
                  title: Text(conteudo.titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(conteudo.descricao, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmarExclusao(context, doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String? uid) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Nenhum material nesta disciplina.\nToque em + para adicionar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _adicionarExemplos(context, uid),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
              child: const Text('Adicionar Material de Exemplo', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf;
    if (t.contains('video') || t.contains('mp4')) return Icons.videocam;
    return Icons.description;
  }

  void _confirmarExclusao(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Material?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('content').doc(docId).delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Material eliminado'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _adicionarExemplos(BuildContext context, String? uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final collection = FirebaseFirestore.instance.collection('content');

    final ex1 = collection.doc();
    batch.set(ex1, {
      'title': 'Aula 1 - Introdução',
      'subject': disciplina,
      'type': 'pdf',
      'classYear': '1º Ano',
      'description': 'Material introdutório',
      'fileUrl': '',
      'authorId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final ex2 = collection.doc();
    batch.set(ex2, {
      'title': 'Exercícios Resolvidos',
      'subject': disciplina,
      'type': 'pdf',
      'classYear': '1º Ano',
      'description': 'Exercícios práticos',
      'fileUrl': '',
      'authorId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Materiais exemplares adicionados'), backgroundColor: Colors.green),
      );
    }
  }
}
