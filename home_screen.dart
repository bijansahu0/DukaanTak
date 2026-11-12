import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';

const categories = ['All', 'Groceries', 'Dairy', 'Snacks', 'Personal Care', 'Household'];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final n = ref.read(cartProvider.notifier);
    final loc = ref.watch(locationProvider);
    final products = ref.watch(filteredProductsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Delivery in 15-25 mins', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(loc.when(data: (p) => '${p.latitude.toStringAsFixed(3)}, ${p.longitude.toStringAsFixed(3)}',
              loading: () => 'Locating…', error: (e, _) => '$e'), style: const TextStyle(fontSize: 12)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.receipt_long), onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())))],
      ),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(12), child: TextField(
          onChanged: (v) => ref.read(searchProvider.notifier).state = v,
          decoration: InputDecoration(hintText: 'Search "doodh", "atta"…  खोजें', prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))))),
        SliverToBoxAdapter(child: ref.watch(bannersProvider).when(
          data: (b) => b.isEmpty ? const SizedBox() : CarouselSlider(
            options: CarouselOptions(height: 140, autoPlay: true, viewportFraction: .9, enlargeCenterPage: true),
            items: b.map((u) => ClipRRect(borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(imageUrl: u, fit: BoxFit.cover, width: double.infinity))).toList()),
          loading: () => _shimmer(140), error: (_, __) => const SizedBox())),
        SliverToBoxAdapter(child: SizedBox(height: 52, child: ListView(scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: categories.map((c) => Padding(padding: const EdgeInsets.all(6), child: ChoiceChip(
            label: Text(c), selected: ref.watch(categoryProvider) == c,
            onSelected: (_) => ref.read(categoryProvider.notifier).state = c))).toList()))),
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Nearby shops', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)))),
        SliverToBoxAdapter(child: SizedBox(height: 96, child: ref.watch(shopsProvider).when(
          data: (s) => ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
              children: s.map(_ShopCard.new).toList()),
          loading: () => _shimmer(96), error: (e, _) => Center(child: Text('Could not load shops'))))),
        products.when(
          data: (l) => l.isEmpty
              ? const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No products found'))))
              : SliverPadding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 100), sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: .68, mainAxisSpacing: 10, crossAxisSpacing: 10),
                  itemCount: l.length, itemBuilder: (_, i) => _ProductCard(l[i]))),
          loading: () => SliverToBoxAdapter(child: _shimmer(300)),
          error: (e, _) => const SliverToBoxAdapter(child: Center(child: Text('Something went wrong. Pull to retry.')))),
      ]),
      bottomNavigationBar: cart.isEmpty ? null : SafeArea(child: Padding(padding: const EdgeInsets.all(10), child: FilledButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
        child: Row(children: [Text('${n.count} items'), const Spacer(), Text(inr(n.subtotal)), const SizedBox(width: 8),
          const Text('View Cart ›')])))),
    );
  }
}

Widget _shimmer(double h) => Shimmer.fromColors(baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100,
    child: Container(height: h, margin: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14))));

class _ShopCard extends StatelessWidget {
  final Shop s; const _ShopCard(this.s);
  @override
  Widget build(BuildContext context) => Container(width: 230, margin: const EdgeInsets.all(4), padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: s.image, width: 56, height: 56, fit: BoxFit.cover,
          errorWidget: (_, __, ___) => const Icon(Icons.store, size: 40))),
      const SizedBox(width: 10),
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('${s.etaMin}-${s.etaMax} mins', style: const TextStyle(fontSize: 12)),
        Text(s.isOpen ? 'Open' : 'Closed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: s.isOpen ? Colors.green : Colors.red)),
      ])),
    ]));
}

class _ProductCard extends ConsumerWidget {
  final Product p; const _ProductCard(this.p);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider)[p.id]?.qty ?? 0;
    final n = ref.read(cartProvider.notifier);
    return Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Colors.black12)),
      child: Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Stack(children: [
          Positioned.fill(child: CachedNetworkImage(imageUrl: p.image, fit: BoxFit.contain, errorWidget: (_, __, ___) => const Icon(Icons.shopping_basket, size: 48))),
          if (p.offPercent > 0) Positioned(top: 0, left: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(6)),
              child: Text('${p.offPercent}% OFF', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))),
        ])),
        Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(p.unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Row(children: [
          Text(inr(p.price), style: const TextStyle(fontWeight: FontWeight.w800)),
          if (p.mrp > p.price) Padding(padding: const EdgeInsets.only(left: 4),
              child: Text(inr(p.mrp), style: const TextStyle(decoration: TextDecoration.lineThrough, fontSize: 12, color: Colors.grey))),
          const Spacer(),
          qty == 0
              ? OutlinedButton(onPressed: () => n.add(p), style: OutlinedButton.styleFrom(minimumSize: const Size(56, 32), padding: EdgeInsets.zero), child: const Text('ADD'))
              : Stepper_(qty: qty, onAdd: () => n.add(p), onRemove: () => n.remove(p)),
        ]),
      ])));
  }
}

class Stepper_ extends StatelessWidget {
  final int qty; final VoidCallback onAdd, onRemove;
  const Stepper_({super.key, required this.qty, required this.onAdd, required this.onRemove});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: brand, borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      InkWell(onTap: onRemove, child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, size: 16, color: Colors.white))),
      Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      InkWell(onTap: onAdd, child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.add, size: 16, color: Colors.white))),
    ]));
}
