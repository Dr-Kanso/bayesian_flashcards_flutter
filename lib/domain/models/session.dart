class Session {
  final String id;
  final String name;
  final int userId;
  final int deckId;
  final DateTime startTime;
  final DateTime? endTime;

  const Session({
    required this.id,
    required this.name,
    required this.userId,
    required this.deckId,
    required this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'user_id': userId,
      'deck_id': deckId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'],
      name: map['name'],
      userId: map['user_id'],
      deckId: map['deck_id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
    );
  }

  Session copyWith({
    String? id,
    String? name,
    int? userId,
    int? deckId,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return Session(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      deckId: deckId ?? this.deckId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
