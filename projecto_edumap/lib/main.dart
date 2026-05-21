/// ARQUIVO PRINCIPAL
/// Ponto de entrada do aplicativo EduMap

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'apresentacao/provedores/auth_provedor.dart';
import 'apresentacao/telas/tela_login.dart';

void main() async {
  // Garante que os widgets estejam disponíveis antes de inicializar
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase com as configurações geradas
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Inicia o aplicativo
  runApp(const EduMapApp());
}

class EduMapApp extends StatelessWidget {
  const EduMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider de autenticação disponível para toda a aplicação
        ChangeNotifierProvider(create: (_) => AuthProvedor()),
      ],
      child: MaterialApp(
        title: 'EduMap',
        debugShowCheckedModeBanner: false, // Remove a faixa "Debug"
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const TelaLogin(), // Primeira tela
      ),
    );
  }
}