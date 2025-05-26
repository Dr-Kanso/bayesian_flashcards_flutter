import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

class BayesianFlashcardsApp extends StatelessWidget {
  const BayesianFlashcardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bayesian Flashcards',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2496DC),
        scaffoldBackgroundColor: const Color(0xFF2F2F31),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF373737),
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardTheme(
          color: Color(0xFF373737),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2496DC),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF373737),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF484848)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF2496DC)),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
