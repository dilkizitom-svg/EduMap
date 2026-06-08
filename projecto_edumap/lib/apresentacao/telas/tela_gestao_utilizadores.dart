import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Services/admin_users_service.dart';

class TelaGestaoUtilizadores extends StatefulWidget {
  const TelaGestaoUtilizadores({super.key});

  @override
  State<TelaGestaoUtilizadores> createState() => _TelaGestaoUtilizadoresState();
}

class _TelaGestaoUtilizadoresState extends State<TelaGestaoUtilizadores> {
  final _service = AdminUsersService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isProcessing = false;

  List<AdminUserModel> _allUsers = [];
  bool _loading = true;
  String? _erro;

  final _blue       = const Color(0xFF1565C0);
  final _activeColor = const Color(0xFF388E3C);
  final _inactiveColor = const Color(0xFFD32F2F);
  final _cardColor  = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final lista = await _service.listarUtilizadores();
      // Remove o próprio admin da lista
      lista.removeWhere((u) => u.id == currentUid);
      setState(() => _allUsers = lista);
    } catch (e) {
      setState(() => _erro = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<AdminUserModel> get _filtered {
    if (_searchQuery.isEmpty) return _allUsers;
    return _allUsers.where((u) {
      final name  = (u.name  ?? '').toLowerCase();
      final email = u.email.toLowerCase();
      return name.contains(_searchQuery) || email.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gestão de Utilizadores',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _erro != null
              ? _buildErro()
              : _buildContent(),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: Center(child: CircularProgressIndicator(color: _blue)),
            ),
        ],
      ),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_erro!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final filtered = _filtered;
    return Column(
      children: [
        _buildHeader(filtered.length),
        _buildSearchBar(),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('Nenhum utilizador encontrado.'))
              : RefreshIndicator(
            onRefresh: _carregar,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _buildCard(filtered[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(int count) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings_rounded, color: _blue),
          const SizedBox(width: 8),
          Text('$count contas no sistema',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Pesquisar nome ou email...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: _cardColor,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildCard(AdminUserModel user) {
    return Card(
      elevation: 0,
      color: _cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: _blue.withOpacity(0.1),
                child: Text(
                  (user.name ?? user.email)[0].toUpperCase(),
                  style: TextStyle(color: _blue, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(user.name ?? '— sem nome —',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email, style: const TextStyle(fontSize: 12)),
                  if (user.createdAt != null)
                    Text(
                      'Criado em: ${_formatDate(user.createdAt!)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                tooltip: 'Eliminar perfil',
                onPressed: () => _confirmarEliminacao(user),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (user.role != null)
                      _buildBadge(user.role!.toUpperCase(), Colors.blue),
                    if (!user.hasProfile)
                      _buildBadge('SEM PERFIL', Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      user.isActive ? 'ATIVA' : 'DESATIVADA',
                      style: TextStyle(
                        color: user.isActive ? _activeColor : _inactiveColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: user.isActive,
                  activeColor: _activeColor,
                  onChanged: (val) => _toggleStatus(user, val),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _toggleStatus(AdminUserModel user, bool val) async {
    setState(() => _isProcessing = true);
    try {
      await _service.toggleStatus(user.id, val);
      await _carregar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(val ? 'Conta reativada!' : 'Conta desativada!'),
          backgroundColor: val ? _activeColor : Colors.black,
          duration: const Duration(seconds: 1),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Falha: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _confirmarEliminacao(AdminUserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Utilizador?'),
        content: Text(
          'Vai apagar o perfil de:\n\n'
              '• ${user.name ?? user.email}\n\n'
              'Nota: No Firebase Client, apenas o registro do Firestore será removido.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteUser(user);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(AdminUserModel user) async {
    setState(() => _isProcessing = true);
    try {
      await _service.eliminarUtilizador(user.id);
      await _carregar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil removido do sistema!'),
              backgroundColor: Colors.black),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
