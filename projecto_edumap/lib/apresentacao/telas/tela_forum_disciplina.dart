import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaForumDisciplina extends StatefulWidget {
  final String disciplina;
  const TelaForumDisciplina({super.key, required this.disciplina});

  @override
  State<TelaForumDisciplina> createState() => _TelaForumDisciplinaState();
}

class _TelaForumDisciplinaState extends State<TelaForumDisciplina> {
  final _perguntaController = TextEditingController();
  final Color _primaryColor = const Color(0xFF1565C0);
  bool _enviando = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<String> _getNome() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
    return doc.data()?['name'] ?? 'Utilizador';
  }

  Future<void> _enviarPergunta() async {
    final texto = _perguntaController.text.trim();
    if (texto.isEmpty || _uid == null) return;

    setState(() => _enviando = true);
    final nome = await _getNome();

    await FirebaseFirestore.instance.collection('duvidas').add({
      'disciplina': widget.disciplina,
      'pergunta':   texto,
      'userId':     _uid,
      'userName':   nome,
      'createdAt':  FieldValue.serverTimestamp(),
    });

    _perguntaController.clear();
    setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Fórum — ${widget.disciplina}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Campo nova pergunta
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _perguntaController,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Escreva a sua dúvida...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _enviando
                    ? const CircularProgressIndicator()
                    : IconButton(
                  icon: Icon(Icons.send, color: _primaryColor),
                  onPressed: _enviarPergunta,
                ),
              ],
            ),
          ),

          // Lista de dúvidas
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('duvidas')
                  .where('disciplina', isEqualTo: widget.disciplina)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final duvidas = snapshot.data!.docs;

                if (duvidas.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.question_answer_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Nenhuma dúvida ainda.\nSeja o primeiro a perguntar!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: duvidas.length,
                  itemBuilder: (context, i) =>
                      _buildDuvidaCard(duvidas[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuvidaCard(DocumentSnapshot doc) {
    final data     = doc.data() as Map<String, dynamic>;
    final duvidaId = doc.id;
    final isOwner  = data['userId'] == _uid;
    final ts       = data['createdAt'] as Timestamp?;
    final dataStr  = ts != null
        ? '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _primaryColor,
                  child: Text(
                    (data['userName'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['userName'] ?? 'Utilizador',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(dataStr,
                          style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () => FirebaseFirestore.instance
                        .collection('duvidas')
                        .doc(duvidaId)
                        .delete(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(data['pergunta'] ?? '', style: const TextStyle(fontSize: 14)),
            const Divider(height: 20),
            _buildRespostas(duvidaId),
            _buildCampoResposta(duvidaId),
          ],
        ),
      ),
    );
  }

  Widget _buildRespostas(String duvidaId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('duvidas')
          .doc(duvidaId)
          .collection('respostas')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final respostas = snapshot.data?.docs ?? [];

        if (respostas.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Sem respostas ainda.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          );
        }

        return Column(
          children: respostas.map((r) {
            final data    = r.data() as Map<String, dynamic>;
            final isOwner = data['userId'] == _uid;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.green,
                    child: Text((data['userName'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['userName'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(data['resposta'] ?? '',
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  if (isOwner)
                    GestureDetector(
                      onTap: () => FirebaseFirestore.instance
                          .collection('duvidas')
                          .doc(duvidaId)
                          .collection('respostas')
                          .doc(r.id)
                          .delete(),
                      child: const Icon(Icons.close, size: 16, color: Colors.red),
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCampoResposta(String duvidaId) {
    final controller = TextEditingController();
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Responder...',
              hintStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              isDense: true,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.reply, color: _primaryColor),
          onPressed: () async {
            final texto = controller.text.trim();
            if (texto.isEmpty || _uid == null) return;
            final nome = await _getNome();
            await FirebaseFirestore.instance
                .collection('duvidas')
                .doc(duvidaId)
                .collection('respostas')
                .add({
              'resposta':  texto,
              'userId':    _uid,
              'userName':  nome,
              'createdAt': FieldValue.serverTimestamp(),
            });
            controller.clear();
          },
        ),
      ],
    );
  }
}