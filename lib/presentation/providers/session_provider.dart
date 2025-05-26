import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/deck.dart';
import '../../domain/models/session.dart';
import '../../domain/models/user.dart';
import '../../domain/models/card.dart' as card_model;
import '../../data/repositories/card_repository_impl.dart';
import '../../services/scheduler_service.dart';
import 'dart:async';

class SessionProvider with ChangeNotifier {
  final CardRepositoryImpl _cardRepository = CardRepositoryImpl();

  Session? _currentSession;
  card_model.Card? _currentCard;
  bool _showBack = false;
  int _rating = 10;
  SchedulerService? _scheduler;
  User? _currentUser;

  // Timer functionality
  int _timer = 60;
  bool _isTimerRunning = false;
  Timer? _timerInstance;
  bool _showTimerModal = false;

  bool get isReviewActive => _currentSession != null;
  Session? get currentSession => _currentSession;
  card_model.Card? get currentCard => _currentCard;
  bool get showBack => _showBack;
  int get rating => _rating;
  int get timer => _timer;
  bool get isTimerRunning => _isTimerRunning;
  bool get showTimerModal => _showTimerModal;

  Future<void> startSession(Deck deck) async {
    try {
      // Create session via API call (similar to React implementation)
      _currentSession = Session(
        id: const Uuid().v4(),
        name: 'Session ${DateTime.now().toString()}',
        userId: 1,
        deckId: deck.id!,
        startTime: DateTime.now(),
      );

      // Load cards and create scheduler
      final cards = await _cardRepository.getCardsByDeck(deck.id!);
      if (cards.isEmpty) {
        throw Exception('No cards in deck');
      }

      _currentUser = const User(id: 1, username: 'default');
      _scheduler = SchedulerService(userProfile: _currentUser!, cards: cards);

      // Get first card
      await _getNextCard();
      _resetTimer();
      _startTimer(); // Auto-start timer
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting session: $e');
      rethrow;
    }
  }

  Future<void> _getNextCard() async {
    if (_scheduler == null) return;

    _currentCard = _scheduler!.selectNextCard();
    _showBack = false;
    _rating = 10;
  }

  void showCardBack() {
    _showBack = true;
    _stopTimer();
    notifyListeners();
  }

  void updateRating(int newRating) {
    _rating = newRating;
    notifyListeners();
  }

  Future<void> submitReview() async {
    if (_currentCard == null || _currentSession == null) return;

    try {
      // Add review logic here (would need review repository)
      // For now, just move to next card
      await _getNextCard();
      _resetTimer();
      _startTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('Error submitting review: $e');
    }
  }

  void endSession() {
    _currentSession = null;
    _currentCard = null;
    _scheduler = null;
    _stopTimer();
    notifyListeners();
  }

  // Timer methods
  void _resetTimer() {
    _timer = 60;
    _showTimerModal = false;
  }

  void _startTimer() {
    _isTimerRunning = true;
    _timerInstance = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timer > 0) {
        _timer--;
        notifyListeners();
      } else {
        _stopTimer();
        _showTimerModal = true;
        notifyListeners();
      }
    });
  }

  void _stopTimer() {
    _isTimerRunning = false;
    _timerInstance?.cancel();
    _timerInstance = null;
  }

  void toggleTimer() {
    if (_isTimerRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
    notifyListeners();
  }

  void dismissTimerModal() {
    _showTimerModal = false;
    notifyListeners();
  }
}
