/// TELA DE LOGIN
/// Permite o usuário entrar com e-mail/senha ou Google

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provedores/auth_provedor.dart';
import 'tela_cadastro.dart';
import 'tela_inicial.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  // Controladores dos campos
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  
  // Mostrar/esconder senha
  bool _mostrarSenha = false;
  
  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvedor = Provider.of<AuthProvedor>(context);
    
    // Se já estiver logado, vai para tela inicial
    if (authProvedor.usuarioAtual != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TelaInicial()),
        );
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
              
              // LOGO
              const Icon(Icons.school, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'EduMap',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                'Educação ao seu alcance',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // CAMPO E-MAIL
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
              
              // CAMPO SENHA
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
              const SizedBox(height: 8),
              
              // ESQUECEU SENHA
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _mostrarMensagem('Recuperação de senha em breve');
                  },
                  child: const Text('Esqueceu a senha?'),
                ),
              ),
              const SizedBox(height: 24),
              
              // BOTÃO ENTRAR
              ElevatedButton(
                onPressed: authProvedor.estaCarregando ? null : () async {
                  // Validações
                  if (_emailController.text.trim().isEmpty) {
                    _mostrarErro('Digite seu e-mail');
                    return;
                  }
                  if (_senhaController.text.isEmpty) {
                    _mostrarErro('Digite sua senha');
                    return;
                  }
                  
                  // Tenta login
                  final sucesso = await authProvedor.login(
                    _emailController.text.trim(),
                    _senhaController.text,
                  );
                  
                  if (sucesso && mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const TelaInicial()),
                    );
                  } else if (mounted && authProvedor.mensagemErro != null) {
                    _mostrarErro(authProvedor.mensagemErro!);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: authProvedor.estaCarregando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Entrar', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              
              // BOTÃO GOOGLE
              OutlinedButton.icon(
                onPressed: authProvedor.estaCarregando ? null : () async {
                  final sucesso = await authProvedor.loginComGoogle();
                  if (sucesso && mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const TelaInicial()),
                    );
                  }
                },
                icon: Image.network(
                  'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png',
                  height: 20,
                ),
                label: const Text('Entrar com Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
              
              // LINK CADASTRO
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Não tem conta? '),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TelaCadastro()),
                      );
                    },
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
  
  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }
  
  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }
}