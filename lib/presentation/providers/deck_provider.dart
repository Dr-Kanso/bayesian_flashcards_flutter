// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/deck.dart';
import '../../domain/repositories/deck_repository.dart';
import '../../data/repositories/deck_repository_impl.dart';
import 'session_provider.dart';

class DeckProvider with ChangeNotifier {
  final DeckRepository _deckRepository = DeckRepositoryImpl();

  List<Deck> _decks = [];
  Deck? _selectedDeck;
  bool _isLoading = false;

  List<Deck> get decks => _decks;
  Deck? get selectedDeck => _selectedDeck;
  bool get isLoading => _isLoading;

  Future<void> loadDecks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _decks = await _deckRepository.getAllDecks();
    } catch (e) {
      print('Error loading decks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDeck(Deck deck) {
    _selectedDeck = deck;
    notifyListeners();
  }

  Future<void> createDeck(String name) async {
    try {
      final deck = Deck(
        name: name,
        dateCreated: DateTime.now(),
      );
      final createdDeck = await _deckRepository.createDeck(deck);
      _decks.add(createdDeck);
      notifyListeners();
    } catch (e) {
      print('Error creating deck: $e');
    }
  }

  Future<void> deleteDeck(int deckId) async {
    try {
      await _deckRepository.deleteDeck(deckId);
      _decks.removeWhere((deck) => deck.id == deckId);
      if (_selectedDeck?.id == deckId) {
        _selectedDeck = null;
      }
      notifyListeners();
    } catch (e) {
      print('Error deleting deck: $e');
    }
  }

  Future<void> updateDeck(Deck deck) async {
    try {
      final updatedDeck = await _deckRepository.updateDeck(deck);
      final index = _decks.indexWhere((d) => d.id == deck.id);
      if (index != -1) {
        _decks[index] = updatedDeck;
        if (_selectedDeck?.id == deck.id) {
          _selectedDeck = updatedDeck;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error updating deck: $e');
    }
  }

  void startStudySession(BuildContext context) {
    if (_selectedDeck != null) {
      Provider.of<SessionProvider>(context, listen: false)
          .startSession(_selectedDeck!);
    }
  }
}
