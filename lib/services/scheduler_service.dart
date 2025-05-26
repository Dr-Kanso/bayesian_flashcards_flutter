import 'dart:math';
import '../domain/models/card.dart' as card_model;
import '../domain/models/user.dart';
import 'bayesian_service.dart';

class SchedulerService {
  final User userProfile;
  final List<card_model.Card> cards;
  final Random _random = Random();

  SchedulerService({
    required this.userProfile,
    required this.cards,
  });

  card_model.Card? selectNextCard() {
    if (cards.isEmpty) return null;

    // Calculate priorities for all cards
    final cardPriorities = cards.map((card) {
      return {
        'card': card,
        'priority': BayesianService.calculatePriority(card),
      };
    }).toList();

    // Sort by priority (highest first)
    cardPriorities.sort(
        (a, b) => (b['priority'] as double).compareTo(a['priority'] as double));

    // Select from top 20% using weighted random selection
    final topCount = max(1, (cardPriorities.length * 0.2).round());
    final topCards = cardPriorities.take(topCount).toList();

    // Weighted random selection
    final totalWeight = topCards.fold<double>(
        0, (sum, item) => sum + (item['priority'] as double));

    if (totalWeight == 0) return topCards.first['card'] as card_model.Card;

    double randomValue = _random.nextDouble() * totalWeight;
    double cumulativeWeight = 0;

    for (final item in topCards) {
      cumulativeWeight += item['priority'] as double;
      if (randomValue <= cumulativeWeight) {
        return item['card'] as card_model.Card;
      }
    }

    return topCards.first['card'] as card_model.Card;
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
}
