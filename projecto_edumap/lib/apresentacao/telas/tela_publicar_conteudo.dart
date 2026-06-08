import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaPublicarConteudo extends StatefulWidget {
  final String? disciplinaPreSelecionada;
  const TelaPublicarConteudo({super.key, this.disciplinaPreSelecionada});

  @override
  State<TelaPublicarConteudo> createState() => _TelaPublicarConteudoState();
}

class _TelaPublicarConteudoState extends State<TelaPublicarConteudo> {
  final _formKey       = GlobalKey<FormState>();
  final _tituloController    = TextEditingController();
  final _descricaoController = TextEditingController();

  String? _disciplinaSelecionada;
  String? _classeSelecionada;
  PlatformFile? _arquivoSelecionado;
  bool _estaPublicando = false;

  final List<String> _disciplinas = [
    'Matemática', 'Física', 'Português', 'História', 'Geografia',
    'Biologia', 'Química', 'Inglês', 'Ciências Naturais',
    'Matemática Discreta', 'Ciências Sociais', 'Filosofia', 'PRDM'
  ];

  final List<String> _classes = [
    '1ª', '2ª', '3ª', '4ª', '7ª', '8ª', '9ª', '10ª', '11ª', '12ª'
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
      withData: true,
    );
    if (resultado != null) {
      setState(() => _arquivoSelecionado = resultado.files.first);
    }
  }

  Future<void> _publicarMaterial() async {
    if (!_formKey.currentState!.validate() || _arquivoSelecionado == null) {
      _snack('Selecione um arquivo e preencha os campos', Colors.orange);
      return;
    }

    // ✅ UID do Firebase Auth
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack('Utilizador não autenticado.', Colors.red);
      return;
    }

    setState(() => _estaPublicando = true);

    try {
      final supabase = Supabase.instance.client;
      final file     = _arquivoSelecionado!;
      final extensao = file.extension?.toLowerCase() ?? 'file';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_'
          '${file.name.replaceAll(RegExp(r'[^\w\.]'), '_')}';
      final path     = 'materiais/$uid/$fileName';

      // ✅ 1. Upload ficheiro → Supabase Storage
      if (kIsWeb) {
        await supabase.storage.from('materiais').uploadBinary(path, file.bytes!);
      } else {
        await supabase.storage.from('materiais').upload(path, File(file.path!));
      }

      // ✅ 2. URL pública
      final fileUrl = supabase.storage.from('materiais').getPublicUrl(path);

      // ✅ 3. Tipo
      String tipo;
      if (['jpg', 'jpeg', 'png', 'webp'].contains(extensao))    tipo = 'imagem';
      else if (['mp4', 'mkv', 'mov', 'avi'].contains(extensao)) tipo = 'video';
      else if (extensao == 'pdf')                                tipo = 'pdf';
      else                                                        tipo = 'outro';

      // ✅ 4. Metadados → Supabase (tabela materiais)
      await supabase.from('materiais').insert({
        'titulo':      _tituloController.text.trim(),
        'descricao':   _descricaoController.text.trim(),
        'disciplina':  _disciplinaSelecionada,
        'classe':      _classeSelecionada,
        'tipo':        tipo,
        'url_arquivo': fileUrl,
        'user_id':     uid,
        'created_at':  DateTime.now().toIso8601String(),
      });

      if (mounted) {
        _snack('Material publicado com sucesso!', Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('ERRO: $e');
      _snack('Erro ao publicar: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _estaPublicando = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Publicar Material',
            style: TextStyle(color: Colors.white)),
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
            const Text('A publicar material...'),
            const Text('Não feche o aplicativo',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
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
              _buildDropdown('Disciplina', _disciplinas,
                  _disciplinaSelecionada,
                      (val) => setState(() => _disciplinaSelecionada = val)),
              const SizedBox(height: 16),
              _buildDropdown('Classe', _classes, _classeSelecionada,
                      (val) => setState(() => _classeSelecionada = val)),
              const SizedBox(height: 16),
              _buildTextField('Descrição', _descricaoController,
                  maxLines: 4),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _selecionarArquivo,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _arquivoSelecionado != null
                        ? const Color(0xFFE8F5E9)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _arquivoSelecionado != null
                          ? Colors.green
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _arquivoSelecionado != null
                            ? Icons.check_circle
                            : Icons.attach_file,
                        color: _arquivoSelecionado != null
                            ? Colors.green
                            : _primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _arquivoSelecionado?.name ??
                              'Selecionar Ficheiro (PDF, Vídeo, Imagem)',
                          style: TextStyle(
                            color: _arquivoSelecionado != null
                                ? Colors.green[700]
                                : Colors.grey,
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
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Publicar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (val) =>
      val == null || val.isEmpty ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? selected,
      Function(String?) onChanged) {
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