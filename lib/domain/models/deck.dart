class Deck {
  final int? id;
  final String name;
  final DateTime dateCreated;
  final String? description;

  const Deck({
    this.id,
    required this.name,
    required this.dateCreated,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'date_created': dateCreated.toIso8601String(),
      'description': description,
    };
  }

  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'],
      name: map['name'],
      dateCreated: DateTime.parse(map['date_created']),
      description: map['description'],
    );
  }

  Deck copyWith({
    int? id,
    String? name,
    DateTime? dateCreated,
    String? description,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      dateCreated: dateCreated ?? this.dateCreated,
      description: description ?? this.description,
    );
  }
}
