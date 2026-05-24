import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class TelaVisualizadorPdf extends StatelessWidget {
  final String path;
  final String titulo;

  const TelaVisualizadorPdf({super.key, required this.path, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo, style: const TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF1565C0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PDFView(
        filePath: path,
        autoSpacing: true,
        enableSwipe: true,
        pageSnap: true,
        swipeHorizontal: false,
        onError: (error) {
          debugPrint(error.toString());
        },
      ),
    );
  }
}
