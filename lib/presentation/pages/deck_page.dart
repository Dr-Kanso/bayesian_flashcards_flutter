import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/deck.dart';
import '../providers/deck_provider.dart';
import '../widgets/deck/deck_grid.dart';

class DeckPage extends StatelessWidget {
  const DeckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeckProvider>(
      builder: (context, deckProvider, child) {
        return Column(
          children: [
            // Header with Study button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Your Decks',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: deckProvider.selectedDeck != null
                        ? () => deckProvider.startStudySession(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2496DC),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Study', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
            // Deck grid
            Expanded(
              child: DeckGrid(
                decks: deckProvider.decks,
                selectedDeck: deckProvider.selectedDeck,
                onDeckSelected: deckProvider.selectDeck,
                onCreateDeck: () =>
                    _showCreateDeckDialog(context, deckProvider),
                onDeleteDeck: (deck) =>
                    _deleteDeck(context, deckProvider, deck),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateDeckDialog(BuildContext context, DeckProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Deck'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Enter deck name'),
          onSubmitted: (name) {
            if (name.isNotEmpty) {
              provider.createDeck(name);
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _deleteDeck(
      BuildContext context, DeckProvider provider, Deck deck) async {
    try {
      await provider.deleteDeck(deck.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deck "${deck.name}" deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting deck: $e')),
        );
      }
    }
  }
}
