import 'package:flutter/material.dart';
const brand = Color(0xFF0034E1);
ThemeData buildTheme(Brightness b) => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: brand, primary: brand, brightness: b),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: brand, minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
);
String inr(num v) => '₹${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)}';
