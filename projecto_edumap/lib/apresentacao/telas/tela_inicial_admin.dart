import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tela_perfil.dart';
import 'tela_solicitacoes_professor.dart';

class TelaInicialAdmin extends StatefulWidget {
  const TelaInicialAdmin({super.key});

  @override
  State<TelaInicialAdmin> createState() => _TelaInicialAdminState();
}

class _TelaInicialAdminState extends State<TelaInicialAdmin> {
  String _searchQuery = "";
  int _currentIndex  = 0;
  final Color _primaryBlue = const Color(0xFF1565C0);
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final List<Widget> tabs = [
      _buildHomeTab(uid),
      const TelaPerfil(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _currentIndex == 0
          ? AppBar(
        title: const Text('EduMap',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primaryBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.people, color: Colors.white),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TelaSolicitacoesProfessor())),
          ),
        ],
      )
          : null,
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(String? uid) {
    return Column(
      children: [
        _buildAdminHeader(uid),
        _buildNotificacaoPendentes(),
        _buildStatsRow(),
        _buildSearchBar(),
        _buildUserListHeader(),
        Expanded(child: _buildUserList(uid)),
      ],
    );
  }

  Widget _buildAdminHeader(String? uid) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _supabase.from('users').select('name').eq('id', uid ?? ''),
      builder: (context, snapshot) {
        final name = snapshot.data?.isNotEmpty == true
            ? snapshot.data![0]['name'] ?? 'Administrador'
            : 'Administrador';
        return Container(
          width: double.infinity,
          color: _primaryBlue,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bem-vindo, $name',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              Text('Painel de Administração',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificacaoPendentes() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('solicitacoes_professor')
          .stream(primaryKey: ['id'])
          .eq('status', 'pendente'),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const TelaSolicitacoesProfessor())),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('$count solicitação(ões) de professor pendente(s)',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
                const Icon(Icons.chevron_right, color: Colors.orange),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('users').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        final total   = snapshot.data?.length ?? 0;
        final activos = snapshot.data
            ?.where((u) => u['is_active'] == true)
            .length ?? 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(child: _statCard('Total de Utilizadores', total.toString())),
              const SizedBox(width: 16),
              Expanded(child: _statCard('Utilizadores Activos', activos.toString())),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: _primaryBlue, fontWeight: FontWeight.bold, fontSize: 28)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Pesquisar por nome ou email...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildUserListHeader() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('users').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Todos os Utilizadores',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('$count registados',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserList(String? currentUid) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase.from('users').stream(primaryKey: ['id']).order('name'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.where((u) {
          if (u['id'] == currentUid) return false;
          final name  = (u['name']  ?? '').toString().toLowerCase();
          final email = (u['email'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery) || email.contains(_searchQuery);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data     = docs[index];
            final uid      = data['id'];
            final name     = data['name']      ?? 'Utilizador';
            final email    = data['email']     ?? '';
            final role     = data['role']      ?? 'estudante';
            final isActive = data['is_active'] ?? true;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _primaryBlue,
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Colors.white)),
                ),
                title: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _buildRoleBadge(role),
                      const SizedBox(width: 8),
                      _buildStatusBadge(isActive),
                    ]),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(isActive ? Icons.block : Icons.check_circle,
                      color: isActive ? Colors.red : Colors.green),
                  onPressed: () => _toggleStatus(uid, isActive),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg, text;
    switch (role.toLowerCase()) {
      case 'professor': bg = const Color(0xFFE8F5E9); text = const Color(0xFF2E7D32); break;
      case 'admin':     bg = const Color(0xFFFFF3E0); text = const Color(0xFFE65100); break;
      case 'pendente':  bg = const Color(0xFFFFF8E1); text = const Color(0xFFF57F17); break;
      default:          bg = const Color(0xFFE3F2FD); text = const Color(0xFF1565C0);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(role.toUpperCase(),
          style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(isActive ? 'ACTIVO' : 'INACTIVO',
          style: TextStyle(
              color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
              fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _toggleStatus(String uid, bool current) async {
    try {
      await _supabase
          .from('users')
          .update({'is_active': !current})
          .eq('id', uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(current ? 'Utilizador desactivado' : 'Utilizador activado'),
          backgroundColor: current ? Colors.red : Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erro ao atualizar'), backgroundColor: Colors.red));
      }
    }
  }
}