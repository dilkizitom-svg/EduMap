import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaGestaoUtilizadores extends StatefulWidget {
  const TelaGestaoUtilizadores({super.key});

  @override
  State<TelaGestaoUtilizadores> createState() => _TelaGestaoUtilizadoresState();
}

class _TelaGestaoUtilizadoresState extends State<TelaGestaoUtilizadores> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final Color _activeColor = const Color(0xFF388E3C);
  final Color _inactiveColor = const Color(0xFF757575);
  final Color _deactivateColor = const Color(0xFFD32F2F);
  final Color _cardColor = const Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gestão de Utilizadores', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) return const Center(child: Text('Nenhum dado encontrado'));

          // Filtrar admins e por pesquisa
          final allUsers = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['role'] != 'admin';
          }).toList();

          final filteredUsers = allUsers.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || email.contains(_searchQuery);
          }).toList();

          final activeCount = allUsers.where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] == true).length;

          return Column(
            children: [
              _buildSummaryHeader(activeCount),
              _buildSearchBar(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final doc = filteredUsers[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildUserCard(doc.id, data);
                  },
                ),
              ),
              _buildFooter(allUsers.length, activeCount),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(int activeCount) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.people_outline, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '$activeCount utilizadores activos',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
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
          hintText: 'Pesquisar por nome ou email...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: _cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(String uid, Map<String, dynamic> data) {
    final bool isActive = data['isActive'] ?? true;
    final String role = data['role'] ?? 'aluno';

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
                backgroundColor: Colors.blue.shade100,
                child: Text(data['name']?[0].toUpperCase() ?? 'U'),
              ),
              title: Text(data['name'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(data['email'] ?? ''),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBadge(role.toUpperCase(), Colors.blue),
                  const SizedBox(height: 4),
                  _buildBadge(
                    isActive ? 'ACTIVO' : 'INACTIVO',
                    isActive ? _activeColor : _inactiveColor,
                  ),
                ],
              ),
            ),
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _toggleUserStatus(uid, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _deactivateColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Desativar Conta'),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _toggleUserStatus(uid, true),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _activeColor),
                      foregroundColor: _activeColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Reativar Conta'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFooter(int total, int active) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('TOTAL', total.toString()),
          _buildStat('ACTIVOS', active.toString()),
          _buildStat('INACTIVOS', (total - active).toString()),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Future<void> _toggleUserStatus(String uid, bool status) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'isActive': status});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar status: $e')),
        );
      }
    }
  }
}
