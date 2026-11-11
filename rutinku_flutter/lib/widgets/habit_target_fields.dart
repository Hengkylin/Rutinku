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
    return Row(
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
              decoration: decoration(hintText: '1'),
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
              decoration: decoration(hintText: 'gelas, menit, halaman'),
            ),
          ),
        ),
      ],
    );
  }

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
