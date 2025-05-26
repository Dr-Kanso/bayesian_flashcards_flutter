import 'package:flutter/material.dart';
import '../../../domain/models/deck.dart';

class DeckGrid extends StatelessWidget {
  final List<Deck> decks;
  final Deck? selectedDeck;
  final Function(Deck) onDeckSelected;
  final VoidCallback onCreateDeck;

  const DeckGrid({
    super.key,
    required this.decks,
    required this.selectedDeck,
    required this.onDeckSelected,
    required this.onCreateDeck,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: decks.length + 1, // +1 for the "Add Deck" tile
        itemBuilder: (context, index) {
          if (index == decks.length) {
            // Add deck tile
            return GestureDetector(
              onTap: onCreateDeck,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF373737),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                    width: 2,
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add Deck',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final deck = decks[index];
          final isSelected = selectedDeck?.id == deck.id;

          return GestureDetector(
            onTap: () => onDeckSelected(deck),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2496DC).withValues(alpha: 0.2)
                    : const Color(0xFF373737),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? const Color(0xFF2496DC) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.library_books,
                          color: isSelected
                              ? const Color(0xFF2496DC)
                              : Colors.white,
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF2496DC),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      deck.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected ? const Color(0xFF2496DC) : Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      'Created: ${deck.dateCreated.day}/${deck.dateCreated.month}/${deck.dateCreated.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
