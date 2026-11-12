import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';

final authStateProvider = StreamProvider<User?>((_) => FirebaseAuth.instance.authStateChanges());
final db = FirebaseFirestore.instance;

/// Auto-fetch location with permission handling; throws readable errors.
final locationProvider = FutureProvider<Position>((_) async {
  if (!await Geolocator.isLocationServiceEnabled()) throw 'Turn on location services';
  var p = await Geolocator.checkPermission();
  if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
  if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
    throw 'Location denied - pick an address manually';
  }
  return Geolocator.getCurrentPosition();
});

final bannersProvider = StreamProvider<List<String>>((_) => db.collection('banners')
    .where('active', isEqualTo: true).snapshots()
    .map((s) => s.docs.map((d) => (d['image'] ?? '') as String).toList()));

final shopsProvider = StreamProvider<List<Shop>>((_) => db.collection('shops')
    .where('verified', isEqualTo: true).snapshots()
    .map((s) => s.docs.map(Shop.fromDoc).toList()));

final categoryProvider = StateProvider<String>((_) => 'All');
final searchProvider = StateProvider<String>((_) => '');

final productsProvider = StreamProvider<List<Product>>((ref) {
  final cat = ref.watch(categoryProvider);
  Query<Map<String, dynamic>> q = db.collection('products');
  if (cat != 'All') q = q.where('category', isEqualTo: cat);
  return q.limit(100).snapshots().map((s) => s.docs.map(Product.fromDoc).toList());
});

/// Predictive search over the (offline-cached) product stream.
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final q = ref.watch(searchProvider).toLowerCase().trim();
  return ref.watch(productsProvider).whenData(
      (l) => q.isEmpty ? l : l.where((p) => p.name.toLowerCase().contains(q)).toList());
});

class CartNotifier extends StateNotifier<Map<String, CartLine>> {
  CartNotifier() : super({});
  void add(Product p) => state = {...state, p.id: CartLine(p, (state[p.id]?.qty ?? 0) + 1)};
  void remove(Product p) {
    final q = (state[p.id]?.qty ?? 0) - 1;
    final m = {...state};
    q <= 0 ? m.remove(p.id) : m[p.id] = CartLine(p, q);
    state = m;
  }
  void clear() => state = {};
  int get count => state.values.fold(0, (a, b) => a + b.qty);
  double get subtotal => state.values.fold(0.0, (a, b) => a + b.qty * b.product.price);
}
final cartProvider = StateNotifierProvider<CartNotifier, Map<String, CartLine>>((_) => CartNotifier());

double deliveryFee(double sub) => sub == 0 ? 0 : (sub >= 199 ? 0 : 25);

/// Coupon doc: coupons/{CODE} {active, flat, minOrder}
Future<double> applyCoupon(String code, double sub) async {
  final d = await db.collection('coupons').doc(code.trim().toUpperCase()).get();
  if (!d.exists || d['active'] != true) throw 'Invalid coupon';
  if (sub < (d['minOrder'] ?? 0)) throw 'Minimum order ₹${d['minOrder']}';
  return (d['flat'] ?? 0).toDouble();
}

Future<String> placeOrder(CartNotifier cart, Map<String, CartLine> lines,
    {required String payment, required Map<String, dynamic> address, double discount = 0}) async {
  final l = lines.values.toList();
  final sub = cart.subtotal, fee = deliveryFee(sub);
  final doc = await db.collection('orders').add({
    'userId': FirebaseAuth.instance.currentUser!.uid,
    'shopId': l.first.product.shopId,
    'items': l.map((e) => {'id': e.product.id, 'name': e.product.name, 'unit': e.product.unit,
        'price': e.product.price, 'qty': e.qty}).toList(),
    'subtotal': sub, 'deliveryFee': fee, 'discount': discount, 'total': sub + fee - discount,
    'payment': payment, 'address': address, 'status': 'placed', 'riderPhone': null,
    'createdAt': FieldValue.serverTimestamp(),
  });
  cart.clear();
  return doc.id;
}

final ordersProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>>((_) => db
    .collection('orders').where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
    .orderBy('createdAt', descending: true).snapshots());

final orderProvider = StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>(
    (_, id) => db.collection('orders').doc(id).snapshots());
