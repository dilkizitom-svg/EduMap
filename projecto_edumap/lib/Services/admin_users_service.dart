import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserModel {
  final String id;
  final String email;
  final String? name;
  final String? role;
  final String? phone;
  final bool isActive;
  final bool hasProfile;
  final DateTime? createdAt;

  AdminUserModel({
    required this.id,
    required this.email,
    this.name,
    this.role,
    this.phone,
    required this.isActive,
    required this.hasProfile,
    this.createdAt,
  });

  factory AdminUserModel.fromSupabase(Map<String, dynamic> data) {
    return AdminUserModel(
      id:        data['id']         ?? '',
      email:     data['email']      ?? '',
      name:      data['name'],
      role:      data['role'],
      phone:     data['phone'],
      isActive:  data['is_active']  ?? true,
      hasProfile: true,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString())
          : null,
    );
  }
}

class AdminUsersService {
  final _supabase = Supabase.instance.client;

  Future<List<AdminUserModel>> listarUtilizadores() async {
    final data = await _supabase
        .from('users')
        .select()
        .order('name');
    return (data as List)
        .map((u) => AdminUserModel.fromSupabase(u))
        .toList();
  }

  Future<void> eliminarUtilizador(String uid) async {
    // Remove o perfil do Supabase
    await _supabase.from('users').delete().eq('id', uid);
  }

  Future<void> toggleStatus(String uid, bool isActive) async {
    await _supabase
        .from('users')
        .update({'is_active': isActive})
        .eq('id', uid);
  }
}