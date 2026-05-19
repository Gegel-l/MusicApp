import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/product.dart';

void main() {
  group('Product Model Tests', () {
    test('Product should be created from map', () {
      // Arrange
      final map = {
        'id': 1,
        'name': 'Гитара Yamaha',
        'price': '50 000 ₽',
        'amount': 50000.0,
        'images': ['https://example.com/image1.jpg'],
        'tag': 'Хит',
        'category': 'Струнные',
        'description': 'Отличная гитара',
        'rating': 4.5,
        'specs': {'Материал': 'Дерево', 'Струны': '6'},
      };

      // Act
      final product = Product.fromMap(map);

      // Assert
      expect(product.id, 1);
      expect(product.name, 'Гитара Yamaha');
      expect(product.price, '50 000 ₽');
      expect(product.amount, 50000.0);
      expect(product.images.length, 1);
      expect(product.tag, 'Хит');
      expect(product.category, 'Струнные');
      expect(product.description, 'Отличная гитара');
      expect(product.rating, 4.5);
      expect(product.specs['Материал'], 'Дерево');
    });

    test('Product should be converted to map', () {
      // Arrange
      const product = Product(
        id: 1,
        name: 'Гитара Yamaha',
        price: '50 000 ₽',
        amount: 50000.0,
        images: ['https://example.com/image1.jpg'],
        tag: 'Хит',
        category: 'Струнные',
        description: 'Отличная гитара',
        rating: 4.5,
        specs: {'Материал': 'Дерево'},
      );

      // Act
      final map = product.toMap();

      // Assert
      expect(map['id'], 1);
      expect(map['name'], 'Гитара Yamaha');
      expect(map['price'], '50 000 ₽');
      expect(map['amount'], 50000.0);
      expect(map['category'], 'Струнные');
    });

    test('Product with empty images should work', () {
      // Arrange
      final map = {
        'id': 2,
        'name': 'Пианино',
        'price': '100 000 ₽',
        'amount': 100000.0,
        'images': <String>[],
        'tag': '',
        'category': 'Клавишные',
        'description': 'Классическое пианино',
        'rating': 5.0,
        'specs': <String, String>{},
      };

      // Act
      final product = Product.fromMap(map);

      // Assert
      expect(product.images.isEmpty, true);
      expect(product.tag.isEmpty, true);
      expect(product.specs.isEmpty, true);
    });
  });
}
