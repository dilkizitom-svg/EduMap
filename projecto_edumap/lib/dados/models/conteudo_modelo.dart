import 'package:cloud_firestore/cloud_firestore.dart';

class ConteudoModelo {
  final String id;
  final String titulo;
  final String disciplina;
  final String classe;
  final String descricao;
  final String tipo;
  final String urlArquivo;
  final String autorId;
  final DateTime? criadoEm;

  ConteudoModelo({
    required this.id,
    required this.titulo,
    required this.disciplina,
    required this.classe,
    required this.descricao,
    required this.tipo,
    required this.urlArquivo,
    required this.autorId,
    this.criadoEm,
  });

  factory ConteudoModelo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConteudoModelo(
      id: doc.id,
      titulo: data['title'] ?? '',
      disciplina: data['subject'] ?? '',
      classe: data['classYear'] ?? '',
      descricao: data['description'] ?? '',
      tipo: data['type'] ?? '',
      urlArquivo: data['fileUrl'] ?? '',
      autorId: data['authorId'] ?? '',
      criadoEm: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': titulo,
      'subject': disciplina,
      'classYear': classe,
      'description': descricao,
      'type': tipo,
      'fileUrl': urlArquivo,
      'authorId': autorId,
      'createdAt': criadoEm != null ? Timestamp.fromDate(criadoEm!) : FieldValue.serverTimestamp(),
    };
  }
}
