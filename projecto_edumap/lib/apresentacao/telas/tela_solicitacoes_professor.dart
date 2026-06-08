import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TelaSolicitacoesProfessor extends StatelessWidget {
  const TelaSolicitacoesProfessor({super.key});

  final Color _primaryColor = const Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Solicitações de Professores',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('solicitacoes_professor')
            .stream(primaryKey: ['id'])
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!;

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Nenhuma solicitação.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final pendentes  = docs.where((d) => d['status'] == 'pendente').toList();
          final resolvidas = docs.where((d) => d['status'] != 'pendente').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pendentes.isNotEmpty) ...[
                _buildHeader('Pendentes', pendentes.length, Colors.orange),
                ...pendentes.map((d) => _buildCard(context, d)),
              ],
              if (resolvidas.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildHeader('Resolvidas', resolvidas.length, Colors.grey),
                ...resolvidas.map((d) => _buildCard(context, d)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(String titulo, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4, height: 20,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text('$titulo ($count)',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> data) {
    final status     = data['status'] as String? ?? 'pendente';
    final isPendente = status == 'pendente';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'aprovado': statusColor = Colors.green;  statusIcon = Icons.check_circle; break;
      case 'recusado': statusColor = Colors.red;    statusIcon = Icons.cancel; break;
      default:         statusColor = Colors.orange; statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _primaryColor,
                  child: Text(
                    (data['name'] ?? 'P')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(data['email'] ?? '',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                      if ((data['phone'] ?? '').toString().isNotEmpty)
                        Text(data['phone'].toString(),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                Icon(statusIcon, color: statusColor),
              ],
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => _verDocumento(data['documento_url']),
              icon: const Icon(Icons.description),
              label: const Text('Ver Documento'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: BorderSide(color: _primaryColor),
              ),
            ),

            if (data['motivo_recusa'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Motivo: ${data['motivo_recusa']}',
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            if (isPendente) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _aprovar(context, data),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Aprovar',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _recusar(context, data),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Recusar',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _verDocumento(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _aprovar(BuildContext context, Map<String, dynamic> data) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('solicitacoes_professor')
          .update({'status': 'aprovado'})
          .eq('id', data['id']);

      await supabase
          .from('users')
          .update({'role': 'professor'})
          .eq('id', data['user_id']);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Professor aprovado!'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _recusar(BuildContext context, Map<String, dynamic> data) async {
    final supabase = Supabase.instance.client;
    final motivoController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motivo da Recusa'),
        content: TextField(
          controller: motivoController,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'Explique o motivo...',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await supabase
                    .from('solicitacoes_professor')
                    .update({
                  'status': 'recusado',
                  'motivo_recusa': motivoController.text.trim(),
                })
                    .eq('id', data['id']);

                await supabase
                    .from('users')
                    .update({'role': 'estudante'})
                    .eq('id', data['user_id']);

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Solicitação recusada.'),
                      backgroundColor: Colors.red));
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Erro: $e'),
                      backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}