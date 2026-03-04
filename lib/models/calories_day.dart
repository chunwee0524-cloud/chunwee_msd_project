class CaloriesDay {
  final String day; // yyyy-mm-dd
  final int totalCalories;

  const CaloriesDay({
    required this.day,
    required this.totalCalories,
  });

  Map<String, dynamic> toMap() => {
    'day': day,
    'totalCalories': totalCalories,
  };

  factory CaloriesDay.fromMap(Map<String, dynamic> map) {
    return CaloriesDay(
      day: map['day'] as String,
      totalCalories: map['totalCalories'] as int,
    );
  }
}