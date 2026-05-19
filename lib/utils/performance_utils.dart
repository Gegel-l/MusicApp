import 'package:flutter/material.dart';
import 'dart:async';

/// Утилита для debounce (защита от частых вызовов)
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Утилита для throttle (ограничение частоты вызовов)
class Throttler {
  final Duration interval;
  Timer? _timer;
  bool _canExecute = true;

  Throttler({this.interval = const Duration(milliseconds: 300)});

  void call(VoidCallback action) {
    if (_canExecute) {
      action();
      _canExecute = false;
      _timer = Timer(interval, () {
        _canExecute = true;
      });
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// Memoization для кэширования результатов функций
class Memoizer<T> {
  final Map<String, T> _cache = {};

  T memoize(String key, T Function() computation) {
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    final result = computation();
    _cache[key] = result;
    return result;
  }

  void clear() {
    _cache.clear();
  }

  void remove(String key) {
    _cache.remove(key);
  }
}
