import 'dart:math';
import '../domain/models/card.dart';
import '../domain/models/user.dart';
import '../domain/models/review.dart';

class BayesianService {
  /// Calculate Bayesian posterior parameters for a card's success rate
  static Map<String, double> bayesianPosterior(Card card, {double priorAlpha = 1.0, double priorBeta = 1.0}) {
    final ratings = card.getRatings();
    if (ratings.isEmpty) {
      return {'alpha': priorAlpha, 'beta': priorBeta};
    }
    
    final success = ratings.where((r) => r >= 7).length;
    final fail = ratings.where((r) => r < 7).length;
    
    return {
      'alpha': priorAlpha + success,
      'beta': priorBeta + fail,
    };
  }

  /// Calculate adaptive decay rate for a card based on review history
  static double adaptiveDecay(Card card, User user, {double? baseDecay, int historyWindow = 5}) {
    baseDecay ??= user.globalDecay;
    final reviews = card.reviews;
    
    if (reviews.length < 2) {
      return baseDecay;
    }

    // Sort reviews by timestamp and take the most recent ones
    final sortedReviews = List<Review>.from(reviews)..sort((a, b) => a.reviewTime.compareTo(b.reviewTime));
    final window = sortedReviews.length > historyWindow 
        ? sortedReviews.sublist(sortedReviews.length - historyWindow)
        : sortedReviews;

    double decay = baseDecay;

    for (int i = 1; i < window.length; i++) {
      final t0 = window[i - 1].reviewTime;
      final rating0 = window[i - 1].rating;
      final t1 = window[i].reviewTime;
      final rating1 = window[i].rating;
      
      final deltaT = t1.difference(t0).inMinutes.toDouble();
      final deltaRating = rating1 - rating0;
      
      if (deltaRating < 0) {
        decay += (deltaRating.abs() * deltaT) / 10000;
      } else if (deltaRating > 0 && deltaT > 10) {
        decay *= 0.97;
      }
    }

    // Reward for maturity streak
    if (card.matureStreak > 3) {
      decay *= 0.6;
    }

    return max(0.001, decay);
  }

  /// Sample next review interval using Bayesian approach
  static Map<String, dynamic> sampleNextReview(Card card, User user, {double targetRecall = 0.7, int nSamples = 3000}) {
    try {
      final posterior = bayesianPosterior(card);
      final alpha = posterior['alpha']!;
      final beta = posterior['beta']!;
      final decay = adaptiveDecay(card, user);

      // Generate beta distribution samples
      final p0Samples = _generateBetaSamples(alpha, beta, nSamples);
      final tSamples = <double>[];

      for (final p0 in p0Samples) {
        if (p0 <= targetRecall) {
          tSamples.add(1);
        } else {
          final t = log(p0 / targetRecall) / decay;
          tSamples.add(max(1, t));
        }
      }

      // Apply age factor
      try {
        final matureStreak = card.matureStreak;
        final timeSince = card.timeSinceAdded();
        final ageFactor = 1 + (matureStreak / 2) + (timeSince / (60 * 24 * 7));
        
        for (int i = 0; i < tSamples.length; i++) {
          tSamples[i] *= ageFactor;
        }
      } catch (e) {
        // Continue without age factor if calculation fails
      }

      // Get interval from percentile
      tSamples.sort();
      final percentile = Random().nextDouble() * 0.5 + 0.3; // 30-80th percentile
      final index = (tSamples.length * percentile).floor().clamp(0, tSamples.length - 1);
      final interval = tSamples[index].round();

      return {
        'interval': interval,
        'samples': tSamples,
        'alpha': alpha,
        'beta': beta,
        'decay': decay,
      };
    } catch (e) {
      return {
        'interval': 1,
        'samples': [1.0],
        'alpha': 1.0,
        'beta': 1.0,
        'decay': 0.03,
      };
    }
  }

  /// Generate samples from Beta distribution using simple approximation
  static List<double> _generateBetaSamples(double alpha, double beta, int nSamples) {
    final random = Random();
    final samples = <double>[];
    
    for (int i = 0; i < nSamples; i++) {
      // Simple approximation using gamma distributions
      final x = _gammaRandom(alpha, random);
      final y = _gammaRandom(beta, random);
      samples.add(x / (x + y));
    }
    
    return samples;
  }

  /// Simple gamma distribution approximation
  static double _gammaRandom(double shape, Random random) {
    if (shape < 1) {
      return _gammaRandom(shape + 1, random) * pow(random.nextDouble(), 1.0 / shape);
    } else {
      // Marsaglia and Tsang method approximation
      final d = shape - 1.0 / 3.0;
      final c = 1.0 / sqrt(9.0 * d);
      
      while (true) {
        double x, v;
        do {
          x = _normalRandom(random);
          v = 1.0 + c * x;
        } while (v <= 0);
        
        v = v * v * v;
        final u = random.nextDouble();
        
        if (u < 1.0 - 0.0331 * x * x * x * x) {
          return d * v;
        }
        
        if (log(u) < 0.5 * x * x + d * (1.0 - v + log(v))) {
          return d * v;
        }
      }
    }
  }

  static double? _spare;

  /// Box-Muller transform for normal distribution
  static double _normalRandom(Random random) {
    if (_spare != null) {
      final temp = _spare!;
      _spare = null;
      return temp;
    }
    
    final u = random.nextDouble();
    final v = random.nextDouble();
    final mag = sqrt(-2.0 * log(u));
    _spare = mag * cos(2.0 * pi * v);
    return mag * sin(2.0 * pi * v);
  }

  /// Convert interval in minutes to human-readable text
  static String intervalToText(int minutes) {
    if (minutes < 60) {
      return "$minutes minutes";
    } else if (minutes < 1440) {
      return "${minutes ~/ 60} hours";
    } else {
      final days = minutes ~/ 1440;
      final hours = (minutes % 1440) ~/ 60;
      return hours > 0 ? "$days days, $hours hours" : "$days days";
    }
  }

  /// Get recent posterior distribution for user performance
  static Map<String, double> getRecentPosterior(User user, {int window = 30, double priorAlpha = 2, double priorBeta = 1}) {
    final history = user.getRecallHistory();
    final recent = history.length > window ? history.sublist(history.length - window) : history;
    
    final successes = recent.where((entry) => entry[1] == 1).length;
    final failures = recent.length - successes;
    
    return {
      'alpha': priorAlpha + successes,
      'beta': priorBeta + failures,
    };
  }

  /// Calculate success rate statistics
  static Map<String, double> calculateSuccessRateStats(List<double> samples) {
    if (samples.isEmpty) {
      return {'mean': 0.0, 'std': 0.0, 'p25': 0.0, 'p50': 0.0, 'p75': 0.0};
    }
    
    final sortedSamples = List<double>.from(samples)..sort();
    final mean = samples.reduce((a, b) => a + b) / samples.length;
    final variance = samples.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / samples.length;
    
    return {
      'mean': mean,
      'std': sqrt(variance),
      'p25': _percentile(sortedSamples, 0.25),
      'p50': _percentile(sortedSamples, 0.50),
      'p75': _percentile(sortedSamples, 0.75),
    };
  }

  static double _percentile(List<double> sortedList, double percentile) {
    final index = (sortedList.length * percentile).floor().clamp(0, sortedList.length - 1);
    return sortedList[index];
  }

  static double calculatePriority(Card card) {
    // Calculate priority based on card characteristics
    double priority = 0.0;
    
    final reviewCount = card.reviewCount();
    final now = DateTime.now();
    
    // Higher priority for cards that haven't been reviewed
    if (reviewCount == 0) {
      priority += 10.0;
    }
    
    // Higher priority for non-mature cards
    if (!card.isMature) {
      priority += 5.0;
    }
    
    // Higher priority for cards that were recently wrong
    if (card.lastWrong != null) {
      final hoursSinceWrong = now.difference(card.lastWrong!).inHours;
      if (hoursSinceWrong < 48) {
        priority += 8.0 - (hoursSinceWrong / 6.0); // Decreasing priority over 48 hours
      }
    }
    
    // Higher priority for cards with lower mature streak
    priority += (10 - card.matureStreak) * 0.5;
    
    // Time since last review factor
    if (card.reviews.isNotEmpty) {
      final lastReview = card.reviews.last.timestamp;
      final hoursSinceReview = now.difference(lastReview).inHours;
      priority += (hoursSinceReview / 24.0); // Increase priority over time
    }
    
    return priority.clamp(0.0, 20.0); // Clamp to reasonable range
  }
}
