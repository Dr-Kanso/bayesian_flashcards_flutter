import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Card;
import '../../domain/models/card.dart';
import '../../domain/repositories/card_repository.dart';
import '../../data/repositories/card_repository_impl.dart';

class CardProvider with ChangeNotifier {
  final CardRepository _cardRepository = CardRepositoryImpl();

  List<Card> _cards = [];
  bool _isLoading = false;

  List<Card> get cards => _cards;
  bool get isLoading => _isLoading;

  Future<void> loadCardsForDeck(int deckId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _cards = await _cardRepository.getCardsByDeck(deckId);
    } catch (e) {
      debugPrint('Error loading cards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCard({
    required String front,
    required String back,
    String? frontImage,
    String? backImage,
    required int deckId,
  }) async {
    try {
      final card = Card(
        front: front,
        back: back,
        frontImage: frontImage,
        backImage: backImage,
        dateAdded: DateTime.now(),
      );

      final createdCard = await _cardRepository.createCard(card, deckId);
      _cards.add(createdCard);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating card: $e');
      rethrow;
    }
  }

  Future<void> deleteCard(int cardId) async {
    try {
      await _cardRepository.deleteCard(cardId);
      _cards.removeWhere((card) => card.id == cardId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting card: $e');
      rethrow;
    }
  }

  Future<void> updateCard(Card card) async {
    try {
      final updatedCard = await _cardRepository.updateCard(card);
      final index = _cards.indexWhere((c) => c.id == card.id);
      if (index != -1) {
        _cards[index] = updatedCard;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating card: $e');
      rethrow;
    }
  }
}
