import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _databaseName = 'flashcards.db';
  static const int _databaseVersion = 1;

  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        recall_history TEXT DEFAULT '[]',
        global_decay REAL DEFAULT 0.03,
        pomodoro_length INTEGER DEFAULT 25,
        active_session_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        date_created TEXT NOT NULL
      )
    ''');

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

    await db.execute('''
      CREATE TABLE deck_cards (
        deck_id INTEGER,
        card_id INTEGER,
        FOREIGN KEY (deck_id) REFERENCES decks (id),
        FOREIGN KEY (card_id) REFERENCES cards (id),
        PRIMARY KEY (deck_id, card_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        deck_id INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (deck_id) REFERENCES decks (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER NOT NULL,
        session_id TEXT,
        timestamp TEXT NOT NULL,
        rating INTEGER NOT NULL,
        FOREIGN KEY (card_id) REFERENCES cards (id),
        FOREIGN KEY (session_id) REFERENCES sessions (id)
      )
    ''');

    // Create default user
    await db.insert('users', {
      'username': 'default',
      'recall_history': '[]',
      'global_decay': 0.03,
      'pomodoro_length': 25,
    });
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
