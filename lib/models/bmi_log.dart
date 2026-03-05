class BmiLog {
  final int? id;
  final String? name; // store owner name at the time
  final double heightCm;
  final double weightKg;
  final double bmi;
  final int createdAt; // millisecondsSinceEpoch

  BmiLog({
    this.id,
    this.name,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    required this.createdAt,
  });

  // ✅ MUST match DB column names: height, weight, createdAt
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'height': heightCm,
      'weight': weightKg,
      'bmi': bmi,
      'createdAt': createdAt, // stored as INTEGER
    };
  }

  // ✅ Tolerant parsing (works even if createdAt is TEXT in old DB)
  factory BmiLog.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAt'];

    int createdAtMs;
    if (rawCreatedAt is int) {
      createdAtMs = rawCreatedAt;
    } else if (rawCreatedAt is num) {
      createdAtMs = rawCreatedAt.toInt();
    } else if (rawCreatedAt is String) {
      final asInt = int.tryParse(rawCreatedAt);
      if (asInt != null) {
        createdAtMs = asInt;
      } else {
        // try parse as DateTime string
        final dt = DateTime.tryParse(rawCreatedAt);
        createdAtMs = dt?.millisecondsSinceEpoch ?? 0;
      }
    } else {
      createdAtMs = 0;
    }

    return BmiLog(
      id: map['id'] as int?,
      name: map['name'] as String?,
      heightCm: (map['height'] as num).toDouble(),
      weightKg: (map['weight'] as num).toDouble(),
      bmi: (map['bmi'] as num).toDouble(),
      createdAt: createdAtMs,
    );
  }
}