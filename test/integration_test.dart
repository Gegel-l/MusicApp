import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/providers/cart_provider.dart';
import 'package:flutter_application_1/models/product.dart';

String _cartLine(CartProvider c, Product p) =>
    c.items.firstWhere((i) => i.product.id == p.id).lineId;

void main() {
  group('Integration Tests - Shopping Flow', () {
    late CartProvider cartProvider;
    late Product guitar;
    late Product piano;
    late Product drums;

    setUp(() {
      cartProvider = CartProvider();
      
      guitar = const Product(
        id: 1,
        name: 'Гитара Yamaha',
        price: '50 000 ₽',
        amount: 50000.0,
        images: ['guitar.jpg'],
        tag: 'Хит',
        category: 'Струнные',
        description: 'Акустическая гитара',
        rating: 4.5,
        specs: {'Материал': 'Дерево', 'Струны': '6'},
      );

      piano = const Product(
        id: 2,
        name: 'Пианино Casio',
        price: '100 000 ₽',
        amount: 100000.0,
        images: ['piano.jpg'],
        tag: 'Новинка',
        category: 'Клавишные',
        description: 'Цифровое пианино',
        rating: 5.0,
        specs: {'Клавиши': '88', 'Полифония': '256'},
      );

      drums = const Product(
        id: 3,
        name: 'Барабаны Roland',
        price: '80 000 ₽',
        amount: 80000.0,
        images: ['drums.jpg'],
        tag: 'Скидка',
        category: 'Ударные',
        description: 'Электронная установка',
        rating: 4.8,
        specs: {'Пэды': '5', 'Тарелки': '3'},
      );
    });

    test('Complete shopping scenario', () {
      // 1. Пользователь добавляет товары в корзину
      cartProvider.add(guitar);
      cartProvider.add(piano);
      cartProvider.add(drums);

      expect(cartProvider.items.length, 3);
      expect(cartProvider.totalCount, 3);

      // 2. Пользователь увеличивает количество гитар
      cartProvider.add(guitar);
      cartProvider.add(guitar);

      expect(cartProvider.totalCount, 5); // 3 guitars + 1 piano + 1 drums
      expect(cartProvider.items.firstWhere((i) => i.product.id == 1).quantity, 3);

      // 3. Пользователь снимает выбор с барабанов
      cartProvider.toggleSelect(_cartLine(cartProvider, drums));

      expect(cartProvider.selectedItems.length, 2);
      expect(cartProvider.selectedCount, 4); // 3 guitars + 1 piano

      // 4. Проверка общей суммы (только выбранные)
      final expectedTotal = (50000.0 * 3) + 100000.0; // 250000
      expect(cartProvider.totalAmount, expectedTotal);

      // 5. Пользователь уменьшает количество гитар
      cartProvider.decrement(_cartLine(cartProvider, guitar));

      expect(cartProvider.items.firstWhere((i) => i.product.id == 1).quantity, 2);
      expect(cartProvider.totalCount, 4);

      // 6. Пользователь удаляет пианино
      cartProvider.remove(_cartLine(cartProvider, piano));

      expect(cartProvider.items.length, 2);
      expect(cartProvider.contains(piano.id), false);

      // 7. Финальная проверка
      expect(cartProvider.totalCount, 3); // 2 guitars + 1 drums
      expect(cartProvider.selectedCount, 2); // only 2 guitars (drums unselected)
    });

    test('Add multiple items and calculate total', () {
      // Добавляем товары
      cartProvider.add(guitar);
      cartProvider.add(guitar);
      cartProvider.add(piano);

      // Проверяем общую сумму
      final expectedTotal = (50000.0 * 2) + 100000.0; // 200000
      expect(cartProvider.totalAmount, expectedTotal);
      expect(cartProvider.totalAmountFormatted, '200 000 ₽');
    });

    test('Select and unselect items affects total', () {
      // Добавляем товары
      cartProvider.add(guitar);
      cartProvider.add(piano);
      cartProvider.add(drums);

      // Все выбраны
      expect(cartProvider.totalAmount, 230000.0);

      // Снимаем выбор с пианино
      cartProvider.toggleSelect(_cartLine(cartProvider, piano));
      expect(cartProvider.totalAmount, 130000.0); // guitar + drums

      // Снимаем выбор со всех
      cartProvider.selectAll(false);
      expect(cartProvider.totalAmount, 0.0);
      expect(cartProvider.selectedItems.isEmpty, true);

      // Выбираем все обратно
      cartProvider.selectAll(true);
      expect(cartProvider.totalAmount, 230000.0);
      expect(cartProvider.allSelected, true);
    });

    test('Remove all items one by one', () {
      // Добавляем товары
      cartProvider.add(guitar);
      cartProvider.add(piano);
      cartProvider.add(drums);

      expect(cartProvider.items.length, 3);

      // Удаляем по одному
      cartProvider.remove(_cartLine(cartProvider, guitar));
      expect(cartProvider.items.length, 2);

      cartProvider.remove(_cartLine(cartProvider, piano));
      expect(cartProvider.items.length, 1);

      cartProvider.remove(_cartLine(cartProvider, drums));
      expect(cartProvider.items.isEmpty, true);
      expect(cartProvider.totalCount, 0);
      expect(cartProvider.totalAmount, 0.0);
    });

    test('Clear cart removes everything', () {
      // Добавляем товары
      cartProvider.add(guitar);
      cartProvider.add(piano);
      cartProvider.add(drums);
      cartProvider.add(guitar);

      expect(cartProvider.items.length, 3);
      expect(cartProvider.totalCount, 4);

      // Очищаем корзину
      cartProvider.clear();

      expect(cartProvider.items.isEmpty, true);
      expect(cartProvider.totalCount, 0);
      expect(cartProvider.totalAmount, 0.0);
    });

    test('Decrement to zero removes item', () {
      // Добавляем товар
      cartProvider.add(guitar);
      expect(cartProvider.contains(guitar.id), true);

      // Уменьшаем до нуля
      cartProvider.decrement(_cartLine(cartProvider, guitar));

      // Товар должен быть удален
      expect(cartProvider.contains(guitar.id), false);
      expect(cartProvider.items.isEmpty, true);
    });
  });

  group('Integration Tests - Edge Cases', () {
    late CartProvider cartProvider;
    late Product testProduct;

    setUp(() {
      cartProvider = CartProvider();
      testProduct = const Product(
        id: 1,
        name: 'Test Product',
        price: '1 000 ₽',
        amount: 1000.0,
        images: ['test.jpg'],
        tag: '',
        category: 'Test',
        description: 'Test',
        rating: 3.0,
        specs: {},
      );
    });

    test('Decrement non-existent item does nothing', () {
      // Act
      cartProvider.decrement('_absent_cart_line_test');

      // Assert
      expect(cartProvider.items.isEmpty, true);
    });

    test('Remove non-existent item does nothing', () {
      // Arrange
      cartProvider.add(testProduct);

      // Act
      cartProvider.remove('_absent_cart_line_test');

      // Assert
      expect(cartProvider.items.length, 1);
    });

    test('Toggle select non-existent item does nothing', () {
      // Arrange
      cartProvider.add(testProduct);

      // Act
      cartProvider.toggleSelect('_absent_cart_line_test');

      // Assert
      expect(cartProvider.items.length, 1);
    });

    test('Contains returns false for non-existent item', () {
      // Assert
      expect(cartProvider.contains(999), false);
    });

    test('Empty cart has zero total', () {
      // Assert
      expect(cartProvider.totalAmount, 0.0);
      expect(cartProvider.totalCount, 0);
      expect(cartProvider.selectedCount, 0);
      expect(cartProvider.allSelected, false);
    });
  });
}
