import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('My Orders')),
    body: ref.watch(ordersProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Could not load orders')),
      data: (s) => s.docs.isEmpty ? const Center(child: Text('No orders yet')) : ListView(children: s.docs.map((d) {
        final m = d.data(); final ts = (m['createdAt'] as dynamic)?.toDate();
        return ListTile(
          title: Text('${inr(m['total'] ?? 0)} • ${(m['status'] ?? '').toString().replaceAll('_', ' ')}'),
          subtitle: Text(ts == null ? '' : DateFormat('d MMM, h:mm a').format(ts)),
          trailing: TextButton(child: const Text('Reorder'), onPressed: () {
            final n = ref.read(cartProvider.notifier);
            for (final i in (m['items'] as List)) {
              for (var k = 0; k < (i['qty'] as int); k++) {
                n.add(Product(id: i['id'], shopId: m['shopId'], name: i['name'], unit: i['unit'] ?? '',
                    image: '', category: '', mrp: (i['price'] as num).toDouble(), price: (i['price'] as num).toDouble()));
              }
            }
            Navigator.pop(context);
          }),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(orderId: d.id))));
      }).toList())));
}

class TrackingScreen extends ConsumerWidget {
  final String orderId; const TrackingScreen({super.key, required this.orderId});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Track Order')),
    body: ref.watch(orderProvider(orderId)).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Could not load order')),
      data: (d) {
        final m = d.data() ?? {}; final step = orderSteps.indexOf(m['status'] ?? 'placed');
        final phone = m['riderPhone'] as String?;
        return ListView(padding: const EdgeInsets.all(16), children: [
          for (var i = 0; i < orderLabels.length; i++) ListTile(
            leading: Icon(i <= step ? Icons.check_circle : Icons.radio_button_unchecked, color: i <= step ? brand : Colors.grey),
            title: Text(orderLabels[i], style: TextStyle(fontWeight: i == step ? FontWeight.w800 : null))),
          if (phone != null && step < 4) FilledButton.icon(icon: const Icon(Icons.call), label: const Text('Call Rider'),
              onPressed: () => launchUrl(Uri.parse('tel:$phone'))),
          const Divider(height: 32),
          const Text('Invoice', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ...((m['items'] as List?) ?? []).map((i) => ListTile(dense: true, title: Text('${i['name']} × ${i['qty']}'), trailing: Text(inr(i['price'] * i['qty'])))),
          ListTile(dense: true, title: const Text('Delivery fee'), trailing: Text(inr(m['deliveryFee'] ?? 0))),
          ListTile(dense: true, title: const Text('Discount'), trailing: Text('-${inr(m['discount'] ?? 0)}')),
          ListTile(title: const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('Paid via ${m['payment']}'),
              trailing: Text(inr(m['total'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w800))),
        ]);
      }));
}
