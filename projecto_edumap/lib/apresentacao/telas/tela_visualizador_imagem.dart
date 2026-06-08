import 'dart:io';
import 'package:flutter/material.dart';

class TelaVisualizadorImagem extends StatelessWidget {
  final String path;
  final String titulo;

  const TelaVisualizadorImagem({super.key, required this.path, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer( // Permite fazer zoom na imagem
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
