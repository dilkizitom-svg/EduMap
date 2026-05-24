import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../dados/models/conteudo_modelo.dart';
import 'tela_detalhes_conteudo.dart';
import 'tela_visualizador_pdf.dart';
import 'tela_visualizador_video.dart';

class TelaDisciplinaEstudante extends StatefulWidget {
  final String disciplina;

  const TelaDisciplinaEstudante({super.key, required this.disciplina});

  @override
  State<TelaDisciplinaEstudante> createState() => _TelaDisciplinaEstudanteState();
}

class _TelaDisciplinaEstudanteState extends State<TelaDisciplinaEstudante> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1565C0);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.disciplina, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('downloads')
            .where('userId', isEqualTo: uid)
            .snapshots(),
        builder: (context, downloadSnapshot) {
          final downloadedContentIds = downloadSnapshot.hasData
              ? downloadSnapshot.data!.docs.map((doc) => doc['contentId'] as String).toSet()
              : <String>{};

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('content')
                .where('subject', isEqualTo: widget.disciplina)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final materiais = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: materiais.length,
                itemBuilder: (context, index) {
                  final doc = materiais[index];
                  final conteudo = ConteudoModelo.fromFirestore(doc);
                  final isDownloaded = downloadedContentIds.contains(conteudo.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TelaDetalhesConteudo(conteudo: conteudo)),
                      ),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_getIconForType(conteudo.tipo), color: primaryColor),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(conteudo.titulo,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          if (isDownloaded)
                            const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        ],
                      ),
                      subtitle: Text(conteudo.descricao,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDownloaded)
                            IconButton(
                              icon: Icon(Icons.play_circle_outline, color: primaryColor),
                              onPressed: () => _abrirVisualizador(context, conteudo),
                            )
                          else
                            IconButton(
                              icon: Icon(Icons.download, color: primaryColor),
                              onPressed: () => _fazerDownload(context, conteudo, uid),
                            ),
                        ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Nenhum material disponível nesta disciplina',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf;
    if (t.contains('video') || t.contains('mp4')) return Icons.videocam;
    if (t.contains('jpg') || t.contains('png') || t.contains('image')) return Icons.image;
    return Icons.insert_drive_file;
  }

  Future<void> _abrirVisualizador(BuildContext context, ConteudoModelo conteudo) async {
    final diretorio = await getApplicationDocumentsDirectory();
    final nomeArquivo = "${conteudo.id}.${conteudo.tipo}";
    final caminhoLocal = "${diretorio.path}/$nomeArquivo";

    if (!await File(caminhoLocal).exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ficheiro não encontrado localmente. Faça o download novamente.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (conteudo.tipo.toLowerCase().contains('pdf')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TelaVisualizadorPdf(path: caminhoLocal, titulo: conteudo.titulo)));
    } else if (conteudo.tipo.toLowerCase().contains('video') || conteudo.tipo.toLowerCase().contains('mp4')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TelaVisualizadorVideo(path: caminhoLocal, titulo: conteudo.titulo)));
    }
  }

  Future<void> _fazerDownload(BuildContext context, ConteudoModelo conteudo, String? uid) async {
    if (conteudo.urlArquivo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este material ainda não tem ficheiro'), backgroundColor: Colors.orange),
      );
      return;
    }

    final conexao = await Connectivity().checkConnectivity();
    if (conexao.contains(ConnectivityResult.none)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem ligação à internet'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final diretorio = await getApplicationDocumentsDirectory();
      final nomeArquivo = "${conteudo.id}.${conteudo.tipo}";
      final caminhoLocal = "${diretorio.path}/$nomeArquivo";

      final request = await HttpClient().getUrl(Uri.parse(conteudo.urlArquivo));
      final response = await request.close();
      final bytes = await response.expand((element) => element).toList();
      final file = File(caminhoLocal);
      await file.writeAsBytes(bytes);

      await FirebaseFirestore.instance.collection('downloads').add({
        'userId': uid,
        'contentId': conteudo.id,
        'localPath': caminhoLocal,
        'status': 'completed',
        'downloadedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download concluído!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no download: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
