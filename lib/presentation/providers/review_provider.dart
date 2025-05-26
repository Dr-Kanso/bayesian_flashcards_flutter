import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/review_repository_impl.dart';
import '../../domain/models/review.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewRepositoryImpl _reviewRepository = ReviewRepositoryImpl();

  List<Review> _reviews = [];
  bool _isLoading = false;

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;

  Future<void> loadReviews() async {
    _isLoading = true;
    notifyListeners();

    try {
      _reviews = await _reviewRepository.getAllReviews();
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReview(Review review) async {
    try {
      final createdReview = await _reviewRepository.createReview(review);
      _reviews.add(createdReview);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding review: $e');
    }
  }
}
