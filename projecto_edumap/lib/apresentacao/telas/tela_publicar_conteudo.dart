import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../provedores/auth_provedor.dart';

class TelaPublicarConteudo extends StatefulWidget {
  final String? disciplinaPreSelecionada;
  const TelaPublicarConteudo({super.key, this.disciplinaPreSelecionada});

  @override
  State<TelaPublicarConteudo> createState() => _TelaPublicarConteudoState();
}

class _TelaPublicarConteudoState extends State<TelaPublicarConteudo> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();

  String? _disciplinaSelecionada;
  String? _classeSelecionada;
  PlatformFile? _arquivoSelecionado;
  bool _estaPublicando = false;

  final List<String> _disciplinas = [
    'Matemática',
    'Física',
    'Português',
    'História',
    'Geografia',
    'Biologia',
    'Química',
    'Inglês',
    'Álgebra Linear',
    'Matemática Discreta',
    'Programação I',
    'Electrónica Digital',
    'PRDM',
  ];

  final List<String> _classes = [
    '7ª',
    '8ª',
    '9ª',
    '10ª',
    '11ª',
    '12ª',
    '1º Ano',
    '2º Ano',
    '3º Ano',
    '4º Ano',
  ];

  @override
  void initState() {
    super.initState();
    _disciplinaSelecionada = widget.disciplinaPreSelecionada;
  }

  final Color _primaryColor = const Color(0xFF1565C0);

  Future<void> _selecionarArquivo() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp4', 'mkv', 'jpg', 'jpeg', 'png'],
    );

    if (resultado != null) {
      setState(() => _arquivoSelecionado = resultado.files.first);
    }
  }

  Future<void> _publicarMaterial() async {
    if (!_formKey.currentState!.validate() || _arquivoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha todos os campos e selecione um arquivo'),
        ),
      );
      return;
    }

    setState(() => _estaPublicando = true);
    final auth = Provider.of<AuthProvedor>(context, listen: false);
    final uid = auth.usuarioAtual?.uid;

    if (uid == null) {
      if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text('Utilizador não autenticado. Faça login novamente.'),
           backgroundColor: Colors.red,
         ),
       );
       setState(() => _estaPublicando = false);
     }
     return;
   }

    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_arquivoSelecionado!.name}';
      final storageRef = FirebaseStorage.instance.ref().child(
        'content/$uid/$fileName',
      );

      UploadTask uploadTask;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        uploadTask = storageRef.putData(_arquivoSelecionado!.bytes!);
      } else {
        uploadTask = storageRef.putFile(File(_arquivoSelecionado!.path!));
      }

      final snapshot = await uploadTask;
      final fileUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('content').add({
        'title': _tituloController.text.trim(),
        'subject': _disciplinaSelecionada,
        'classYear': _classeSelecionada,
        'description': _descricaoController.text.trim(),
        'type': _arquivoSelecionado!.extension,
        'fileUrl': fileUrl,
        'authorId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material publicado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao publicar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _estaPublicando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Publicar Material',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _estaPublicando
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryColor),
                  const SizedBox(height: 16),
                  const Text('Enviando material...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField('Título do Material', _tituloController),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      'Disciplina',
                      _disciplinas,
                      _disciplinaSelecionada,
                      (val) => setState(() => _disciplinaSelecionada = val),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      'Classe',
                      _classes,
                      _classeSelecionada,
                      (val) => setState(() => _classeSelecionada = val),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Descrição',
                      _descricaoController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),

                    GestureDetector(
                      onTap: _selecionarArquivo,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.attach_file, color: _primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _arquivoSelecionado?.name ??
                                    'Selecionar Ficheiro (PDF, Vídeo, Imagem)',
                                style: TextStyle(
                                  color: _arquivoSelecionado == null
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed: _publicarMaterial,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Publicar Material',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      validator: (val) =>
          val == null || val.isEmpty ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selected,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Selecione uma opção' : null,
    );
  }
}
