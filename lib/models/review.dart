class Review {
  final int? id;
  final int cardId;
  final int userId;
  final String sessionId;
  final int rating;
  final DateTime timestamp;
  final int responseTime;

  const Review({
    this.id,
    required this.cardId,
    required this.userId,
    required this.sessionId,
    required this.rating,
    required this.timestamp,
    required this.responseTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'card_id': cardId,
      'user_id': userId,
      'session_id': sessionId,
      'rating': rating,
      'timestamp': timestamp.toIso8601String(),
      'response_time': responseTime,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      cardId: map['card_id'],
      userId: map['user_id'],
      sessionId: map['session_id'],
      rating: map['rating'],
      timestamp: DateTime.parse(map['timestamp']),
      responseTime: map['response_time'],
    );
  }

  Review copyWith({
    int? id,
    int? cardId,
    int? userId,
    String? sessionId,
    int? rating,
    DateTime? timestamp,
    int? responseTime,
  }) {
    return Review(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      rating: rating ?? this.rating,
      timestamp: timestamp ?? this.timestamp,
      responseTime: responseTime ?? this.responseTime,
    );
  }
}
