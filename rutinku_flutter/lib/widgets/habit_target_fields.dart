import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/validators.dart';

/// Input "Target Harian" (angka, default 1) dan "Satuan" (opsional) untuk
/// Progressive Habit. Dipakai bersama oleh form tambah & edit kebiasaan.
/// Aturan input ada di [Validators]; gaya field mengikuti form induk lewat
/// [decoration].
class HabitTargetFields extends StatelessWidget {
  const HabitTargetFields({
    super.key,
    required this.targetController,
    required this.unitController,
    required this.decoration,
    this.enabled = true,
  });

  final TextEditingController targetController;
  final TextEditingController unitController;
  final InputDecoration Function({String? hintText}) decoration;
  final bool enabled;

  static const _labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Color(0xFF334155),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildField(
                label: 'Target harian',
                child: TextFormField(
                  key: const Key('habit_target_field'),
                  controller: targetController,
                  enabled: enabled,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: _withWrappingError(decoration(hintText: '8')),
                  validator: Validators.validateTargetValue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _buildField(
                label: 'Satuan (opsional)',
                child: TextFormField(
                  key: const Key('habit_unit_field'),
                  controller: unitController,
                  enabled: enabled,
                  decoration: _withWrappingError(
                    decoration(hintText: 'gelas, menit, halaman'),
                  ),
                  validator: Validators.validateUnit,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Menjelaskan kapan kartu memakai tombol [+] agar jumlah tidak
        // tertukar diisi di kolom Satuan.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Isi Target lebih dari 1 untuk mencatat progres dengan tombol [+], '
                'mis. target 8 dengan satuan "gelas". Target 1 = cukup centang sekali.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Kolom berdampingan cukup sempit; izinkan pesan error lebih dari 1 baris.
  static InputDecoration _withWrappingError(InputDecoration decoration) =>
      decoration.copyWith(errorMaxLines: 3);

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
