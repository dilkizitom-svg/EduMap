import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../provedores/auth_provedor.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({super.key});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final _nomeController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _senhaController    = TextEditingController();
  final _confirmarController = TextEditingController();
  final _telefoneController = TextEditingController();

  String _roleSelecionado   = 'estudante';
  File?  _documentoSelecionado;
  bool   _enviando          = false;

  final List<String> roles  = ['estudante', 'professor'];
  final Color _primaryColor = const Color(0xFF1565C0);

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _selecionarDocumento() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _documentoSelecionado = File(result.files.single.path!));
    }
  }

  Future<void> _realizarCadastro() async {
    final authProvedor = Provider.of<AuthProvedor>(context, listen: false);

    if (_nomeController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _senhaController.text.isEmpty) {
      _snack('Preencha os campos obrigatórios', Colors.orange);
      return;
    }

    if (_senhaController.text != _confirmarController.text) {
      _snack('As senhas não coincidem', Colors.red);
      return;
    }

    if (_roleSelecionado == 'professor' && _documentoSelecionado == null) {
      _snack('Professores devem submeter um comprovativo.', Colors.orange);
      return;
    }

    setState(() => _enviando = true);

    try {
      final sucesso = await authProvedor.registrar(
        _emailController.text.trim(),
        _senhaController.text,
        _nomeController.text.trim(),
        role:      _roleSelecionado == 'professor' ? 'pendente' : 'estudante',
        phone:     _telefoneController.text.trim(),
        documento: _documentoSelecionado, // ← passa o documento
      );

      if (!sucesso) {
        _snack(authProvedor.mensagemErro ?? 'Falha no cadastro', Colors.red);
        return;
      }

      if (_roleSelecionado == 'professor') {
        _mostrarSucessoProfessor();
      } else {
        _snack('Conta criada com sucesso!', Colors.green);
        Navigator.pop(context);
      }

    } catch (e) {
      _snack('Erro: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarSucessoProfessor() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pending_actions, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Text('Solicitação Enviada'),
          ],
        ),
        content: const Text(
          'O seu pedido foi enviado para análise.\n\n'
              'Um administrador irá verificar o seu documento '
              'e aprovar ou recusar o acesso como professor.\n\n'
              'Aguarde o contacto.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
        title: const Text('Criar Conta'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(_nomeController,  'Nome completo', Icons.person),
            const SizedBox(height: 12),
            _buildTextField(_emailController, 'Email', Icons.email,
                type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _buildTextField(_telefoneController, 'Telefone', Icons.phone,
                type: TextInputType.phone),
            const SizedBox(height: 12),
            _buildTextField(_senhaController, 'Senha', Icons.lock, obscure: true),
            const SizedBox(height: 12),
            _buildTextField(_confirmarController, 'Confirmar senha', Icons.lock,
                obscure: true),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _roleSelecionado,
              decoration: InputDecoration(
                labelText: 'Desejo ser:',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.badge),
              ),
              items: roles.map((r) => DropdownMenuItem(
                value: r,
                child: Row(
                  children: [
                    Icon(r == 'professor' ? Icons.school : Icons.person,
                        size: 18, color: _primaryColor),
                    const SizedBox(width: 8),
                    Text(r.toUpperCase()),
                  ],
                ),
              )).toList(),
              onChanged: (val) => setState(() => _roleSelecionado = val!),
            ),

            if (_roleSelecionado == 'professor') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Professores precisam de aprovação do administrador. '
                            'Submeta um documento que comprove a sua identidade.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selecionarDocumento,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _documentoSelecionado != null
                        ? const Color(0xFFE8F5E9)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _documentoSelecionado != null
                          ? Colors.green
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _documentoSelecionado != null
                            ? Icons.check_circle
                            : Icons.upload_file,
                        color: _documentoSelecionado != null
                            ? Colors.green
                            : _primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _documentoSelecionado != null
                              ? _documentoSelecionado!.path.split('/').last
                              : 'Selecionar documento (PDF, JPG, PNG)',
                          style: TextStyle(
                            color: _documentoSelecionado != null
                                ? Colors.green[700]
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _enviando ? null : _realizarCadastro,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _enviando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  _roleSelecionado == 'professor'
                      ? 'Enviar Solicitação'
                      : 'Cadastrar',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType type = TextInputType.text,
        bool obscure = false,
      }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}