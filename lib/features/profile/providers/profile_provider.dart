import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/models/user_model.dart';

// Profile provider just re-exposes the current user with convenience selectors
final profileProvider = Provider<UserModel?>((ref) {
  return ref.watch(currentUserProvider);
});

// Badges definition
class BadgeDefinition {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int requiredPoints;

  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.requiredPoints,
  });

  bool isUnlocked(int points) => points >= requiredPoints;
}

final allBadges = [
  BadgeDefinition(
    id: 'first_light',
    name: 'Primera Luz',
    emoji: '💡',
    description: 'Completa tu primera misión',
    requiredPoints: 10,
  ),
  BadgeDefinition(
    id: 'explorer',
    name: 'Explorador',
    emoji: '🔭',
    description: 'Alcanza 100 puntos',
    requiredPoints: 100,
  ),
  BadgeDefinition(
    id: 'guardian',
    name: 'Guardián',
    emoji: '🛡️',
    description: 'Alcanza 200 puntos',
    requiredPoints: 200,
  ),
  BadgeDefinition(
    id: 'master',
    name: 'Maestro Guardián',
    emoji: '⭐',
    description: 'Alcanza 400 puntos',
    requiredPoints: 400,
  ),
  BadgeDefinition(
    id: 'watcher',
    name: 'Observador Nocturno',
    emoji: '🌙',
    description: 'Registra tu primer avistamiento',
    requiredPoints: 20,
  ),
  BadgeDefinition(
    id: 'scientist',
    name: 'Pequeño Científico',
    emoji: '🧪',
    description: 'Completa un capítulo entero',
    requiredPoints: 15,
  ),
];
