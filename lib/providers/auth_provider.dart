import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;
  bool get isLoggedIn => user != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _errorMessage(e.code);
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _errorMessage(e.code);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();
  }

  String _errorMessage(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Email уже используется';
      case 'invalid-email': return 'Неверный формат email';
      case 'weak-password': return 'Пароль слишком слабый (мин. 6 символов)';
      case 'user-not-found': return 'Пользователь не найден';
      case 'wrong-password': return 'Неверный пароль';
      case 'invalid-credential': return 'Неверный email или пароль';
      default: return 'Ошибка: $code';
    }
  }
}
