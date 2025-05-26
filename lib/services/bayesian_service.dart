import 'dart:math';
import '../domain/models/card.dart';
import '../domain/models/user.dart';

class BayesianService {
  static List<double> bayesianPosterior(Card card, {double priorAlpha = 1.0, double priorBeta = 1.0}) {
    final ratings = card.getRatings();
    if (ratings.isEmpty) {
      return [priorAlpha, priorBeta];
    }
    
    final success = ratings.where((r) => r >= 7).length;
    final fail = ratings.length - success;
    
    return [priorAlpha + success, priorBeta + fail];
  }

  double adaptiveDecay(Card card, User userProfile, {double? baseDecay, int historyWindow = 5}) {
    final reviews = card.reviews;
    baseDecay ??= userProfile.globalDecay;
    
    if (reviews.length < 2) return baseDecay;
    
    reviews.sort((a, b) => a.reviewTime.compareTo(b.reviewTime));
    final window = reviews.take(historyWindow).toList();
    double decay = baseDecay;
    
    for (int i = 1; i < window.length; i++) {
      final t0 = window[i-1].reviewTime;
      final rating0 = window[i-1].rating;
      final t1 = window[i].reviewTime;
      final rating1 = window[i].rating;
      
      final deltaT = t1.difference(t0).inMinutes.toDouble();
      final deltaRating = rating1 - rating0;
      
      if (deltaRating < 0) {
        decay += (deltaRating.abs() * deltaT / 10000);
      } else if (deltaRating > 0 && deltaT > 10) {
        decay *= 0.97;
      }
    }
    
    if (card.matureStreak > 3) {
      decay *= 0.6;
    }
    
    return max(0.001, decay);
  }

  Map<String, dynamic> sampleNextReview(
    Card card, 
    User userProfile, 
    {double targetRecall = 0.7, int nSamples = 3000}
  ) {
    try {
      final posterior = bayesianPosterior(card);
      final alpha = posterior[0];
      final beta = posterior[1];
      final decay = adaptiveDecay(card, userProfile);
      
      final random = Random();
      final List<double> tSamples = [];
      
      for (int i = 0; i < nSamples; i++) {
        final p0 = _betaDistribution(alpha, beta, random);
        if (p0 <= targetRecall) {
          tSamples.add(1.0);
        } else {
          final t = log(p0 / targetRecall) / decay;
          tSamples.add(max(1.0, t));
        }
      }
      
      final ageFactor = 1 + (card.matureStreak ~/ 2) + 
          (card.timeSinceAdded() / (60 * 24 * 7));
      
      final adjustedSamples = tSamples.map((t) => t * ageFactor).toList();
      adjustedSamples.sort();
      
      final percentile = random.nextDouble() * 0.5 + 0.3; // 30-80%
      final index = (adjustedSamples.length * percentile).floor();
      final interval = adjustedSamples[index].toInt();
      
      return {
        'interval': interval,
        'samples': adjustedSamples,
      };
    } catch (e) {
      return {
        'interval': 1,
        'samples': [1.0],
      };
    }
  }

  static double _betaDistribution(double alpha, double beta, Random random) {
    // Simplified beta distribution sampling
    // In production, use a proper statistical library
    final x = _gammaDistribution(alpha, random);
    final y = _gammaDistribution(beta, random);
    return x / (x + y);
  }

  static double _gammaDistribution(double shape, Random random) {
    // Simplified gamma distribution sampling
    // In production, use a proper statistical library
    if (shape < 1) {
      return _gammaDistribution(shape + 1, random) * pow(random.nextDouble(), 1 / shape);
    }
    
    final d = shape - 1 / 3;
    final c = 1 / sqrt(9 * d);
    
    while (true) {
      double x, v;
      do {
        x = _normalDistribution(random);
        v = 1 + c * x;
      } while (v <= 0);
      
      v = v * v * v;
      final u = random.nextDouble();
      
      if (u < 1 - 0.331 * x * x * x * x) {
        return d * v;
      }
      
      if (log(u) < 0.5 * x * x + d * (1 - v + log(v))) {
        return d * v;
      }
    }
  }

  static double _normalDistribution(Random random) {
    // Box-Muller transform
    static double? spare;
    if (spare != null) {
      final temp = spare!;
      spare = null;
      return temp;
    }
    
    final u = random.nextDouble();
    final v = random.nextDouble();
    final mag = sqrt(-2 * log(u));
    spare = mag * cos(2 * pi * v);
    return mag * sin(2 * pi * v);
  }

  static double calculatePriority(Card card) {
    // Simple priority calculation based on review count and time since added
    final reviewCount = card.reviewCount();
    final timeSinceAdded = card.timeSinceAdded();
    
    // Cards with fewer reviews get higher priority
    final reviewFactor = 1.0 / (reviewCount + 1);
    
    // Older cards that haven't been reviewed get higher priority
    final timeFactor = timeSinceAdded / (60 * 24); // Convert to days
    
    // Calculate success rate
    final ratings = card.getRatings();
    double successRate = 0.5; // Default neutral rate
    if (ratings.isNotEmpty) {
      successRate = ratings.where((r) => r >= 7).length / ratings.length;
    }
    
    // Cards with lower success rates get higher priority
    final difficultyFactor = 1.0 - successRate;
    
    return reviewFactor * (1 + timeFactor) * (1 + difficultyFactor);
  }
}