import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final double originalPrice;
  final int discount;
  final IconData iconData;
  final Color accent;
  final String stock;
  final String imageUrl;
  final bool isDeals;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.originalPrice,
    required this.discount,
    required this.iconData,
    required this.accent,
    required this.stock,
    this.imageUrl = '',
    this.isDeals = true,
  });

  /// ─────────────────────────────────────────────────────────────────────
  /// Exercise 1: parse JSON (from dummyjson.com/products) into a Product.
  ///
  /// ✅ Validate After Decoding — every field is type-checked with a safe
  ///    fallback, so a malformed API/cache entry never crashes the app.
  /// ─────────────────────────────────────────────────────────────────────
  factory Product.fromApiJson(Map<String, dynamic> json) {
    final dynamic rawId = json['id'];
    final int id = switch (rawId) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v) ?? 0,
      _ => 0,
    };

    final name = json['title'] is String ? json['title'] as String : 'Unnamed product';

    final apiCategory = json['category'] is String ? json['category'] as String : '';
    final category = _mapCategory(apiCategory);

    final price = json['price'] is num ? (json['price'] as num).toDouble() : 0.0;

    final discountPct = json['discountPercentage'] is num
        ? (json['discountPercentage'] as num).toDouble()
        : 0.0;
    final discount = discountPct.round().clamp(0, 90).toInt();

    final original = discount > 0 ? price / (1 - discount / 100) : price;

    final stockNum = json['stock'] is num ? (json['stock'] as num).toInt() : 0;

    String thumb = '';
    if (json['thumbnail'] is String) {
      thumb = json['thumbnail'] as String;
    } else if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      final first = (json['images'] as List).first;
      if (first is String) thumb = first;
    }

    return Product(
      id: id,
      name: name,
      category: category,
      price: double.parse(price.toStringAsFixed(2)),
      originalPrice: double.parse(original.toStringAsFixed(2)),
      discount: discount,
      iconData: kCategoryIcons[category] ?? Icons.shopping_bag_rounded,
      accent: kCategoryColors[category] ?? kAccent,
      stock: '$stockNum left',
      imageUrl: thumb,
    );
  }


  // ─── Exercise 2: Model class with fromDoc / toMap ──────────────────────

  // ✅ fromDoc — parse a Firestore document into a Product
  factory Product.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final j = doc.data();
    final id       = int.tryParse(doc.id) ?? 0;
    final category = j['category'] is String ? j['category'] as String : 'Others';
    final price    = j['price']    is num    ? (j['price'] as num).toDouble() : 0.0;
    final origP    = j['originalPrice'] is num ? (j['originalPrice'] as num).toDouble() : price;
    final discount = j['discount'] is num    ? (j['discount'] as num).toInt() : 0;
    final stockNum = j['stock']    is num    ? (j['stock']    as num).toInt() : 0;
    return Product(
      id: id,
      name: j['name'] is String ? j['name'] as String : 'Unnamed product',
      category: category,
      price: price,
      originalPrice: origP,
      discount: discount,
      iconData: kCategoryIcons[category] ?? Icons.shopping_bag_rounded,
      accent:   kCategoryColors[category] ?? kAccent,
      stock:    '$stockNum left',
      imageUrl: j['imageUrl'] is String ? j['imageUrl'] as String : '',
    );
  }

  // ✅ toFirestoreMap — the toMap() side of the fromDoc/toMap pattern
  Map<String, dynamic> toFirestoreMap() => {
    'name':          name,
    'category':      category,
    'price':         price,
    'originalPrice': originalPrice,
    'discount':      discount,
    'stock':         int.tryParse(stock.split(' ').first) ?? 0,
    'imageUrl':      imageUrl,
  };

  /// Map dummyjson's fine-grained categories onto the app's 6 categories.
  static String _mapCategory(String apiCategory) {
    const electronics = {'smartphones', 'laptops', 'tablets', 'mobile-accessories'};
    const fashion = {
      'mens-shirts', 'mens-shoes', 'mens-watches',
      'womens-dresses', 'womens-shoes', 'womens-watches',
      'womens-jewellery', 'sunglasses', 'tops',
    };
    const sports = {'sports-accessories', 'motorcycle', 'vehicle'};
    const perfumes = {'fragrances'};
    const backset = {'womens-bags'};

    if (electronics.contains(apiCategory)) return 'Electronics';
    if (fashion.contains(apiCategory)) return 'Fashion';
    if (sports.contains(apiCategory)) return 'Sports';
    if (perfumes.contains(apiCategory)) return 'Perfumes';
    if (backset.contains(apiCategory)) return 'Backset';
    return 'Others';
  }
}

const Map<String, Color> kCategoryColors = {
  'Electronics': Color(0xFF4A9DE8),
  'Fashion':     Color(0xFFE91E63),
  'Sports':      Color(0xFF2ECC71),
  'Perfumes':    Color(0xFF9B59B6),
  'Backset':     Color(0xFFFF9800),
  'Others':      Color(0xFF607D8B),
};

const Map<String, IconData> kCategoryIcons = {
  'Electronics': Icons.devices_other_rounded,
  'Fashion':     Icons.checkroom_rounded,
  'Sports':      Icons.sports_rounded,
  'Perfumes':    Icons.spa_rounded,
  'Backset':     Icons.backpack_rounded,
  'Others':      Icons.category_rounded,
};

// App Color Constants
const kBgColor     = Color(0xFF0C0F1C);
const kCardColor   = Color(0xFF131826);
const kBorderColor = Color(0xFF1D2640);
const kTextPrimary = Color(0xFFE8EAF6);
const kTextSecond  = Color(0xFF6B7A99);
const kAccent      = Color(0xFF00C8FF);
const kGold        = Color(0xFFF5C518);
const kRed         = Color(0xFFE85C4A);
const kGreen       = Color(0xFF4CAF50);
