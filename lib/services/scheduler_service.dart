import 'dart:math';
import '../domain/models/card.dart' as card_model;
import '../domain/models/user.dart';
import 'bayesian_service.dart';

class SchedulerService {
  final User userProfile;
  final List<card_model.Card> cards;
  final Random _random = Random();
  final Map<int, int> _cardReviewCounts = {};

  SchedulerService({
    required this.userProfile,
    required this.cards,
  }) {
    // Initialize review counts for session management
    for (final card in cards) {
      _cardReviewCounts[card.id!] = 0;
    }
  }

  card_model.Card? selectNextCard({
    int backlogLimit = 50,
    int maxReviewsPerCard = 2,
  }) {
    final urgents = <card_model.Card>[];
    final news = <card_model.Card>[];
    final matures = <card_model.Card>[];

    for (final card in cards) {
      try {
        // Skip if we've already reviewed this card enough times this session
        if (_cardReviewCounts[card.id!]! >= maxReviewsPerCard) {
          continue;
        }

        final reviewCount = card.reviewCount();

        if (reviewCount == 0) {
          news.add(card);
        } else if (!card.isMature ||
            (card.lastWrong != null &&
                DateTime.now().difference(card.lastWrong!).inHours < 48)) {
          urgents.add(card);
        } else {
          matures.add(card);
        }
      } catch (e) {
        // Add to news by default if there's an error
        news.add(card);
      }
    }

    // Shuffle each category
    urgents.shuffle(_random);
    news.shuffle(_random);
    matures.shuffle(_random);

    // Create study queue with priority: urgent -> new -> mature
    final toStudy = <card_model.Card>[];
    toStudy.addAll(urgents.take(backlogLimit));
    toStudy.addAll(news.take(3));
    toStudy.addAll(matures.take(5));

    if (toStudy.length > backlogLimit) {
      toStudy.removeRange(backlogLimit, toStudy.length);
    }

    if (toStudy.isNotEmpty) {
      final selectedCard = toStudy[_random.nextInt(toStudy.length)];
      _cardReviewCounts[selectedCard.id!] = _cardReviewCounts[selectedCard.id!]! + 1;
      return selectedCard;
    }

    // Fallback: find any remaining cards
    final remaining = cards.where((c) => _cardReviewCounts[c.id!]! < maxReviewsPerCard).toList();
    if (remaining.isNotEmpty) {
      final selectedCard = remaining[_random.nextInt(remaining.length)];
      _cardReviewCounts[selectedCard.id!] = _cardReviewCounts[selectedCard.id!]! + 1;
      return selectedCard;
    }

    // Last resort: return any card
    if (cards.isNotEmpty) {
      return cards[_random.nextInt(cards.length)];
    }

    return null;
  }

  List<card_model.Card> getReviewQueue({int limit = 10}) {
    final cardPriorities = cards.map((card) {
      return {
        'card': card,
        'priority': BayesianService.calculatePriority(card),
      };
    }).toList();

    cardPriorities.sort(
        (a, b) => (b['priority'] as double).compareTo(a['priority'] as double));

    return cardPriorities
        .take(limit)
        .map((item) => item['card'] as card_model.Card)
        .toList();
  }

  void resetSessionCounts() {
    for (final key in _cardReviewCounts.keys) {
      _cardReviewCounts[key] = 0;
    }
  }
}
