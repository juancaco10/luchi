// ── SightingModel ─────────────────────────────────────────────────

class SightingModel {
  final int? id;
  final double lat;
  final double lng;
  final int quantity;
  final String? notes;
  final String? photoUrl;
  final String? locationName;
  final bool isPending;
  final String createdAt;
  final String? updatedAt;
  final String? archivedAt;

  /// Corazones recibidos. En `/my-sightings` y en el feed comunitario
  /// (`GET /sightings`) lo manda el servidor; en un avistamiento recién
  /// creado offline empieza en 0.
  final int likesCount;

  /// Si el usuario actual ya le dio corazón a este avistamiento.
  final bool likedByMe;

  /// `true` para todo lo que viene de `/my-sightings` o se creó en este
  /// dispositivo; `false` solo para lo ajeno del feed comunitario
  /// (`GET /sightings`, que nunca revela de quién es). Determina si la UI
  /// puede mostrar tu nombre/avatar o debe usar el anónimo — ver
  /// `sighting_details_modal.dart`.
  final bool isMine;

  /// Solo viene informado en `/my-sightings` (es tu propio contenido, ver
  /// por qué algo tuyo no sale aún en el feed no es una fuga). En el feed
  /// comunitario todo es siempre 'approved' por construcción, así que ahí
  /// no hace falta ni se manda.
  final String moderationStatus;

  const SightingModel({
    this.id,
    required this.lat,
    required this.lng,
    required this.quantity,
    this.notes,
    this.photoUrl,
    this.locationName,
    this.isPending = false,
    required this.createdAt,
    this.updatedAt,
    this.archivedAt,
    this.likesCount = 0,
    this.likedByMe = false,
    this.isMine = true,
    this.moderationStatus = 'approved',
  });

  bool get isArchived => archivedAt != null;

  factory SightingModel.fromJson(Map<String, dynamic> json) => SightingModel(
        id: json['id'] as int?,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        quantity: json['quantity'] as int? ?? 1,
        notes: json['notes'] as String?,
        photoUrl: json['photo_url'] as String?,
        locationName: json['location_name'] as String?,
        isPending: json['is_pending'] as bool? ?? false,
        createdAt: json['created_at'] as String? ??
            DateTime.now().toIso8601String(),
        updatedAt: json['updated_at'] as String?,
        archivedAt: json['archived_at'] as String?,
        likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
        likedByMe: json['liked_by_me'] as bool? ?? false,
        // Ausente (p. ej. una fila creada offline antes de sincronizar) se
        // trata como propio: es la única interpretación posible para algo
        // que todavía no vino del servidor.
        isMine: json['is_mine'] as bool? ?? true,
        moderationStatus: json['moderation_status'] as String? ?? 'approved',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': lat,
        'lng': lng,
        'quantity': quantity,
        'notes': notes,
        'photo_url': photoUrl,
        'location_name': locationName,
        'is_pending': isPending,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'archived_at': archivedAt,
        'likes_count': likesCount,
        'liked_by_me': likedByMe,
        'is_mine': isMine,
        'moderation_status': moderationStatus,
      };

  static const _unset = Object();

  /// `archivedAt` acepta explícitamente `null` (para desarchivar) gracias
  /// al sentinel `_unset` — con un `??` normal, como en el resto de campos,
  /// nunca sería posible volver a poner el campo a `null`.
  SightingModel copyWith({
    int? id,
    double? lat,
    double? lng,
    int? quantity,
    String? notes,
    String? photoUrl,
    String? locationName,
    bool? isPending,
    String? createdAt,
    String? updatedAt,
    Object? archivedAt = _unset,
    int? likesCount,
    bool? likedByMe,
    bool? isMine,
    String? moderationStatus,
  }) =>
      SightingModel(
        id: id ?? this.id,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        quantity: quantity ?? this.quantity,
        notes: notes ?? this.notes,
        photoUrl: photoUrl ?? this.photoUrl,
        locationName: locationName ?? this.locationName,
        isPending: isPending ?? this.isPending,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        archivedAt: identical(archivedAt, _unset)
            ? this.archivedAt
            : archivedAt as String?,
        likesCount: likesCount ?? this.likesCount,
        likedByMe: likedByMe ?? this.likedByMe,
        isMine: isMine ?? this.isMine,
        moderationStatus: moderationStatus ?? this.moderationStatus,
      );
}
