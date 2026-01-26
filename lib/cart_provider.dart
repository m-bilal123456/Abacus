import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  // Internal cart list
  final List<Map<String, dynamic>> _cart = [];

  // Get all items in the cart
  List<Map<String, dynamic>> get cart => _cart;

  // Number of different products
  int get itemCount => _cart.length;

  // 🔹 Total quantity of all items in the cart
 int get totalItems {
  int total = 0;
  for (var item in _cart) {
    num qty = item["qty"] ?? 0;  // treat it as num
    total += qty.toInt();        // now safe
  }
  return total;
}

void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  // 🔹 Total price of the cart
  int get totalPrice {
    int total = 0;
    for (var item in _cart) {
      num price = item["price"] ?? 0;
      int qty = (item["qty"] ?? 0).toInt(); // ✅ safe cast to int
      total += (price * qty).toInt(); // convert final result to int
    }
    return total;
  }

  // Add an item to the cart
  void addToCart(Map<String, dynamic> item) {
    int index = _cart.indexWhere((e) => e["name"] == item["name"]);
    if (index != -1) {
      // Item already exists → increase quantity
      _cart[index]["qty"] = (_cart[index]["qty"] ?? 0) + 1;
    } else {
      // Add new item
      _cart.add({
        "name": item["name"],
        "price": item["price"] ?? 0,
        "per_piece_price": item["per_piece_price"] ?? 0,
        "pack": item["pack"],
        "qty": item["qty"] ?? 1,
        "image": item["image"] ?? "",
      });
    }
    notifyListeners();
  }

  // Increase quantity of an item
  void increaseQty(int index) {
    _cart[index]["qty"] = (_cart[index]["qty"] ?? 0) + 1;
    notifyListeners();
  }

  // Decrease quantity of an item
  void decreaseQty(int index) {
    if ((_cart[index]["qty"] ?? 0) > 1) {
      _cart[index]["qty"] = (_cart[index]["qty"] ?? 0) - 1;
    } else {
      _cart.removeAt(index);
    }
    notifyListeners();
  }

  // Remove an item completely
  void removeItem(int index) {
    _cart.removeAt(index);
    notifyListeners();
  }
}
