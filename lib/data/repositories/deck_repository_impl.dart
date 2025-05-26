import '../../core/database/database_helper.dart';
import '../../domain/models/deck.dart';
import '../../domain/repositories/deck_repository.dart';

class DeckRepositoryImpl implements DeckRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  Future<List<Deck>> getAllDecks() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('decks');
    return List.generate(maps.length, (i) => Deck.fromMap(maps[i]));
  }

  @override
  Future<Deck?> getDeckById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'decks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Deck.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<Deck?> getDeckByName(String name) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'decks',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (maps.isNotEmpty) {
      return Deck.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<Deck> createDeck(Deck deck) async {
    final db = await _databaseHelper.database;
    final id = await db.insert('decks', deck.toMap());
    return deck.copyWith(id: id);
  }

  @override
  Future<void> deleteDeck(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('decks', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Deck> updateDeck(Deck deck) async {
    final db = await _databaseHelper.database;
    await db.update(
      'decks',
      deck.toMap(),
      where: 'id = ?',
      whereArgs: [deck.id],
    );
    return deck;
  }
}
