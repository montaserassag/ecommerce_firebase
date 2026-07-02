import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
  double get subtotal => product.price * quantity;
}

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};

  List<CartItem> get itemList  => _items.values.toList();
  int    get totalItems        => _items.values.fold(0, (s, i) => s + i.quantity);
  double get totalPrice        => _items.values.fold(0.0, (s, i) => s + i.subtotal);
  bool   contains(int id)      => _items.containsKey(id);
  int    getQty(int id)        => _items[id]?.quantity ?? 0;

  void add(Product product) {
    _items.containsKey(product.id)
        ? _items[product.id]!.quantity++
        : _items[product.id] = CartItem(product: product);
    notifyListeners();
  }

  void remove(int id) {
    _items.remove(id);
    notifyListeners();
  }

  void increment(int id) {
    _items[id]?.quantity++;
    notifyListeners();
  }

  void decrement(int id) {
    if (_items[id] == null) return;
    _items[id]!.quantity <= 1 ? _items.remove(id) : _items[id]!.quantity--;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
