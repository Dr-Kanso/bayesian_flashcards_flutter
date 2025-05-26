import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize databaseFactory for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), 'flashcards.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        date_created TEXT
      )
    ''');

    // Decks table
    await db.execute('''
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        date_created TEXT NOT NULL
      )
    ''');

    // Cards table
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        front_image TEXT,
        back_image TEXT,
        card_type TEXT DEFAULT 'Basic',
        date_added TEXT NOT NULL,
        mature_streak INTEGER DEFAULT 0,
        last_wrong TEXT,
        is_mature INTEGER DEFAULT 0
      )
    ''');

    // Deck_cards junction table
    await db.execute('''
      CREATE TABLE deck_cards (
        deck_id INTEGER,
        card_id INTEGER,
        PRIMARY KEY (deck_id, card_id),
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE,
        FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
      )
    ''');

    // Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        user_id INTEGER,
        deck_id INTEGER,
        start_time TEXT NOT NULL,
        end_time TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (deck_id) REFERENCES decks (id)
      )
    ''');

    // Reviews table
    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER,
        user_id INTEGER,
        session_id TEXT,
        rating INTEGER NOT NULL,
        review_time TEXT NOT NULL,
        response_time INTEGER NOT NULL,
        FOREIGN KEY (card_id) REFERENCES cards (id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (session_id) REFERENCES sessions (id)
      )
    ''');

    // Insert default user
    await db.insert('users', {
      'id': 1,
      'username': 'default',
      'date_created': DateTime.now().toIso8601String(),
    });
  }
}
