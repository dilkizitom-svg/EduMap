/// ARQUIVO PRINCIPAL
/// Ponto de entrada do aplicativo EduMap

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'apresentacao/provedores/auth_provedor.dart';
import 'apresentacao/widget_roteador.dart';

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
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF1565C0),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const WidgetRoteador(), // O roteador decide qual tela mostrar
      ),
    );
  }
}