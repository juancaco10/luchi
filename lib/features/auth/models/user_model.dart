// ── UserModel ─────────────────────────────────────────────────────

class UserModel {
  final int id;
  final String name;
  final String email;
  final int points;
  final int level;
  final String levelName;
  final String? avatarUrl;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.points,
    required this.level,
    required this.levelName,
    this.avatarUrl,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        points: json['points'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        levelName: json['levelName'] as String? ?? 'Observador',
        avatarUrl: json['avatar_url'] as String?,
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'points': points,
        'level': level,
        'levelName': levelName,
        'avatar_url': avatarUrl,
        'created_at': createdAt,
      };

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    int? points,
    int? level,
    String? levelName,
    String? avatarUrl,
    String? createdAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        points: points ?? this.points,
        level: level ?? this.level,
        levelName: levelName ?? this.levelName,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt ?? this.createdAt,
      );
}

// ── AuthState (Dart 3 sealed class) ──────────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
