import 'review.dart';

class Card {
  final int? id;
  final String front;
  final String back;
  final String? frontImage;
  final String? backImage;
  final String cardType;
  final DateTime dateAdded;
  final int matureStreak;
  final DateTime? lastWrong;
  final bool isMature;
  List<Review> reviews;

  Card({
    this.id,
    required this.front,
    required this.back,
    this.frontImage,
    this.backImage,
    this.cardType = 'Basic',
    required this.dateAdded,
    this.matureStreak = 0,
    this.lastWrong,
    this.isMature = false,
    this.reviews = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'front_image': frontImage,
      'back_image': backImage,
      'card_type': cardType,
      'date_added': dateAdded.toIso8601String(),
      'mature_streak': matureStreak,
      'last_wrong': lastWrong?.toIso8601String(),
      'is_mature': isMature ? 1 : 0,
    };
  }

  factory Card.fromMap(Map<String, dynamic> map) {
    return Card(
      id: map['id'],
      front: map['front'],
      back: map['back'],
      frontImage: map['front_image'],
      backImage: map['back_image'],
      cardType: map['card_type'] ?? 'Basic',
      dateAdded: DateTime.parse(map['date_added']),
      matureStreak: map['mature_streak'] ?? 0,
      lastWrong:
          map['last_wrong'] != null ? DateTime.parse(map['last_wrong']) : null,
      isMature: (map['is_mature'] ?? 0) == 1,
    );
  }

  List<int> getRatings() {
    return reviews.map((r) => r.rating).toList();
  }

  int reviewCount() => reviews.length;

  double timeSinceAdded() {
    return DateTime.now().difference(dateAdded).inMinutes.toDouble();
  }

  Card copyWith({
    int? id,
    String? front,
    String? back,
    String? frontImage,
    String? backImage,
    String? cardType,
    DateTime? dateAdded,
    int? matureStreak,
    DateTime? lastWrong,
    bool? isMature,
    List<Review>? reviews,
  }) {
    return Card(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      frontImage: frontImage ?? this.frontImage,
      backImage: backImage ?? this.backImage,
      cardType: cardType ?? this.cardType,
      dateAdded: dateAdded ?? this.dateAdded,
      matureStreak: matureStreak ?? this.matureStreak,
      lastWrong: lastWrong ?? this.lastWrong,
      isMature: isMature ?? this.isMature,
      reviews: reviews ?? this.reviews,
    );
  }
}
