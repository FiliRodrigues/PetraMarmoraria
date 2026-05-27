import 'package:flutter/foundation.dart';

@immutable
class Profile {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final bool active;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.active = true,
    required this.createdAt,
  });

  Profile copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    bool? active,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
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
      'role': role,
      'phone': phone,
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
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
        other.role == role &&
        other.phone == phone &&
        other.active == active &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, email, name, role, phone, active, createdAt);
  }

  @override
  String toString() {
    return 'Profile(id: $id, email: $email, name: $name, role: $role, active: $active)';
  }
}
