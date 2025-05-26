import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models/deck.dart';
import '../providers/deck_provider.dart';
import '../providers/card_provider.dart';
import '../widgets/card/card_editor.dart';

class AddCardPage extends StatelessWidget {
  const AddCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Card'),
      ),
      body: Consumer2<DeckProvider, CardProvider>(
        builder: (context, deckProvider, cardProvider, child) {
          return Column(
            children: [
              // Deck selector
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<Deck>(
                  value: deckProvider.selectedDeck,
                  decoration: const InputDecoration(
                    labelText: 'Select a deck',
                    border: OutlineInputBorder(),
                  ),
                  items: deckProvider.decks.map((deck) {
                    return DropdownMenuItem(
                      value: deck,
                      child: Text(deck.name),
                    );
                  }).toList(),
                  onChanged: (deck) {
                    if (deck != null) {
                      deckProvider.selectDeck(deck);
                    }
                  },
                ),
              ),

              // Card editor
              if (deckProvider.selectedDeck != null)
                Expanded(
                  child: CardEditor(
                    onSave: (front, back, frontImage, backImage) async {
                      await cardProvider.createCard(
                        front: front,
                        back: back,
                        frontImage: frontImage,
                        backImage: backImage,
                        deckId: deckProvider.selectedDeck!.id!,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Card added successfully!')),
                        );
                      }
                    },
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text(
                      'Please select a deck first',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
