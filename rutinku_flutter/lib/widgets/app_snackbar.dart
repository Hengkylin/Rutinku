import 'package:flutter/material.dart';

/// Helper tunggal untuk menampilkan SnackBar bergaya seragam di seluruh
/// aplikasi (merah untuk error, hijau untuk sukses).
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor:
          isError ? Colors.red.shade600 : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

