class DiaryEntry {
  final int? id;
  final String imagePath;
  final String? comment;
  final int createdAt;

  DiaryEntry({
    this.id,
    required this.imagePath,
    this.comment,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'imagePath': imagePath,
    'comment': comment,
    'createdAt': createdAt,
  };

  static DiaryEntry fromMap(Map<String, Object?> map) => DiaryEntry(
    id: map['id'] as int?,
    imagePath: map['imagePath'] as String,
    comment: map['comment'] as String?,
    createdAt: (map['createdAt'] as num).toInt(),
  );
}