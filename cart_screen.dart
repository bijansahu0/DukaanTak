import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/providers.dart';
import 'home_screen.dart' show Stepper_;
import 'orders_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _coupon = TextEditingController();
  final _addr = TextEditingController();
  double _discount = 0; String _pay = 'COD'; bool _busy = false;

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _applyCoupon() async {
    try {
      final d = await applyCoupon(_coupon.text, ref.read(cartProvider.notifier).subtotal);
      setState(() => _discount = d); _toast('Coupon applied: -${inr(d)}');
    } catch (e) { _toast('$e'); }
  }

  Future<void> _order() async {
    if (_addr.text.trim().isEmpty) return _toast('Please enter delivery address');
    setState(() => _busy = true);
    try {
      final id = await placeOrder(ref.read(cartProvider.notifier), ref.read(cartProvider),
          payment: _pay, address: {'line': _addr.text.trim()}, discount: _discount);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => TrackingScreen(orderId: id)), (r) => r.isFirst);
    } catch (e) { _toast('Order failed. Check connection and retry.'); }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider); final n = ref.read(cartProvider.notifier);
    final sub = n.subtotal, fee = deliveryFee(sub), total = sub + fee - _discount;
    return Scaffold(
      appBar: AppBar(title: const Text('Cart / कार्ट')),
      body: cart.isEmpty ? const Center(child: Text('Your cart is empty')) : ListView(padding: const EdgeInsets.all(12), children: [
        ...cart.values.map((l) => ListTile(title: Text(l.product.name), subtitle: Text(l.product.unit),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Stepper_(qty: l.qty, onAdd: () => n.add(l.product), onRemove: () => n.remove(l.product)),
              const SizedBox(width: 10), Text(inr(l.qty * l.product.price)),
            ]))),
        const Divider(),
        TextField(controller: _addr, decoration: const InputDecoration(labelText: 'Delivery address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: TextField(controller: _coupon, textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Coupon code', border: OutlineInputBorder()))),
          const SizedBox(width: 8), FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(90, 56)), onPressed: _applyCoupon, child: const Text('Apply')),
        ]),
        RadioListTile(value: 'COD', groupValue: _pay, onChanged: (v) => setState(() => _pay = v!), title: const Text('Cash on Delivery')),
        RadioListTile(value: 'UPI', groupValue: _pay, onChanged: (v) => setState(() => _pay = v!), title: const Text('UPI (pay on delivery via UPI app)')),
        _row('Item total', inr(sub)), _row('Delivery fee', fee == 0 ? 'FREE' : inr(fee)),
        if (_discount > 0) _row('Discount', '-${inr(_discount)}'),
        const Divider(), _row('To pay', inr(total), bold: true),
      ]),
      bottomNavigationBar: cart.isEmpty ? null : SafeArea(child: Padding(padding: const EdgeInsets.all(10),
        child: FilledButton(onPressed: _busy ? null : _order, child: Text(_busy ? 'Placing…' : 'Place Order • ${inr(total)}')))),
    );
  }

  Widget _row(String a, String b, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(a, style: TextStyle(fontWeight: bold ? FontWeight.w800 : null)), Text(b, style: TextStyle(fontWeight: bold ? FontWeight.w800 : null))]));
}
