import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/rating_model.dart';

class RatingProvider with ChangeNotifier {
  List<Rating> _ratings = [];
  bool _isLoading = false;

  List<Rating> get ratings => _ratings;
  bool get isLoading => _isLoading;

  Future<void> loadRatings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final ratingsJson = prefs.getString('ratings') ?? '[]';
      _ratings = (json.decode(ratingsJson) as List)
          .map((r) => Rating.fromJson(r))
          .toList();
    } catch (e) {
      debugPrint('Error loading ratings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRating(Rating rating) async {
    try {
      _ratings.add(rating);
      await _saveRatings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding rating: $e');
    }
  }

  double getWorkerAverageRating(String workerId) {
    final workerRatings = _ratings.where((r) => r.workerId == workerId).toList();
    if (workerRatings.isEmpty) return 0.0;
    
    final sum = workerRatings.fold(0, (sum, rating) => sum + rating.rating);
    return sum / workerRatings.length;
  }

  List<Rating> getWorkerRatings(String workerId) {
    return _ratings.where((r) => r.workerId == workerId).toList();
  }

  bool hasJobBeenRated(String jobId) {
    return _ratings.any((r) => r.jobId == jobId);
  }

  Future<void> _saveRatings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ratings', json.encode(_ratings.map((r) => r.toJson()).toList()));
  }
}