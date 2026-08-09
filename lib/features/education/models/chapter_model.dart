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

  // ── Mock data (4 Niveles Temáticos Educativos) ──────────────────────
  static List<ChapterModel> getMockChapters() => [
        const ChapterModel(
          id: 1,
          title: 'Nivel 1: Descubriendo a las Luciérnagas',
          description:
              'Descubre los secretos de estos increíbles insectos bioluminiscentes que iluminan las noches de verano.',
          videoUrl:
              'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
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
          title: 'Nivel 2: Las Sombras en la Noche (Las 5 Amenazas)',
          description:
              'Aprende sobre las principales amenazas que enfrentan las luciérnagas: contaminación lumínica, pesticidas y pérdida de hábitat.',
          videoUrl:
              'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          orderIndex: 2,
          pointsReward: 20,
          facts: [
            'El 20% de las especies de luciérnagas están en peligro de extinción.',
            'La contaminación lumínica de focos y ciudades les impide comunicarse.',
            'Las larvas viven en la tierra húmeda y sufren por el uso de pesticidas.',
          ],
        ),
        const ChapterModel(
          id: 3,
          title: 'Nivel 3: ¿Cómo Podemos Ayudar?',
          description:
              'Descubre acciones sencillas y reales que tú y tu familia pueden hacer en casa para proteger su hábitat.',
          videoUrl:
              'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
          orderIndex: 3,
          pointsReward: 25,
          facts: [
            'Apagar luces exteriores innecesarias crea un hogar seguro para la noche.',
            'Evitar pesticidas en el jardín protege a las larvas en la tierra.',
            'Plantaciones nativas y zonas húmedas atraen a las luciérnagas.',
          ],
        ),
        const ChapterModel(
          id: 4,
          title: 'Nivel 4: Misión Guardianes de la Luz',
          description:
              'Demuestra todo lo aprendido en el reto final y graduación como Guardián Oficial de las Luciérnagas.',
          videoUrl:
              'https://download.samplelib.com/mp4/sample-15s.mp4',
          orderIndex: 4,
          pointsReward: 30,
          facts: [
            '¡Cada pequeño Guardián suma para proteger la biodiversidad!',
            'Registrar avistamientos ayuda a científicos a mapear sus poblaciones.',
            'Compartir lo aprendido con amigos inspira a más personas a cuidar la naturaleza.',
          ],
        ),
      ];
}
