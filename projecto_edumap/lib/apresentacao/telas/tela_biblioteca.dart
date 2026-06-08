import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../dados/models/conteudo_modelo.dart';
import 'tela_detalhes_conteudo.dart';
import 'tela_visualizador_pdf.dart';
import 'tela_visualizador_video.dart';
import 'tela_visualizador_imagem.dart';

class TelaBiblioteca extends StatefulWidget {
  const TelaBiblioteca({super.key});

  @override
  State<TelaBiblioteca> createState() => _TelaBibliotecaState();
}

class _TelaBibliotecaState extends State<TelaBiblioteca> {
  String _filtroTipo = 'Todos';
  final Color _primaryColor = const Color(0xFF1565C0);
  final Color _chipBg       = const Color(0xFFE3F2FD);
  final _supabase = Supabase.instance.client;
  Key _refreshKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Minha Biblioteca',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() => _refreshKey = UniqueKey()),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              key: _refreshKey,
              future: _supabase
                  .from('downloads')
                  .select()
                  .eq('user_id', uid ?? '')
                  .order('downloaded_at', ascending: false),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) return _buildOfflineView();

                final downloads = snapshot.data ?? [];
                if (downloads.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: downloads.length,
                  itemBuilder: (context, index) {
                    final download   = downloads[index];
                    final contentId  = download['content_id'].toString();
                    final localPath  = download['local_path'] ?? '';
                    final downloadId = download['id'].toString();

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _supabase
                          .from('materiais')
                          .select()
                          .eq('id', contentId),
                      builder: (context, contentSnapshot) {
                        final fileExists = File(localPath).existsSync();

                        if (!contentSnapshot.hasData ||
                            contentSnapshot.data!.isEmpty) {
                          if (fileExists) {
                            return _buildBasicOfflineCard(localPath, downloadId);
                          }
                          return const SizedBox.shrink();
                        }

                        final conteudo = ConteudoModelo.fromSupabase(
                            contentSnapshot.data!.first);

                        if (_filtroTipo != 'Todos' &&
                            !conteudo.tipo
                                .toLowerCase()
                                .contains(_filtroTipo.toLowerCase())) {
                          return const SizedBox.shrink();
                        }

                        return _buildLibraryCard(conteudo, localPath, downloadId);
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
          _filterChip('pdf'),
          _filterChip('video'),
          _filterChip('imagem'),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _filtroTipo == label;
    return ChoiceChip(
      label: Text(label.toUpperCase()),
      selected: isSelected,
      onSelected: (_) => setState(() => _filtroTipo = label),
      selectedColor: _primaryColor,
      labelStyle: TextStyle(
          color: isSelected ? Colors.white : _primaryColor,
          fontWeight: FontWeight.bold),
    );
  }

  Widget _buildLibraryCard(
      ConteudoModelo conteudo, String localPath, String downloadId) {
    final fileExists = File(localPath).existsSync();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          if (fileExists) {
            _abrirVisualizador(conteudo, localPath);
          } else {
            Navigator.push(context, MaterialPageRoute(
                builder: (_) => TelaDetalhesConteudo(conteudo: conteudo)));
          }
        },
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: _chipBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(_getIconForType(conteudo.tipo), color: _primaryColor),
        ),
        title: Text(conteudo.titulo,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          fileExists ? 'Disponível offline' : 'Ficheiro em falta',
          style: TextStyle(
              fontSize: 12, color: fileExists ? Colors.green : Colors.red),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _confirmarExclusao(downloadId, localPath),
        ),
      ),
    );
  }

  Widget _buildBasicOfflineCard(String path, String downloadId) {
    final fileName = path.split('/').last;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.offline_pin, color: Colors.green),
        title: Text(fileName),
        subtitle: const Text('Disponível offline'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _confirmarExclusao(downloadId, path),
        ),
      ),
    );
  }

  void _abrirVisualizador(ConteudoModelo conteudo, String path) {
    final tipo = conteudo.tipo.toLowerCase();
    if (tipo.contains('pdf')) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => TelaVisualizadorPdf(path: path, titulo: conteudo.titulo)));
    } else if (tipo.contains('video')) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => TelaVisualizadorVideo(path: path, titulo: conteudo.titulo)));
    } else if (tipo.contains('imagem') || tipo.contains('jpg') || tipo.contains('png')) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => TelaVisualizadorImagem(path: path, titulo: conteudo.titulo)));
    }
  }

  Widget _buildOfflineView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Modo Offline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Text(
              'Não foi possível ligar ao servidor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => setState(() => _refreshKey = UniqueKey()),
            child: const Text('Tentar Sincronizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('Nenhum material descarregado.'));
  }

  IconData _getIconForType(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf;
    if (t.contains('video')) return Icons.videocam;
    if (t.contains('imagem')) return Icons.image;
    return Icons.insert_drive_file;
  }

  void _confirmarExclusao(String downloadId, String path) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Download?'),
        content: const Text('O ficheiro será apagado permanentemente do dispositivo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final file = File(path);
              if (await file.exists()) await file.delete();
              try {
                await _supabase.from('downloads').delete().eq('id', downloadId);
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() => _refreshKey = UniqueKey());
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}