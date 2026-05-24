import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../provedores/auth_provedor.dart';
import 'tela_perfil.dart';

class TelaInicialAdmin extends StatefulWidget {
  const TelaInicialAdmin({super.key});

  @override
  State<TelaInicialAdmin> createState() => _TelaInicialAdminState();
}

class _TelaInicialAdminState extends State<TelaInicialAdmin> {
  String _searchQuery = "";
  int _currentIndex = 0;
  final Color _primaryBlue = const Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final List<Widget> _tabs = [
      _buildHomeTab(uid),
      const TelaPerfil(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _currentIndex == 0 
        ? AppBar(
            title: const Text('EduMap', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: _primaryBlue,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.people, color: Colors.white),
                onPressed: () {},
              ),
            ],
          )
        : null, // Perfil has its own AppBar
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: _primaryBlue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
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
        _buildStatsRow(),
        _buildSearchBar(),
        _buildUserListHeader(),
        Expanded(child: _buildUserList(uid)),
      ],
    );
  }

  Widget _buildAdminHeader(String? uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        String name = "Administrador";
        if (snapshot.hasData && snapshot.data!.exists) {
          name = snapshot.data!.get('name') ?? snapshot.data!.get('nome') ?? "Administrador";
        }
        return Container(
          width: double.infinity,
          color: _primaryBlue,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bem-vindo, $name', 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              Text('Painel de Administração', 
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int activos = 0;
        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          activos = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isActive'] == true || data['estaAtivo'] == true;
          }).length;
        }
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold, fontSize: 28)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Pesquisar por nome ou email...',
          hintStyle: const TextStyle(fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildUserListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Todos os Utilizadores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Text('$count registados', style: const TextStyle(color: Colors.grey, fontSize: 13));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(String? currentUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? data['nome'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();
          return doc.id != currentUid && (name.contains(_searchQuery) || email.contains(_searchQuery));
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final uid = docs[index].id;
            final String name = data['name'] ?? data['nome'] ?? 'Utilizador';
            final String email = data['email'] ?? '';
            final String role = data['role'] ?? data['papel'] ?? 'estudante';
            final bool isActive = data['isActive'] ?? data['estaAtivo'] ?? true;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _primaryBlue, 
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', 
                    style: const TextStyle(color: Colors.white))
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildRoleBadge(role),
                        const SizedBox(width: 8),
                        _buildStatusBadge(isActive),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(isActive ? Icons.block : Icons.check_circle, 
                    color: isActive ? Colors.red : Colors.green),
                  onPressed: () => _toggleUserStatus(uid, isActive),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg;
    Color text;
    switch (role.toLowerCase()) {
      case 'professor':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        break;
      case 'admin':
        bg = const Color(0xFFFFF3E0);
        text = const Color(0xFFE65100);
        break;
      default: // estudante
        bg = const Color(0xFFE3F2FD);
        text = const Color(0xFF1565C0);
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
        borderRadius: BorderRadius.circular(12)
      ),
      child: Text(isActive ? 'ACTIVO' : 'INACTIVO', 
        style: TextStyle(
          color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828), 
          fontSize: 10, 
          fontWeight: FontWeight.bold)
      ),
    );
  }

  Future<void> _toggleUserStatus(String uid, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isActive': !currentStatus,
        'estaAtivo': !currentStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(currentStatus ? 'Utilizador desactivado' : 'Utilizador activado'), 
          backgroundColor: currentStatus ? Colors.red : Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao atualizar status'), 
          backgroundColor: Colors.red));
      }
    }
  }
}
