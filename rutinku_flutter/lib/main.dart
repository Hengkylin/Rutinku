import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Wajib ditambahkan
import 'app.dart';

void main() {
  // Bungkus App() dengan ProviderScope
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}