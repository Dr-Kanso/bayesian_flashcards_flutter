class User {
  final int id;
  final String username;
  final DateTime? dateCreated;
  final double globalDecay;

  const User({
    required this.id,
    required this.username,
    this.dateCreated,
    this.globalDecay = 0.1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'date_created': dateCreated?.toIso8601String(),
      'global_decay': globalDecay,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      dateCreated: map['date_created'] != null
          ? DateTime.parse(map['date_created'])
          : null,
      globalDecay: map['global_decay']?.toDouble() ?? 0.1,
    );
  }

  User copyWith({
    int? id,
    String? username,
    DateTime? dateCreated,
    double? globalDecay,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      dateCreated: dateCreated ?? this.dateCreated,
      globalDecay: globalDecay ?? this.globalDecay,
    );
  }
}
