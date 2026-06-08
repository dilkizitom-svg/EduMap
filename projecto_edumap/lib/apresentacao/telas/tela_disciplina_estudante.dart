import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../dados/models/conteudo_modelo.dart';
import 'tela_detalhes_conteudo.dart';
import 'tela_visualizador_pdf.dart';
import 'tela_visualizador_video.dart';
import 'tela_visualizador_imagem.dart';
import 'tela_forum_disciplina.dart';

class TelaDisciplinaEstudante extends StatefulWidget {
  final String disciplina;
  const TelaDisciplinaEstudante({super.key, required this.disciplina});

  @override
  State<TelaDisciplinaEstudante> createState() =>
      _TelaDisciplinaEstudanteState();
}

class _TelaDisciplinaEstudanteState extends State<TelaDisciplinaEstudante> {
  final Color _primaryColor = const Color(0xFF1565C0);
  final _supabase = Supabase.instance.client;

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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // ✅ Downloads do Supabase
        future: _supabase
            .from('downloads')
            .select('content_id')
            .eq('user_id', uid ?? ''),
        builder: (context, downloadSnapshot) {
          final downloadedIds = (downloadSnapshot.data ?? [])
              .map((d) => d['content_id'].toString())
              .toSet();

          // ✅ Materiais do Supabase
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase
                .from('materiais')
                .stream(primaryKey: ['id'])
                .eq('disciplina', widget.disciplina)
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final materiais = snapshot.data!
                  .map((e) => ConteudoModelo.fromSupabase(e))
                  .toList();

              if (materiais.isEmpty) {
                return const Center(
                  child: Text('Nenhum material disponível nesta disciplina.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: materiais.length,
                itemBuilder: (context, index) {
                  final conteudo = materiais[index];
                  final isDownloaded =
                  downloadedIds.contains(conteudo.id.toString());

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TelaDetalhesConteudo(conteudo: conteudo),
                        ),
                      ),
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_getIconForType(conteudo.tipo),
                            color: _primaryColor),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(conteudo.titulo,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          if (isDownloaded)
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                        ],
                      ),
                      subtitle: Text(conteudo.descricao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12)),
                      trailing: isDownloaded
                          ? IconButton(
                        icon: Icon(Icons.play_circle_outline,
                            color: _primaryColor),
                        onPressed: () => _abrirVisualizador(conteudo),
                      )
                          : IconButton(
                        icon: Icon(Icons.download, color: _primaryColor),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TelaDetalhesConteudo(conteudo: conteudo),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    if (tipo.contains('pdf')) return Icons.picture_as_pdf;
    if (tipo.contains('video')) return Icons.videocam;
    if (tipo.contains('imagem')) return Icons.image;
    return Icons.insert_drive_file;
  }

  Future<void> _abrirVisualizador(ConteudoModelo conteudo) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/${conteudo.id}.${conteudo.tipo}';

    if (await File(filePath).exists()) {
      if (!mounted) return;
      if (conteudo.tipo.contains('pdf')) {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => TelaVisualizadorPdf(
                path: filePath, titulo: conteudo.titulo)));
      } else if (conteudo.tipo.contains('video')) {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => TelaVisualizadorVideo(
                path: filePath, titulo: conteudo.titulo)));
      } else if (conteudo.tipo.contains('imagem')) {
        Navigator.push(context, MaterialPageRoute(
            builder: (_) => TelaVisualizadorImagem(
                path: filePath, titulo: conteudo.titulo)));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ficheiro não encontrado localmente.'),
            backgroundColor: Colors.orange));
      }
    }
  }
}