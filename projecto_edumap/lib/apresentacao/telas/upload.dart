import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _imagem;
  bool _uploading = false;

  final Color _primaryColor = const Color(0xFF1565C0);

  // Selecionar imagem da galeria
  Future<void> pickImage() async {
    final imagePicker = ImagePicker();
    final XFile? image = await imagePicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _imagem = File(image.path));
    }
  }

  // Upload para Supabase Storage
  Future<void> uploadImage() async {
    if (_imagem == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Utilizador não autenticado', Colors.red);
      return;
    }

    setState(() => _uploading = true);

    try {
      final supabase   = Supabase.instance.client;
      final fileName   = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path       = 'imagens/${user.uid}/$fileName';

      // 1. Upload para Supabase Storage
      await supabase.storage
          .from('imagens')
          .upload(path, _imagem!);

      // 2. Obter URL pública
      final url = supabase.storage
          .from('imagens')
          .getPublicUrl(path);

      // 3. Guardar referência no Firestore
      await FirebaseFirestore.instance.collection('materiais').add({
        'titulo':     'Upload Manual',
        'tipo':       'imagem',
        'urlArquivo': url,
        'userId':     user.uid,
        'createdAt':  FieldValue.serverTimestamp(),
      });

      _snack('Imagem enviada com sucesso!', Colors.green);
      setState(() => _imagem = null);

    } catch (e) {
      _snack('Erro ao enviar: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload de Imagem',
            style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Preview da imagem
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _imagem != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_imagem!, fit: BoxFit.cover),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_outlined,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('Nenhuma imagem selecionada',
                        style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botão selecionar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _uploading ? null : pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Selecionar Imagem'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: BorderSide(color: _primaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Botão upload
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: (_imagem == null || _uploading) ? null : uploadImage,
                  icon: _uploading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Icon(Icons.upload, color: Colors.white),
                  label: Text(
                    _uploading ? 'A enviar...' : 'Fazer Upload',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              if (_uploading) ...[
                const SizedBox(height: 16),
                const Text('A enviar para o Supabase...',
                    style: TextStyle(color: Colors.grey)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}