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
  });

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
      };

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
      );
}
