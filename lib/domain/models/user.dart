import 'dart:convert';

class User {
  final int id;
  final String username;
  final DateTime? dateCreated;
  final double globalDecay;
  final int pomodoroLength;
  final int breakLength;
  final int sessionFatigue;
  final int focusDropCount;
  final String? activeSessionId;
  final List<List<dynamic>> recallHistory;

  const User({
    required this.id,
    required this.username,
    this.dateCreated,
    this.globalDecay = 0.03,
    this.pomodoroLength = 25,
    this.breakLength = 5,
    this.sessionFatigue = 0,
    this.focusDropCount = 0,
    this.activeSessionId,
    this.recallHistory = const [],
  });

  List<List<dynamic>> getRecallHistory() {
    return recallHistory;
  }

  User addRecall(int interval, bool success) {
    final newHistory = List<List<dynamic>>.from(recallHistory);
    newHistory.add([interval, success ? 1 : 0]);

    return copyWith(
      recallHistory: newHistory,
      globalDecay: _updateDecay(newHistory),
    );
  }

  double _updateDecay(List<List<dynamic>> history) {
    if (history.length < 10) {
      return globalDecay;
    }

    // Use the last 50 entries
    final recent = history.length > 50 ? history.sublist(history.length - 50) : history;
    final failIntervals = recent
        .where((entry) => entry[1] == 0)
        .map((entry) => entry[0] as int)
        .toList();

    if (failIntervals.isNotEmpty) {
      final avgFailInterval = failIntervals.reduce((a, b) => a + b) / failIntervals.length;
      return (0.693147 / avgFailInterval).clamp(0.001, 1.0); // ln(2) / half_life
    }

    return 0.03;
  }

  User startSession(String sessionId) {
    return copyWith(activeSessionId: sessionId);
  }

  User endSession() {
    return copyWith(activeSessionId: null);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'date_created': dateCreated?.toIso8601String(),
      'global_decay': globalDecay,
      'pomodoro_length': pomodoroLength,
      'break_length': breakLength,
      'session_fatigue': sessionFatigue,
      'focus_drop_count': focusDropCount,
      'active_session_id': activeSessionId,
      'recall_history': jsonEncode(recallHistory),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    List<List<dynamic>> history = [];
    if (map['recall_history'] != null && map['recall_history'].isNotEmpty) {
      try {
        final decoded = jsonDecode(map['recall_history']);
        if (decoded is List) {
          history = decoded.map((item) => List<dynamic>.from(item)).toList();
        }
      } catch (e) {
        // Handle parsing error gracefully
        history = [];
      }
    }

    return User(
      id: map['id'],
      username: map['username'],
      dateCreated: map['date_created'] != null ? DateTime.parse(map['date_created']) : null,
      globalDecay: map['global_decay']?.toDouble() ?? 0.03,
      pomodoroLength: map['pomodoro_length'] ?? 25,
      breakLength: map['break_length'] ?? 5,
      sessionFatigue: map['session_fatigue'] ?? 0,
      focusDropCount: map['focus_drop_count'] ?? 0,
      activeSessionId: map['active_session_id'],
      recallHistory: history,
    );
  }

  User copyWith({
    int? id,
    String? username,
    DateTime? dateCreated,
    double? globalDecay,
    int? pomodoroLength,
    int? breakLength,
    int? sessionFatigue,
    int? focusDropCount,
    String? activeSessionId,
    List<List<dynamic>>? recallHistory,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      dateCreated: dateCreated ?? this.dateCreated,
      globalDecay: globalDecay ?? this.globalDecay,
      pomodoroLength: pomodoroLength ?? this.pomodoroLength,
      breakLength: breakLength ?? this.breakLength,
      sessionFatigue: sessionFatigue ?? this.sessionFatigue,
      focusDropCount: focusDropCount ?? this.focusDropCount,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      recallHistory: recallHistory ?? this.recallHistory,
    );
  }
}
