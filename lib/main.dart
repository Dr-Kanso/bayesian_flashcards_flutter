import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'data/database/database_helper.dart';
import 'presentation/providers/deck_provider.dart';
import 'presentation/providers/card_provider.dart';
import 'presentation/providers/session_provider.dart';
import 'presentation/providers/review_provider.dart';
import 'data/repositories/deck_repository_impl.dart';
import 'data/repositories/card_repository_impl.dart';
import 'data/repositories/review_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final databaseHelper = DatabaseHelper();
  await databaseHelper.database;

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize repositories
  final deckRepository = DeckRepositoryImpl();
  final cardRepository = CardRepositoryImpl();
  final reviewRepository = ReviewRepositoryImpl();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DeckProvider(repository: deckRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CardProvider(repository: cardRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SessionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewProvider(repository: reviewRepository),
        ),
      ],
      child: const BayesianFlashcardsApp(),
    ),
  );
}
