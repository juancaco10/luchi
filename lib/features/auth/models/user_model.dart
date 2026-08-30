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
  /// Apodo corto (máx. 12 caracteres) elegido por el usuario al entrar:
  /// cómo quiere que lo llamen en el feed y en la app. `displayName` es
  /// lo que se muestra siempre — apodo si lo hay, primer nombre si no.
  final String? nickname;
  // País/ciudad del perfil — requisito para publicar un avistamiento (ver
  // location_setup_screen.dart). `hasLocation` es lo que el redirect de
  // GoRouter usa para decidir si mandar a esa pantalla.
  final String? country;
  final String? city;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.points,
    required this.level,
    required this.levelName,
    this.avatarUrl,
    this.createdAt,
    this.nickname,
    this.country,
    this.city,
  });

  bool get hasLocation =>
      (country?.trim().isNotEmpty ?? false) && (city?.trim().isNotEmpty ?? false);

  bool get hasNickname => (nickname?.trim().isNotEmpty ?? false);

  /// Cómo pedirle que lo llamen: el apodo si lo eligió, si no su primer
  /// nombre. Es el valor que se muestra en el saludo del home, en las
  /// tarjetas de avistamientos propios y en el modal de detalle.
  String get displayName => hasNickname ? nickname!.trim() : name.split(' ').first;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        points: json['points'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        levelName: json['levelName'] as String? ?? 'Observador',
        avatarUrl: json['avatar_url'] as String?,
        createdAt: json['created_at'] as String?,
        nickname: json['nickname'] as String?,
        country: json['country'] as String?,
        city: json['city'] as String?,
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
        'nickname': nickname,
        'country': country,
        'city': city,
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
    String? nickname,
    String? country,
    String? city,
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
        nickname: nickname ?? this.nickname,
        country: country ?? this.country,
        city: city ?? this.city,
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
