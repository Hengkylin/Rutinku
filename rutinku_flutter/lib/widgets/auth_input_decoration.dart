import 'package:flutter/material.dart';

/// Gaya input seragam untuk semua layar autentikasi (Login, Register,
/// Lupa Password, Password Baru).
InputDecoration authInputDecoration(
  String label,
  IconData icon, {
  Widget? suffix,
}) {
  const navy = Color(0xFF1E293B);
  OutlineInputBorder border(BorderSide side) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: side,
      );

  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF1F5F9),
    border: border(BorderSide.none),
    focusedBorder: border(const BorderSide(color: navy, width: 1.6)),
    errorBorder: border(BorderSide(color: Colors.red.shade400)),
    focusedErrorBorder:
        border(BorderSide(color: Colors.red.shade600, width: 1.6)),
  );
}
