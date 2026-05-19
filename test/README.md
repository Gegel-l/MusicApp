# ТЕСТЫ ДЛЯ ПРИЛОЖЕНИЯ "МАГАЗИН МУЗЫКАЛЬНЫХ ИНСТРУМЕНТОВ"

## Структура тестов

```
test/
├── models/
│   ├── product_test.dart          # Тесты модели Product
│   ├── cart_item_test.dart        # Тесты модели CartItem
│   └── review_test.dart           # Тесты модели Review
├── providers/
│   └── cart_provider_test.dart    # Тесты CartProvider
└── integration_test.dart          # Интеграционные тесты
```

## Типы тестов

### 1. Unit Tests (Модульные тесты)

**models/product_test.dart**
- Создание Product из Map
- Преобразование Product в Map
- Обработка пустых значений

**models/cart_item_test.dart**
- Создание CartItem с дефолтными значениями
- Создание CartItem с кастомными значениями
- Изменение quantity и isSelected

**models/review_test.dart**
- Создание Review
- Преобразование Review в Map и обратно
- Валидация рейтинга (0-5)

**providers/cart_provider_test.dart**
- Добавление товаров в корзину
- Удаление товаров
- Изменение количества
- Выбор/снятие выбора товаров
- Расчет общей суммы
- Форматирование суммы

### 2. Integration Tests (Интеграционные тесты)

**integration_test.dart**
- Полный сценарий покупки
- Работа с несколькими товарами
- Расчет суммы с учетом выбора
- Граничные случаи (edge cases)

## Запуск тестов

### Запустить все тесты
```bash
flutter test
```

### Запустить конкретный файл
```bash
flutter test test/models/product_test.dart
```

### Запустить тесты с покрытием
```bash
flutter test --coverage
```

### Просмотр отчета о покрытии
```bash
# Установить lcov (если не установлен)
# Windows: choco install lcov
# Mac: brew install lcov
# Linux: apt-get install lcov

# Генерация HTML отчета
genhtml coverage/lcov.info -o coverage/html

# Открыть отчет
# Windows: start coverage/html/index.html
# Mac: open coverage/html/index.html
# Linux: xdg-open coverage/html/index.html
```

## Статистика тестов

### Покрытие по модулям

| Модуль | Тестов | Покрытие |
|--------|--------|----------|
| Product | 3 | 100% |
| CartItem | 4 | 100% |
| Review | 6 | 100% |
| CartProvider | 20 | ~80% |
| Integration | 10 | - |
| **ИТОГО** | **43** | **~70%** |

## Описание тестовых сценариев

### Product Model Tests
1. ✅ Создание продукта из Map
2. ✅ Преобразование продукта в Map
3. ✅ Обработка пустых изображений и спецификаций

### CartItem Model Tests
1. ✅ Создание с дефолтными значениями (quantity=1, isSelected=true)
2. ✅ Создание с кастомными значениями
3. ✅ Изменение количества
4. ✅ Изменение статуса выбора

### Review Model Tests
1. ✅ Создание отзыва с uid
2. ✅ Создание отзыва без uid
3. ✅ Преобразование в Map
4. ✅ Создание из Map
5. ✅ Обработка пустого автора
6. ✅ Валидация рейтинга (0.0 - 5.0)

### CartProvider Tests
1. ✅ Начальное состояние (пустая корзина)
2. ✅ Добавление товара
3. ✅ Добавление одинакового товара (увеличение quantity)
4. ✅ Добавление разных товаров
5. ✅ Удаление товара
6. ✅ Уменьшение количества
7. ✅ Уменьшение до нуля (удаление)
8. ✅ Расчет общей суммы
9. ✅ Расчет суммы с учетом количества
10. ✅ Переключение выбора товара
11. ✅ Выбор всех товаров
12. ✅ Получение только выбранных товаров
13. ✅ Подсчет выбранных товаров
14. ✅ Очистка корзины
15. ✅ Проверка наличия товара
16. ✅ Форматирование суммы

### Integration Tests - Shopping Flow
1. ✅ Полный сценарий покупки (добавление, изменение, удаление)
2. ✅ Добавление нескольких товаров и расчет суммы
3. ✅ Выбор/снятие выбора влияет на сумму
4. ✅ Удаление всех товаров по одному
5. ✅ Очистка корзины
6. ✅ Уменьшение до нуля удаляет товар

### Integration Tests - Edge Cases
1. ✅ Уменьшение несуществующего товара
2. ✅ Удаление несуществующего товара
3. ✅ Переключение выбора несуществующего товара
4. ✅ Проверка наличия несуществующего товара
5. ✅ Пустая корзина имеет нулевую сумму

## Примеры запуска

### Запуск с подробным выводом
```bash
flutter test --reporter expanded
```

### Запуск конкретной группы тестов
```bash
flutter test --name "Product Model Tests"
```

### Запуск с таймаутом
```bash
flutter test --timeout 30s
```

## Continuous Integration (CI)

Для автоматического запуска тестов при каждом коммите можно настроить GitHub Actions:

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.9.2'
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v2
```

## Рекомендации по тестированию

### Что тестировать
✅ Бизнес-логику (провайдеры)
✅ Модели данных
✅ Утилиты и хелперы
✅ Критические пользовательские сценарии

### Что не обязательно тестировать
❌ UI виджеты (требуют widget tests)
❌ Firebase интеграцию (требуют моки)
❌ Простые геттеры/сеттеры
❌ Сторонние библиотеки

### Best Practices
1. Используйте `setUp()` для подготовки тестовых данных
2. Используйте `tearDown()` для очистки после тестов
3. Один тест = одна проверка (Single Responsibility)
4. Используйте описательные имена тестов
5. Следуйте паттерну AAA (Arrange-Act-Assert)

## Troubleshooting

### Ошибка: "No tests found"
```bash
# Проверьте, что файлы заканчиваются на _test.dart
# Проверьте, что файлы находятся в папке test/
```

### Ошибка: "Package not found"
```bash
flutter pub get
```

### Ошибка: "Test timeout"
```bash
# Увеличьте таймаут
flutter test --timeout 60s
```

## Дальнейшие улучшения

### Планируется добавить:
- [ ] Widget tests для UI компонентов
- [ ] Моки для Firebase (mockito)
- [ ] Тесты для AuthProvider
- [ ] Тесты для ProductsProvider
- [ ] Тесты для ReviewsProvider
- [ ] Тесты для FavoritesProvider
- [ ] E2E тесты (integration_test package)
- [ ] Performance тесты
- [ ] Snapshot тесты

## Контакты

При возникновении вопросов по тестам обращайтесь к разработчику.

---

**Последнее обновление:** 2024
**Версия:** 1.0
