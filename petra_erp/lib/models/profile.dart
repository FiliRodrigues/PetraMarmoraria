import 'package:flutter/foundation.dart';

@immutable
class Profile {
  final String id;
  final String email;
  final String name;

  /// Source of truth: the database column `roles` is a text array, so a
  /// profile can hold multiple roles (e.g. ['admin', 'vendedor']).
  final List<String> roles;

  final String? phone;
  final String? avatarUrl;
  final bool active;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.email,
    required this.name,
    this.roles = const [],
    this.phone,
    this.avatarUrl,
    this.active = true,
    required this.createdAt,
  });

  /// Convenience accessor used throughout the UI where a single label is
  /// enough. Prefers 'admin' when present, otherwise the first role.
  String get role {
    if (roles.isEmpty) return '';
    if (roles.any((r) => r.toLowerCase() == 'admin')) return 'admin';
    return roles.first;
  }

  bool hasRole(String role) =>
      roles.any((r) => r.toLowerCase() == role.toLowerCase());

  bool get isAdmin => hasRole('admin');

  Profile copyWith({
    String? id,
    String? email,
    String? name,
    List<String>? roles,
    String? phone,
    String? avatarUrl,
    bool? active,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      roles: roles ?? this.roles,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'roles': roles,
      'phone': phone,
      'avatar_url': avatarUrl,
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      roles: _parseRoles(map['roles']),
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      active: map['active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Accepts a Postgres text[] (decoded as List) or a single string, so the
  /// model is resilient to either shape coming back from the API.
  static List<String> _parseRoles(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String && raw.isNotEmpty) return [raw];
    return const [];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        listEquals(other.roles, roles) &&
        other.phone == phone &&
        other.avatarUrl == avatarUrl &&
        other.active == active &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      email,
      name,
      Object.hashAll(roles),
      phone,
      avatarUrl,
      active,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Profile(id: $id, email: $email, name: $name, roles: $roles, active: $active)';
  }
}
