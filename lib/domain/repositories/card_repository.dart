import '../models/card.dart';

abstract class CardRepository {
  Future<List<Card>> getCardsByDeck(int deckId);
  Future<Card?> getCardById(int id);
  Future<Card> createCard(Card card, int deckId);
  Future<void> deleteCard(int id);
  Future<Card> updateCard(Card card);
  Future<void> addCardToDeck(int cardId, int deckId);
  Future<void> removeCardFromDeck(int cardId, int deckId);
}
