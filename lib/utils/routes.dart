import 'package:flutter/material.dart';

// Slide up — для detail screen
Route<T> slideUpRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, a, __) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

// Slide right — для обычных переходов вперёд
Route<T> slideRightRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, a, __) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, a, __, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

// Hero-compatible route для detail screen
Route<T> heroRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, a, __) => page,
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, a, __, child) {
        final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: a, curve: const Interval(0.0, 0.6)),
          ),
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.08), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    );
Route<T> fadeScaleRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, a, __) => page,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, a, __, child) {
        final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
