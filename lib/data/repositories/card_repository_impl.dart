import '../database/database_helper.dart';
import '../../domain/models/card.dart';
import '../../domain/repositories/card_repository.dart';

class CardRepositoryImpl implements CardRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  Future<List<Card>> getCardsByDeck(int deckId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT c.* FROM cards c
      INNER JOIN deck_cards dc ON c.id = dc.card_id
      WHERE dc.deck_id = ?
    ''', [deckId]);
    return List.generate(maps.length, (i) => Card.fromMap(maps[i]));
  }

  @override
  Future<Card?> getCardById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Card.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<Card> createCard(Card card, int deckId) async {
    final db = await _databaseHelper.database;

    Card createdCard = card;
    await db.transaction((txn) async {
      final cardId = await txn.insert('cards', card.toMap());
      await txn.insert('deck_cards', {
        'deck_id': deckId,
        'card_id': cardId,
      });
      createdCard = card.copyWith(id: cardId);
    });

    return createdCard;
  }

  @override
  Future<void> deleteCard(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Card> updateCard(Card card) async {
    final db = await _databaseHelper.database;
    await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
    return card;
  }

  @override
  Future<void> addCardToDeck(int cardId, int deckId) async {
    final db = await _databaseHelper.database;
    await db.insert('deck_cards', {
      'deck_id': deckId,
      'card_id': cardId,
    });
  }

  @override
  Future<void> removeCardFromDeck(int cardId, int deckId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'deck_cards',
      where: 'deck_id = ? AND card_id = ?',
      whereArgs: [deckId, cardId],
    );
  }
}
