import 'package:flutter/foundation.dart';

@immutable
class Profile {
  final String id;
  final String? email;
  final String name;
  final List<String> roles;
  final String? phone;
  final bool active;
  final DateTime createdAt;

  const Profile({
    required this.id,
    this.email,
    required this.name,
    required this.roles,
    this.phone,
    this.active = true,
    required this.createdAt,
  });

  bool hasRole(String role) => roles.contains(role);
  bool get isAdmin => roles.contains('admin');

  Profile copyWith({
    String? id,
    String? email,
    String? name,
    List<String>? roles,
    String? phone,
    bool? active,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      roles: roles ?? this.roles,
      phone: phone ?? this.phone,
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
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    final rawRoles = map['roles'];
    List<String> rolesList;
    if (rawRoles is List) {
      rolesList = rawRoles.cast<String>();
    } else if (rawRoles is String) {
      rolesList = [rawRoles];
    } else {
      rolesList = ['vendedor'];
    }
    return Profile(
      id: map['id'] as String,
      email: map['email'] as String?,
      name: map['name'] as String,
      roles: rolesList,
      phone: map['phone'] as String?,
      active: map['active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
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
        other.active == active &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, email, name, Object.hashAll(roles), phone, active, createdAt);
  }

  @override
  String toString() {
    return 'Profile(id: $id, email: $email, name: $name, roles: $roles, active: $active)';
  }
}
