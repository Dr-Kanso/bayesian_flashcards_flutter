import '../models/deck.dart';

abstract class DeckRepository {
  Future<List<Deck>> getAllDecks();
  Future<Deck?> getDeckById(int id);
  Future<Deck?> getDeckByName(String name);
  Future<Deck> createDeck(Deck deck);
  Future<void> deleteDeck(int id);
  Future<Deck> updateDeck(Deck deck);
}
