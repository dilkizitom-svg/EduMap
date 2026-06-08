import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'apresentacao/provedores/auth_provedor.dart';
import 'apresentacao/widget_roteador.dart';

void main() async {
  // ← OBRIGATÓRIO antes de qualquer coisa
  WidgetsFlutterBinding.ensureInitialized();

  // ← Firebase primeiro
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ← Supabase a seguir
  await Supabase.initialize(
    url: 'https://jqbqpmfdnptttttojnqs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxYnFwbWZkbnB0dHR0dG9qbnFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAxNDExNjcsImV4cCI6MjA5NTcxNzE2N30.2QFcSMHYFW39ukNxus9sKEC-GFSjVpX1KVHZxRBiXx0',
  );

  runApp(const EduMapApp());
}

class EduMapApp extends StatelessWidget {
  const EduMapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvedor()),
      ],
      child: MaterialApp(
        title: 'EduMap',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF1565C0),
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1565C0)),
          useMaterial3: true,
        ),
        home: const WidgetRoteador(),
      ),
    );
  }
}