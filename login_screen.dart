import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController(), _otp = TextEditingController();
  String? _verId; bool _busy = false;

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _sendOtp() async {
    setState(() => _busy = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+91${_phone.text.trim()}',
      verificationCompleted: (c) => FirebaseAuth.instance.signInWithCredential(c),
      verificationFailed: (e) { _toast(e.message ?? 'OTP failed'); setState(() => _busy = false); },
      codeSent: (id, _) => setState(() { _verId = id; _busy = false; }),
      codeAutoRetrievalTimeout: (id) => _verId = id,
    );
  }

  Future<void> _verify() async {
    try {
      await FirebaseAuth.instance.signInWithCredential(
          PhoneAuthProvider.credential(verificationId: _verId!, smsCode: _otp.text.trim()));
    } on FirebaseAuthException catch (e) { _toast(e.message ?? 'Invalid OTP'); }
  }

  Future<void> _google() async {
    try {
      final g = await GoogleSignIn().signIn();
      if (g == null) return;
      final a = await g.authentication;
      await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(accessToken: a.accessToken, idToken: a.idToken));
    } catch (e) { _toast('Google sign-in failed'); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(
          mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('DukaanTak', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF0034E1))),
            const Text('Aapki dukaan, bas ek tap door • Delivery in minutes'),
            const SizedBox(height: 32),
            if (_verId == null) TextField(controller: _phone, keyboardType: TextInputType.phone, maxLength: 10,
                decoration: const InputDecoration(prefixText: '+91 ', labelText: 'Mobile number', border: OutlineInputBorder()))
            else TextField(controller: _otp, keyboardType: TextInputType.number, maxLength: 6,
                decoration: const InputDecoration(labelText: 'Enter OTP', border: OutlineInputBorder())),
            FilledButton(onPressed: _busy ? null : (_verId == null ? _sendOtp : _verify),
                child: Text(_verId == null ? 'Send OTP' : 'Verify & Continue')),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: _google, icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Continue with Google'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48))),
          ]))),
      );
}
