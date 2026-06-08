import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dados/models/conteudo_modelo.dart';
import 'tela_publicar_conteudo.dart';
import 'tela_forum_disciplina.dart';

class TelaDisciplinaProfessor extends StatefulWidget {
  final String disciplina;
  final bool abrirUpload;

  const TelaDisciplinaProfessor({
    super.key,
    required this.disciplina,
    this.abrirUpload = false,
  });

  @override
  State<TelaDisciplinaProfessor> createState() =>
      _TelaDisciplinaProfessorState();
}

class _TelaDisciplinaProfessorState extends State<TelaDisciplinaProfessor> {
  final _supabase = Supabase.instance.client;
  final Color _primaryColor = const Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    if (widget.abrirUpload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TelaPublicarConteudo(
                disciplinaPreSelecionada: widget.disciplina),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ UID do Firebase Auth
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.disciplina,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum, color: Colors.white),
            tooltip: 'Fórum',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TelaForumDisciplina(disciplina: widget.disciplina),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        child: const Icon(Icons.upload, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TelaPublicarConteudo(
                disciplinaPreSelecionada: widget.disciplina),
          ),
        ),
      ),
      // ✅ Materiais do Supabase
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('materiais')
            .stream(primaryKey: ['id'])
            .eq('user_id', uid ?? '')
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final todos = snapshot.data!
              .where((m) => m['disciplina'] == widget.disciplina)
              .toList();

          final materiais =
          todos.map((e) => ConteudoModelo.fromSupabase(e)).toList();

          if (materiais.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Nenhum material publicado nesta disciplina.\nToque em + para adicionar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: materiais.length,
            itemBuilder: (context, index) {
              final conteudo = materiais[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  leading:
                  Icon(_getIconForType(conteudo.tipo), color: _primaryColor),
                  title: Text(conteudo.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(conteudo.descricao,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _confirmarExclusao(context, conteudo.id.toString()),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf;
    if (t.contains('video')) return Icons.videocam;
    if (t.contains('imagem')) return Icons.image;
    return Icons.description;
  }

  void _confirmarExclusao(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Material?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await _supabase.from('materiais').delete().eq('id', id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Material eliminado'),
                    backgroundColor: Colors.red));
              }
            },
            child:
            const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}