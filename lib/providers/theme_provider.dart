import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle({String? uid}) {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    if (uid != null) _save(uid);
  }

  Future<void> loadForUser(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final theme = doc.data()?['theme'] as String?;
    _mode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> _save(String uid) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'theme': isDark ? 'dark' : 'light'}, SetOptions(merge: true));
  }
}
