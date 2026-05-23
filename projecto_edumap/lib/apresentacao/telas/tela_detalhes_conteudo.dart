import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../dados/models/conteudo_modelo.dart';
import '../provedores/auth_provedor.dart';

class TelaDetalhesConteudo extends StatefulWidget {
  final ConteudoModelo conteudo;
  const TelaDetalhesConteudo({super.key, required this.conteudo});

  @override
  State<TelaDetalhesConteudo> createState() => _TelaDetalhesConteudoState();
}

class _TelaDetalhesConteudoState extends State<TelaDetalhesConteudo> {
  bool _estaBaixando = false;
  double _progresso = 0;

  final Color _primaryColor = const Color(0xFF1565C0);
  final Color _chipBg = const Color(0xFFE3F2FD);

  Future<void> _baixarMaterial() async {
    final conexao = await Connectivity().checkConnectivity();
    if (conexao == ConnectivityResult.none) {
      _mostrarMensagem("Sem internet para download", erro: true);
      return;
    }

    setState(() => _estaBaixando = true);
    final auth = Provider.of<AuthProvedor>(context, listen: false);

    try {
      final diretorio = await getApplicationDocumentsDirectory();
      final nomeArquivo = "${widget.conteudo.id}.${widget.conteudo.tipo}";
      final caminhoLocal = "${diretorio.path}/$nomeArquivo";
      
      final request = await HttpClient().getUrl(Uri.parse(widget.conteudo.urlArquivo));
      final response = await request.close();
      final arquivo = File(caminhoLocal);
      
      int baixado = 0;
      int total = response.contentLength;
      
      final sink = arquivo.openWrite();
      await response.forEach((chunk) {
        sink.add(chunk);
        baixado += chunk.length;
        if (total > 0) {
          setState(() => _progresso = baixado / total);
        }
      });
      await sink.close();

      // Regista download no Firestore
      await FirebaseFirestore.instance.collection('downloads').add({
        'userId': auth.usuarioAtual?.uid,
        'contentId': widget.conteudo.id,
        'localPath': caminhoLocal,
        'status': 'completed',
        'downloadedAt': FieldValue.serverTimestamp(),
      });

      // Actualiza progresso do utilizador
      await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.usuarioAtual?.uid)
          .collection('progress')
          .doc(widget.conteudo.id)
          .set({
        'completed': true,
        'lastSeenAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _mostrarMensagem("Download concluído!", sucesso: true);
    } catch (e) {
      _mostrarMensagem("Erro ao baixar: $e", erro: true);
    } finally {
      if (mounted) {
        setState(() {
          _estaBaixando = false;
          _progresso = 0;
        });
      }
    }
  }

  void _mostrarMensagem(String msg, {bool erro = false, bool sucesso = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erro ? Colors.red : (sucesso ? Colors.green : null),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text('Detalhes', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubjectChip(),
                  const SizedBox(height: 12),
                  Text(widget.conteudo.titulo, 
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(widget.conteudo.descricao, 
                    style: TextStyle(color: Colors.grey[700], height: 1.5, fontSize: 15)),
                  const SizedBox(height: 24),
                  _buildFileCard(),
                  const SizedBox(height: 32),
                  _buildDownloadButton(),
                  const SizedBox(height: 32),
                  _buildInfoSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[50],
      child: Center(
        child: Icon(_getIconForType(), size: 80, color: _primaryColor.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildSubjectChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: _chipBg, borderRadius: BorderRadius.circular(20)),
      child: Text(widget.conteudo.disciplina.toUpperCase(), 
          style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildFileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(_getIconForType(), color: _primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.conteudo.titulo, maxLines: 1, overflow: TextOverflow.ellipsis, 
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(widget.conteudo.tipo.toUpperCase(), 
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _estaBaixando ? null : _baixarMaterial,
        icon: _estaBaixando ? const SizedBox.shrink() : const Icon(Icons.file_download, color: Colors.white),
        label: _estaBaixando 
          ? SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(value: _progresso > 0 ? _progresso : null, color: Colors.white, strokeWidth: 3),
            )
          : const Text("Download para Offline", 
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: _primaryColor.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Sobre este material", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Divider(height: 24),
        _infoRow("Categoria", widget.conteudo.disciplina),
        _infoRow("Tipo", widget.conteudo.tipo.toUpperCase()),
        _infoRow("Classe", widget.conteudo.classe),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  IconData _getIconForType() {
    switch (widget.conteudo.tipo.toLowerCase()) {
      case 'video': case 'mp4': return Icons.play_circle_filled;
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': case 'docx': return Icons.description;
      default: return Icons.insert_drive_file;
    }
  }
}
