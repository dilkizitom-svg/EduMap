import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provedores/auth_provedor.dart';
import 'tela_cadastro.dart';
import 'tela_inicial_estudante.dart';
import 'tela_inicial_professor.dart';
import 'tela_inicial_admin.dart';
import 'tela_aguardando_aprovacao.dart'; // Importado

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _mostrarSenha = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }
  
  void _redirecionar(BuildContext context, String? papel) {
    if (!mounted) return;
    
    Widget tela;
    switch (papel?.toLowerCase()) {
      case 'admin':
        tela = const TelaInicialAdmin();
        break;
      case 'professor':
        tela = const TelaInicialProfessor();
        break;
      case 'pendente': // ✅ Adicionado
        tela = const TelaAguardandoAprovacao();
        break;
      case 'estudante':
      case 'aluno':
      default:
        tela = const TelaInicialEstudante();
        break;
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => tela),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvedor = Provider.of<AuthProvedor>(context);
    
    // Auto-login se já houver um utilizador carregado
    if (authProvedor.usuarioAtual != null && !authProvedor.estaCarregando) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirecionar(context, authProvedor.usuarioAtual?.papel);
      });
    }
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.school, size: 80, color: Color(0xFF1565C0)),
              const SizedBox(height: 16),
              const Text(
                'EduMap',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Educação ao seu alcance',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _senhaController,
                obscureText: !_mostrarSenha,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_mostrarSenha ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: authProvedor.estaCarregando ? null : () async {
                  if (_emailController.text.trim().isEmpty || _senhaController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
                    return;
                  }
                  
                  final sucesso = await authProvedor.login(
                    _emailController.text.trim(),
                    _senhaController.text,
                  );
                  
                  if (sucesso && mounted) {
                    _redirecionar(context, authProvedor.usuarioAtual?.papel);
                  } else if (mounted && authProvedor.mensagemErro != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvedor.mensagemErro!), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: authProvedor.estaCarregando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Entrar', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              
              const SizedBox(height: 16),
              
              OutlinedButton.icon(
                onPressed: authProvedor.estaCarregando ? null : () async {
                  final sucesso = await authProvedor.loginComGoogle();
                  if (sucesso && mounted) {
                    _redirecionar(context, authProvedor.usuarioAtual?.papel);
                  }
                },
                icon: const Icon(Icons.login, color: Colors.red),
                label: const Text('Entrar com Google'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Não tem conta? '),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCadastro())),
                    child: const Text('Cadastre-se'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
