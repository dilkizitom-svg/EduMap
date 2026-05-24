/// TELA DE CADASTRO
/// Cria uma nova conta de usuário

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provedores/auth_provedor.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  // Controladores
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  
  bool _mostrarSenha = false;
  
  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvedor = Provider.of<AuthProvedor>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.person_add, size: 60, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Cadastro',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // NOME
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // E-MAIL
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
              
              // SENHA
              TextField(
                controller: _senhaController,
                obscureText: !_mostrarSenha,
                decoration: InputDecoration(
                  labelText: 'Senha (mínimo 8 caracteres)',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_mostrarSenha ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _mostrarSenha = !_mostrarSenha),
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // CONFIRMAR SENHA
              TextField(
                controller: _confirmarSenhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar senha',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              
              // BOTÃO CADASTRAR
              ElevatedButton(
                onPressed: authProvedor.estaCarregando ? null : () async {
                  // Validações
                  if (_nomeController.text.trim().isEmpty) {
                    _mostrarErro('Informe seu nome completo');
                    return;
                  }
                  if (_emailController.text.trim().isEmpty) {
                    _mostrarErro('Informe seu e-mail');
                    return;
                  }
                  if (!_emailController.text.contains('@')) {
                    _mostrarErro('E-mail inválido');
                    return;
                  }
                  if (_senhaController.text.length < 8) {
                    _mostrarErro('A senha deve ter pelo menos 8 caracteres');
                    return;
                  }
                  if (_senhaController.text != _confirmarSenhaController.text) {
                    _mostrarErro('As senhas não coincidem');
                    return;
                  }
                  
                  // Tenta cadastrar
                  final sucesso = await authProvedor.registrar(
                    _emailController.text.trim(),
                    _senhaController.text,
                    _nomeController.text.trim(),
                  );
                  
                  if (sucesso && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Conta criada com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context); // Volta para login
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
                    : const Text('Cadastrar', style: TextStyle(fontSize: 16)),
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
}