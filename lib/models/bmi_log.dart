class BmiLog {
  final int? id;
  final String? name; // ✅ store owner name at the time
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'bmi': bmi,
      'createdAt': createdAt,
    };
  }

  factory BmiLog.fromMap(Map<String, dynamic> map) {
    return BmiLog(
      id: map['id'] as int?,
      name: map['name'] as String?,
      heightCm: (map['heightCm'] as num).toDouble(),
      weightKg: (map['weightKg'] as num).toDouble(),
      bmi: (map['bmi'] as num).toDouble(),
      createdAt: map['createdAt'] as int,
    );
  }
}