import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/deck.dart';
import '../../domain/models/session.dart';
import '../../domain/models/user.dart';
import '../../domain/models/card.dart' as card_model;
import '../../domain/models/review.dart';
import '../../data/repositories/card_repository_impl.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../services/scheduler_service.dart';
import '../../services/bayesian_service.dart';
import 'dart:async';

class SessionProvider with ChangeNotifier {
  final CardRepositoryImpl _cardRepository = CardRepositoryImpl();
  final ReviewRepositoryImpl _reviewRepository = ReviewRepositoryImpl();

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

  // Performance tracking
  int _sessionReviews = 0;
  int _sessionSuccesses = 0;
  DateTime? _cardStartTime;

  bool get isReviewActive => _currentSession != null;
  Session? get currentSession => _currentSession;
  card_model.Card? get currentCard => _currentCard;
  bool get showBack => _showBack;
  int get rating => _rating;
  int get timer => _timer;
  bool get isTimerRunning => _isTimerRunning;
  bool get showTimerModal => _showTimerModal;
  int get sessionReviews => _sessionReviews;
  double get sessionSuccessRate => _sessionReviews > 0 ? _sessionSuccesses / _sessionReviews : 0.0;

  Future<void> startSession(Deck deck) async {
    try {
      // Load cards first to check if deck has any cards
      final cards = await _cardRepository.getCardsByDeck(deck.id!);
      if (cards.isEmpty) {
        debugPrint('Cannot start session: No cards in deck "${deck.name}"');
        return;
      }

      // Create session
      _currentSession = Session(
        id: const Uuid().v4(),
        name: 'Session ${DateTime.now().toString()}',
        userId: 1,
        deckId: deck.id!,
        startTime: DateTime.now(),
      );

      // Load/create user with enhanced properties
      _currentUser = const User(
        id: 1,
        username: 'default',
        globalDecay: 0.03,
        pomodoroLength: 25,
        breakLength: 5,
      );

      // Initialize scheduler with Bayesian backend
      _scheduler = SchedulerService(userProfile: _currentUser!, cards: cards);

      // Reset session counters
      _sessionReviews = 0;
      _sessionSuccesses = 0;

      // Get first card
      await _getNextCard();
      
      // Start session timer only once
      _resetTimer();
      _startTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('Error starting session: $e');
      _cleanup();
      rethrow;
    }
  }

  Future<void> _getNextCard() async {
    if (_scheduler == null) return;

    _currentCard = _scheduler!.selectNextCard();
    _showBack = false;
    _rating = 10;
    _cardStartTime = DateTime.now();
    notifyListeners();
  }

  void showCardBack() {
    _showBack = true;
    // Don't stop timer when showing card back - keep it running for the session
    notifyListeners();
  }

  void updateRating(int newRating) {
    _rating = newRating;
    notifyListeners();
  }

  Future<void> submitReview() async {
    if (_currentCard == null || _currentSession == null || _scheduler == null || _currentUser == null) {
      return;
    }

    try {
      // Calculate response time
      final responseTime = _cardStartTime != null 
          ? DateTime.now().difference(_cardStartTime!).inSeconds 
          : 0;

      // Create and save review
      final review = Review(
        cardId: _currentCard!.id!,
        userId: _currentUser!.id,
        sessionId: _currentSession!.id,
        rating: _rating,
        reviewTime: DateTime.now(),
        responseTime: responseTime,
      );

      await _reviewRepository.createReview(review);

      // Update session statistics
      _sessionReviews++;
      if (_rating >= 7) {
        _sessionSuccesses++;
      }

      // Update user's recall history using Bayesian analysis
      final prediction = BayesianService.sampleNextReview(_currentCard!, _currentUser!);
      final interval = prediction['interval'] as int;
      final success = _rating >= 7;
      
      _currentUser = _currentUser!.addRecall(interval, success);

      // Get next card
      final nextCard = _scheduler!.selectNextCard();

      if (nextCard != null) {
        _currentCard = nextCard;
        _showBack = false;
        _rating = 10;
        _cardStartTime = DateTime.now();
        // Don't reset timer - keep session timer running
        notifyListeners();
      } else {
        debugPrint('No more cards available, ending session');
        endSession();
      }
    } catch (e) {
      debugPrint('Error submitting review: $e');
    }
  }

  void endSession() {
    _cleanup();
    notifyListeners();
  }

  void _cleanup() {
    _currentSession = null;
    _currentCard = null;
    _scheduler = null;
    _currentUser = null;
    _sessionReviews = 0;
    _sessionSuccesses = 0;
    _cardStartTime = null;
    _stopTimer();
  }

  // Timer methods
  void _resetTimer() {
    _timer = _currentUser?.pomodoroLength ?? 25;
    _timer *= 60; // Convert to seconds
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

  Future<List<Session>> getSessions() async {
    try {
      // Fetch all sessions from the repository
      return await _reviewRepository.getSessions();
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      return [];
    }
  }
}
