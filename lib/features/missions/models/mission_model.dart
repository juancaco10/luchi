// ── MissionType ───────────────────────────────────────────────────

enum MissionType { daily, weekly }

// ── MissionModel ──────────────────────────────────────────────────

class MissionModel {
  final int id;
  final String title;
  final String description;
  final MissionType type;
  final int pointsReward;
  final String icon;
  final String? howTo;
  final String? tip;
  final bool isCompleted;

  const MissionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.pointsReward,
    required this.icon,
    this.howTo,
    this.tip,
    this.isCompleted = false,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) => MissionModel(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        type: (json['type'] as String?) == 'weekly'
            ? MissionType.weekly
            : MissionType.daily,
        pointsReward: json['points_reward'] as int? ?? 10,
        icon: json['icon'] as String? ?? '🎯',
        howTo: json['how_to'] as String?,
        tip: json['tip'] as String?,
        isCompleted: json['is_completed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'points_reward': pointsReward,
        'icon': icon,
        'how_to': howTo,
        'tip': tip,
        'is_completed': isCompleted,
      };

  MissionModel copyWith({
    int? id,
    String? title,
    String? description,
    MissionType? type,
    int? pointsReward,
    String? icon,
    String? howTo,
    String? tip,
    bool? isCompleted,
  }) =>
      MissionModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        type: type ?? this.type,
        pointsReward: pointsReward ?? this.pointsReward,
        icon: icon ?? this.icon,
        howTo: howTo ?? this.howTo,
        tip: tip ?? this.tip,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  // ── Mock data ─────────────────────────────────────────────────
  static List<MissionModel> getMockMissions() => [
        MissionModel(
          id: 1,
          title: 'Apaga luces innecesarias',
          description:
              'Durante la noche de hoy, apaga todas las luces exteriores que no necesites.',
          type: MissionType.daily,
          pointsReward: 10,
          icon: '💡',
          howTo:
              'Cuando anochezca, recorre tu casa y apaga las luces del jardín, porche o terraza que no estés usando.',
          tip:
              'La contaminación lumínica es la principal amenaza para las luciérnagas. ¡Cada luz apagada cuenta!',
        ),
        MissionModel(
          id: 2,
          title: 'Observa la naturaleza 5 min',
          description:
              'Siéntate afuera o cerca de una ventana y observa la naturaleza por 5 minutos.',
          type: MissionType.daily,
          pointsReward: 10,
          icon: '🌿',
          howTo:
              'Busca un lugar tranquilo. Presta atención a insectos, plantas y sonidos.',
          tip:
              'La observación consciente nos conecta con la naturaleza y nos hace mejores guardianes.',
        ),
        MissionModel(
          id: 3,
          title: 'Lee un dato sobre luciérnagas',
          description:
              'Aprende un dato nuevo sobre las luciérnagas y cuéntaselo a alguien.',
          type: MissionType.daily,
          pointsReward: 10,
          icon: '📚',
          howTo:
              'Ve a la sección de Capítulos y lee al menos un hecho de cualquier capítulo.',
          tip:
              'Compartir conocimiento es una forma de proteger: cuantas más personas sepan, mejor.',
        ),
        MissionModel(
          id: 4,
          title: 'Semana sin pesticidas',
          description:
              'Compromete a tu familia a no usar pesticidas durante esta semana.',
          type: MissionType.weekly,
          pointsReward: 30,
          icon: '🌱',
          howTo:
              'Habla con tu familia sobre el daño que los pesticidas causan a insectos benéficos.',
          tip:
              'Las larvas de luciérnaga viven en la tierra. Los pesticidas las matan antes de convertirse en adultos.',
        ),
        MissionModel(
          id: 5,
          title: 'Planta algo nativo',
          description:
              'Planta una semilla o plántula de especie nativa de tu región.',
          type: MissionType.weekly,
          pointsReward: 30,
          icon: '🌻',
          howTo:
              'Visita un vivero local o usa semillas de plantas que ya crecen en tu zona.',
          tip:
              'Las plantas nativas proveen el hábitat perfecto para las luciérnagas y otros insectos benéficos.',
        ),
        MissionModel(
          id: 6,
          title: 'Registra un avistamiento',
          description:
              'Sal al anochecer y registra si ves (o no) luciérnagas en tu zona.',
          type: MissionType.weekly,
          pointsReward: 30,
          icon: '✨',
          howTo:
              'Espera que oscurezca y observa durante al menos 15 minutos.',
          tip:
              'Incluso reportar que NO viste luciérnagas es información valiosa para los científicos.',
        ),
      ];
}
