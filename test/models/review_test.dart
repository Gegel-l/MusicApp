import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/review.dart';

void main() {
  group('Review Model Tests', () {
    test('Review should be created correctly', () {
      // Arrange
      final date = DateTime(2024, 1, 15);

      // Act
      final review = Review(
        author: 'Иван',
        text: 'Отличный товар!',
        rating: 5.0,
        date: date,
        uid: 'user123',
      );

      // Assert
      expect(review.author, 'Иван');
      expect(review.text, 'Отличный товар!');
      expect(review.rating, 5.0);
      expect(review.date, date);
      expect(review.uid, 'user123');
    });

    test('Review should be created without uid', () {
      // Arrange
      final date = DateTime(2024, 1, 15);

      // Act
      final review = Review(
        author: 'Петр',
        text: 'Хороший инструмент',
        rating: 4.0,
        date: date,
      );

      // Assert
      expect(review.uid, null);
    });

    test('Review should be converted to map', () {
      // Arrange
      final date = DateTime(2024, 1, 15);
      final review = Review(
        author: 'Иван',
        text: 'Отличный товар!',
        rating: 5.0,
        date: date,
        uid: 'user123',
      );

      // Act
      final map = review.toMap();

      // Assert
      expect(map['author'], 'Иван');
      expect(map['text'], 'Отличный товар!');
      expect(map['rating'], 5.0);
      expect(map['date'], date.millisecondsSinceEpoch);
      expect(map['uid'], 'user123');
    });

    test('Review should be created from map', () {
      // Arrange
      final date = DateTime(2024, 1, 15);
      final map = {
        'author': 'Иван',
        'text': 'Отличный товар!',
        'rating': 5.0,
        'date': date.millisecondsSinceEpoch,
      };

      // Act
      final review = Review.fromMap(map);

      // Assert
      expect(review.author, 'Иван');
      expect(review.text, 'Отличный товар!');
      expect(review.rating, 5.0);
      expect(review.date, date);
    });

    test('Review should handle empty author', () {
      // Arrange
      final map = {
        'author': '',
        'text': 'Текст отзыва',
        'rating': 3.0,
        'date': DateTime.now().millisecondsSinceEpoch,
      };

      // Act
      final review = Review.fromMap(map);

      // Assert
      expect(review.author, '');
    });

    test('Review rating should be between 0 and 5', () {
      // Arrange
      final date = DateTime.now();

      // Act & Assert
      final review1 = Review(author: 'Test', text: 'Text', rating: 0.0, date: date);
      expect(review1.rating, 0.0);

      final review2 = Review(author: 'Test', text: 'Text', rating: 5.0, date: date);
      expect(review2.rating, 5.0);

      final review3 = Review(author: 'Test', text: 'Text', rating: 2.5, date: date);
      expect(review3.rating, 2.5);
    });
  });
}
