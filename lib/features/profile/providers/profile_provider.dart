import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/cached_list_repository.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/local_storage.dart';
import '../../../features/auth/models/user_model.dart';
import '../../../features/auth/providers/auth_provider.dart';

// Profile provider just re-exposes the current user with convenience selectors
final profileProvider = Provider<UserModel?>((ref) {
  return ref.watch(currentUserProvider);
});

/// Insignia tal como la devuelve `GET /badges` — ya no hay una lista
/// hardcodeada en el cliente que decida por su cuenta cuándo se
/// desbloquea algo. Antes había 6 insignias locales que se calculaban
/// solo por puntos (`points >= requiredPoints`) con descripciones que
/// prometían otra cosa ("Completa tu primera misión" se conseguía con 10
/// puntos, sin misiones de por medio); ahora `earned`/`earnedAt` vienen
/// tal cual del servidor, que es quien de verdad evalúa la condición
/// (`condition_type`/`condition_value`) contra `users.points`/
/// `game_stars`/capítulos/avistamientos reales.
class BadgeModel {
  const BadgeModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.conditionType,
    required this.conditionValue,
    required this.earned,
    this.earnedAt,
  });

  final int id;
  final String name;
  final String emoji;
  final String description;

  /// 'points' | 'chapters' | 'sightings' | 'game_stars' (y 'missions',
  /// heredado — ninguna insignia activa lo usa ya).
  final String conditionType;
  final int conditionValue;
  final bool earned;
  final String? earnedAt;

  factory BadgeModel.fromJson(Map<String, dynamic> json) => BadgeModel(
        id: json['id'] as int,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        description: json['description'] as String,
        conditionType: json['condition_type'] as String,
        conditionValue: json['condition_value'] as int,
        earned: json['earned'] as bool? ?? false,
        earnedAt: json['earned_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'description': description,
        'condition_type': conditionType,
        'condition_value': conditionValue,
        'earned': earned,
        'earned_at': earnedAt,
      };
}

class BadgesState {
  const BadgesState({
    this.badges = const [],
    this.isLoading = false,
    this.isStale = false,
  });

  final List<BadgeModel> badges;
  final bool isLoading;
  final bool isStale;

  BadgesState copyWith({
    List<BadgeModel>? badges,
    bool? isLoading,
    bool? isStale,
  }) =>
      BadgesState(
        badges: badges ?? this.badges,
        isLoading: isLoading ?? this.isLoading,
        isStale: isStale ?? this.isStale,
      );
}

/// Carga `GET /badges` con el mismo patrón "red → caché → nada" que ya
/// usa `chaptersProvider` (`loadCachedList`, en
/// core/data/cached_list_repository.dart): si el perfil se abre sin
/// conexión, se ve la última foto conocida de las insignias en vez de una
/// pantalla vacía.
class BadgesNotifier extends StateNotifier<BadgesState> {
  BadgesNotifier(this._ref) : super(const BadgesState()) {
    load();
  }

  final Ref _ref;

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final result = await loadCachedList<BadgeModel>(
      api: _ref.read(apiClientProvider),
      path: ApiEndpoints.badges,
      envelopeKey: 'badges',
      fromJson: BadgeModel.fromJson,
      toJson: (b) => b.toJson(),
      readCache: LocalStorage.instance.getCachedBadges,
      writeCache: LocalStorage.instance.cacheBadges,
      // Sin `seed`: a diferencia de los capítulos, no tiene sentido
      // inventar insignias de ejemplo — o se tienen de verdad, o no.
    );
    state = state.copyWith(
      badges: result.items,
      isLoading: false,
      isStale: result.isStale,
    );
  }
}

final badgesProvider = StateNotifierProvider<BadgesNotifier, BadgesState>(
  (ref) => BadgesNotifier(ref),
);
