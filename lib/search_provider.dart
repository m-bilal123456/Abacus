import 'package:flutter/material.dart';

class SearchProvider extends ChangeNotifier {
  String _query = "";

  String get query => _query;

  void updateQuery(String value) {
    _query = value.toLowerCase();
    notifyListeners();
  }

  void clearSearch() {
  _query = "";
  notifyListeners();
}
}


