import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/cart_item.dart';
import 'package:flutter_application_1/models/product.dart';

void main() {
  group('CartItem Model Tests', () {
    late Product testProduct;

    setUp(() {
      testProduct = const Product(
        id: 1,
        name: 'Гитара',
        price: '50 000 ₽',
        amount: 50000.0,
        images: ['image.jpg'],
        tag: 'Хит',
        category: 'Струнные',
        description: 'Описание',
        rating: 4.5,
        specs: {},
      );
    });

    test('CartItem should be created with default values', () {
      // Act
      final cartItem = CartItem(product: testProduct);

      // Assert
      expect(cartItem.product, testProduct);
      expect(cartItem.quantity, 1);
      expect(cartItem.isSelected, true);
    });

    test('CartItem should be created with custom values', () {
      // Act
      final cartItem = CartItem(
        product: testProduct,
        quantity: 3,
        isSelected: false,
      );

      // Assert
      expect(cartItem.quantity, 3);
      expect(cartItem.isSelected, false);
    });

    test('CartItem quantity should be modifiable', () {
      // Arrange
      final cartItem = CartItem(product: testProduct);

      // Act
      cartItem.quantity = 5;

      // Assert
      expect(cartItem.quantity, 5);
    });

    test('CartItem isSelected should be modifiable', () {
      // Arrange
      final cartItem = CartItem(product: testProduct);

      // Act
      cartItem.isSelected = false;

      // Assert
      expect(cartItem.isSelected, false);
    });
  });
}
