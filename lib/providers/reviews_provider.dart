import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review.dart';

class ReviewsProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final Map<int, List<Review>> _cache = {};

  CollectionReference _col(int productId) =>
      _db.collection('products').doc(productId.toString()).collection('reviews');

  List<Review> getReviews(int productId) => _cache[productId] ?? [];

  Future<void> loadReviews(int productId) async {
    final snap = await _col(productId).orderBy('date', descending: true).get();
    _cache[productId] = snap.docs
        .map((d) => Review.fromMap(d.data() as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  double averageRating(int productId) {
    final list = getReviews(productId);
    if (list.isEmpty) return 0;
    return list.fold(0.0, (acc, r) => acc + r.rating) / list.length;
  }

  Future<void> addReview(int productId, Review review) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final reviewWithUid = Review(
      author: review.author,
      text: review.text,
      rating: review.rating,
      date: review.date,
      uid: uid,
    );
    await _col(productId).add(reviewWithUid.toMap());
    if (uid != null) {
      await _db.collection('users').doc(uid)
          .set({'reviewsCount': FieldValue.increment(1)}, SetOptions(merge: true));
    }
    _cache.putIfAbsent(productId, () => []);
    _cache[productId]!.insert(0, reviewWithUid);
    notifyListeners();
  }

  Future<void> updateReview(int productId, String docId, String text, double rating) async {
    await _col(productId).doc(docId).update({'text': text, 'rating': rating});
    final list = _cache[productId];
    if (list != null) {
      final i = list.indexWhere((r) => r.date.millisecondsSinceEpoch.toString() == docId);
      if (i != -1) {
        list[i] = Review(author: list[i].author, text: text, rating: rating, date: list[i].date, uid: list[i].uid);
      }
    }
    notifyListeners();
  }
}
