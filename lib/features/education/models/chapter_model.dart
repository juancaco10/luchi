// ── ChapterModel ──────────────────────────────────────────────────

class ChapterModel {
  final int id;
  final String title;
  final String description;
  final String videoUrl;
  final String? thumbnailUrl;
  final int orderIndex;
  final int pointsReward;
  final List<String> facts;
  final bool isCompleted;
  final bool isUnlocked;

  const ChapterModel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.orderIndex,
    required this.pointsReward,
    this.facts = const [],
    this.isCompleted = false,
    this.isUnlocked = false,
  });

  factory ChapterModel.fromJson(Map<String, dynamic> json) => ChapterModel(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        videoUrl: json['video_url'] as String? ?? '',
        thumbnailUrl: json['thumbnail_url'] as String?,
        orderIndex: json['order_index'] as int? ?? 1,
        pointsReward: json['points_reward'] as int? ?? 15,
        facts: (json['facts'] as List<dynamic>?)
                ?.map<String>((e) => e.toString())
                .toList() ??
            [],
        isCompleted: json['is_completed'] as bool? ?? false,
        isUnlocked: json['is_unlocked'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'order_index': orderIndex,
        'points_reward': pointsReward,
        'facts': facts,
        'is_completed': isCompleted,
        'is_unlocked': isUnlocked,
      };

  ChapterModel copyWith({
    int? id,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    int? orderIndex,
    int? pointsReward,
    List<String>? facts,
    bool? isCompleted,
    bool? isUnlocked,
  }) =>
      ChapterModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        videoUrl: videoUrl ?? this.videoUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        orderIndex: orderIndex ?? this.orderIndex,
        pointsReward: pointsReward ?? this.pointsReward,
        facts: facts ?? this.facts,
        isCompleted: isCompleted ?? this.isCompleted,
        isUnlocked: isUnlocked ?? this.isUnlocked,
      );

  // ── Mock data (8 Niveles Temáticos Educativos) ──────────────────────
  // Cada capítulo reproduce su video empaquetado en el APK
  // (`assets/videos/n.mp4`), así Aprender funciona sin conexión.
  static List<ChapterModel> getMockChapters() => [
        const ChapterModel(
          id: 1,
          title: '¿Qué es una luciérnaga?',
          description:
              'Descubre los secretos de estos increíbles insectos bioluminiscentes que iluminan las noches de verano.',
          videoUrl: 'assets/videos/1.mp4',
          orderIndex: 1,
          pointsReward: 15,
          isUnlocked: true,
          facts: [
            'Las luciérnagas producen luz fría — ¡casi sin emitir calor!',
            'Su luz es producida por una reacción química llamada bioluminiscencia.',
            'Existen más de 2.000 especies de luciérnagas en el mundo.',
          ],
        ),
        const ChapterModel(
          id: 2,
          title: 'Su hábitat natural',
          description:
              'Aprende dónde viven las luciérnagas y por qué necesitan lugares oscuros y húmedos para sobrevivir.',
          videoUrl: 'assets/videos/2.mp4',
          orderIndex: 2,
          pointsReward: 15,
          facts: [
            'Prefieren zonas húmedas como prados y bordes de ríos.',
            'La contaminación lumínica es su mayor amenaza.',
            'Necesitan vegetación para esconderse durante el día.',
          ],
        ),
        const ChapterModel(
          id: 3,
          title: 'Por qué están desapareciendo',
          description:
              'Entiende las causas del declive de las luciérnagas y cómo cada uno puede hacer la diferencia.',
          videoUrl: 'assets/videos/3.mp4',
          orderIndex: 3,
          pointsReward: 20,
          facts: [
            'La pérdida de hábitat afecta a gran parte de las especies.',
            'El uso de pesticidas mata a sus larvas que viven en la tierra.',
            'Puedes ayudar apagando luces exteriores innecesarias.',
          ],
        ),
        const ChapterModel(
          id: 4,
          title: 'Cómo ser un Guardián',
          description:
              'Aprende las acciones concretas que puedes tomar para proteger a las luciérnagas en tu vecindario.',
          videoUrl: 'assets/videos/4.mp4',
          orderIndex: 4,
          pointsReward: 25,
          facts: [
            'Cada pequeño Guardián suma para proteger la biodiversidad.',
            'Apagar luces innecesarias crea un hogar seguro para la noche.',
            'Plantaciones nativas y zonas húmedas atraen a las luciérnagas.',
          ],
        ),
        const ChapterModel(
          id: 5,
          title: 'La luz que comunica',
          description:
              'Descubre cómo las luciérnagas usan su luz para comunicarse y encontrar pareja en la noche.',
          videoUrl: 'assets/videos/5.mp4',
          orderIndex: 5,
          pointsReward: 15,
          facts: [
            'Cada especie tiene su propio patrón de destellos, como una firma.',
            'Usan su luz como un código de señas para encontrarse.',
            'La luz artificial de la ciudad las confunde de noche.',
          ],
        ),
        const ChapterModel(
          id: 6,
          title: 'El ciclo de vida',
          description:
              'Sigue el viaje de una luciérnaga desde el huevo hasta convertirse en un adulto brillante.',
          videoUrl: 'assets/videos/6.mp4',
          orderIndex: 6,
          pointsReward: 20,
          facts: [
            'La mayor parte de su vida la pasan como larva, no como adulto.',
            'Las larvas viven en la tierra húmeda y cazan caracoles y babosas.',
            'Huevo, larva, pupa y adulto: su metamorfosis completa.',
          ],
        ),
        const ChapterModel(
          id: 7,
          title: 'Cómo alimentarse sin dañar',
          description:
              'Aprende cómo la alimentación de las luciérnagas ayuda a mantener sano el jardín.',
          videoUrl: 'assets/videos/7.mp4',
          orderIndex: 7,
          pointsReward: 15,
          facts: [
            'Las larvas son pequeñas cazadoras que controlan caracoles y babosas.',
            'Evitar pesticidas protege a las larvas que viven en la tierra.',
            'Un jardín natural les ofrece comida y refugio.',
          ],
        ),
        const ChapterModel(
          id: 8,
          title: 'Misión Guardianes de la Luz',
          description:
              'Demuestra todo lo aprendido en el reto final y graduación como Guardián Oficial de las Luciérnagas.',
          videoUrl: 'assets/videos/8.mp4',
          orderIndex: 8,
          pointsReward: 30,
          facts: [
            '¡Cada pequeño Guardián suma para proteger la biodiversidad!',
            'Registrar avistamientos ayuda a científicos a mapear sus poblaciones.',
            'Compartir lo aprendido con amigos inspira a más personas a cuidar la naturaleza.',
          ],
        ),
      ];
}
