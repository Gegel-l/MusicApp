import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/providers/cart_provider.dart';
import 'package:flutter_application_1/models/product.dart';

String _lid(CartProvider c, Product p) =>
    c.items.firstWhere((i) => i.product.id == p.id).lineId;

void main() {
  group('CartProvider Tests', () {
    late CartProvider cartProvider;
    late Product testProduct1;
    late Product testProduct2;

    setUp(() {
      cartProvider = CartProvider();
      testProduct1 = const Product(
        id: 1,
        name: 'Гитара',
        price: '50 000 ₽',
        amount: 50000.0,
        images: ['image1.jpg'],
        tag: 'Хит',
        category: 'Струнные',
        description: 'Описание',
        rating: 4.5,
        specs: {},
      );
      testProduct2 = const Product(
        id: 2,
        name: 'Пианино',
        price: '100 000 ₽',
        amount: 100000.0,
        images: ['image2.jpg'],
        tag: 'Новинка',
        category: 'Клавишные',
        description: 'Описание',
        rating: 5.0,
        specs: {},
      );
    });

    test('Initial state should be empty', () {
      // Assert
      expect(cartProvider.items.isEmpty, true);
      expect(cartProvider.totalCount, 0);
      expect(cartProvider.totalAmount, 0.0);
    });

    test('Add product should increase items count', () {
      // Act
      cartProvider.add(testProduct1);

      // Assert
      expect(cartProvider.items.length, 1);
      expect(cartProvider.totalCount, 1);
      expect(cartProvider.contains(testProduct1.id), true);
    });

    test('Add same product twice should increase quantity', () {
      // Act
      cartProvider.add(testProduct1);
      cartProvider.add(testProduct1);

      // Assert
      expect(cartProvider.items.length, 1);
      expect(cartProvider.totalCount, 2);
      expect(cartProvider.items.first.quantity, 2);
    });

    test('Add different products should increase items count', () {
      // Act
      cartProvider.add(testProduct1);
      cartProvider.add(testProduct2);

      // Assert
      expect(cartProvider.items.length, 2);
      expect(cartProvider.totalCount, 2);
    });

    test('Remove product should decrease items count', () {
      // Arrange
      cartProvider.add(testProduct1);

      // Act
      cartProvider.remove(_lid(cartProvider, testProduct1));

      // Assert
      expect(cartProvider.items.isEmpty, true);
      expect(cartProvider.totalCount, 0);
    });

    test('Decrement should decrease quantity', () {
      // Arrange
      cartProvider.add(testProduct1);
      cartProvider.add(testProduct1);

      // Act
      cartProvider.decrement(_lid(cartProvider, testProduct1));

      // Assert
      expect(cartProvider.items.first.quantity, 1);
      expect(cartProvider.totalCount, 1);
    });

    test('Decrement with quantity 1 should remove item', () {
      // Arrange
      cartProvider.add(testProduct1);

      // Act
      cartProvider.decrement(_lid(cartProvider, testProduct1));

      // Assert
      expect(cartProvider.items.isEmpty, true);
    });

    test('Total amount should be calculated correctly', () {
      // Act
      cartProvider.add(testProduct1); // 50000
      cartProvider.add(testProduct2); // 100000

      // Assert
      expect(cartProvider.totalAmount, 150000.0);
    });

    test('Total amount should consider quantity', () {
      // Act
      cartProvider.add(testProduct1);
      cartProvider.add(testProduct1);
      cartProvider.add(testProduct1); // 3 x 50000 = 150000

      // Assert
      expect(cartProvider.totalAmount, 150000.0);
    });

    test('Toggle select should change isSelected', () {
      // Arrange
      cartProvider.add(testProduct1);

      // Act
      cartProvider.toggleSelect(_lid(cartProvider, testProduct1));

      // Assert
      expect(cartProvider.items.first.isSelected, false);
    });

    test('Select all should select all items', () {
      // Arrange
      cartProvider.add(testProduct1);
      cartProvider.add(testProduct2);
      cartProvider.toggleSelect(_lid(cartProvider, testProduct1)); // unselect first

      // Act
      cartProvider.selectAll(true);

      // Assert
      expect(cartProvider.items.every((item) => item.isSelected), true);
      expect(cartProvider.allSelected, true);
    });

    test('Selected items should return only selected', () {
      // Arrange
      cartProvider.add(testProduct1);
      cartProvider.add(testProduct2);
      cartProvider.toggleSelect(_lid(cartProvider, testProduct1)); // unselect first

      // Act
      final selected = cartProvider.selectedItems;

      // Assert
      expect(selected.length, 1);
      expect(selected.first.product.id, testProduct2.id);
    });

    test('Selected count should count only selected items', () {
      // Arrange
      cartProvider.add(testProduct1);
      cartProvider.add(testProduct1);
      cartProvider.add(testProduct2);
      cartProvider.toggleSelect(_lid(cartProvider, testProduct1)); // unselect first (quantity 2)

      // Act
      final count = cartProvider.selectedCount;

      // Assert
      expect(count, 1); // only testProduct2
    });

    test('Clear should remove all items', () {
      // Arrange
      cartProvider.add(testProduct1);
      cartProvider.add(testProduct2);

      // Act
      cartProvider.clear();

      // Assert
      expect(cartProvider.items.isEmpty, true);
      expect(cartProvider.totalCount, 0);
    });

    test('Contains should return correct value', () {
      // Arrange
      cartProvider.add(testProduct1);

      // Assert
      expect(cartProvider.contains(testProduct1.id), true);
      expect(cartProvider.contains(testProduct2.id), false);
    });

    test('Total amount formatted should have correct format', () {
      // Arrange
      cartProvider.add(testProduct1); // 50000

      // Act
      final formatted = cartProvider.totalAmountFormatted;

      // Assert
      expect(formatted, '50 000 ₽');
    });
  });
}
