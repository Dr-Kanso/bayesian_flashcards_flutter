import '../database/database_helper.dart';
import '../../domain/models/review.dart';

class ReviewRepositoryImpl {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<List<Review>> getAllReviews() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('reviews');
    return List.generate(maps.length, (i) => Review.fromMap(maps[i]));
  }

  Future<Review> createReview(Review review) async {
    final db = await _databaseHelper.database;
    final id = await db.insert('reviews', review.toMap());
    return review.copyWith(id: id);
  }

  Future<List<Review>> getReviewsByCard(int cardId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reviews',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
    return List.generate(maps.length, (i) => Review.fromMap(maps[i]));
  }
}
