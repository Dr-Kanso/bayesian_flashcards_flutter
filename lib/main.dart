import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/database/database_helper.dart';
import 'presentation/providers/deck_provider.dart';
import 'presentation/providers/card_provider.dart';
import 'presentation/providers/review_provider.dart';
import 'presentation/providers/session_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  await DatabaseHelper().database;
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeckProvider()),
        ChangeNotifierProvider(create: (_) => CardProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: const BayesianFlashcardsApp(),
    ),
  );
}
