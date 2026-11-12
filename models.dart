import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id, shopId, name, unit, image, category;
  final double mrp, price;
  Product({required this.id, required this.shopId, required this.name, required this.unit,
      required this.image, required this.category, required this.mrp, required this.price});
  factory Product.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return Product(id: d.id, shopId: m['shopId'] ?? '', name: m['name'] ?? '',
        unit: m['unit'] ?? '', image: m['image'] ?? '', category: m['category'] ?? '',
        mrp: (m['mrp'] ?? 0).toDouble(), price: (m['price'] ?? 0).toDouble());
  }
  int get offPercent => mrp > price ? (((mrp - price) / mrp) * 100).round() : 0;
}

class Shop {
  final String id, name, image;
  final bool isOpen;
  final int etaMin, etaMax;
  Shop({required this.id, required this.name, required this.image, required this.isOpen,
      this.etaMin = 15, this.etaMax = 25});
  factory Shop.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return Shop(id: d.id, name: m['name'] ?? '', image: m['image'] ?? '',
        isOpen: m['isOpen'] ?? false, etaMin: m['etaMin'] ?? 15, etaMax: m['etaMax'] ?? 25);
  }
}

class CartLine { final Product product; final int qty; CartLine(this.product, this.qty); }

const orderSteps = ['placed', 'accepted', 'packed', 'out_for_delivery', 'delivered'];
const orderLabels = ['Order Placed', 'Accepted by Shop', 'Packed', 'Out for Delivery', 'Delivered'];
