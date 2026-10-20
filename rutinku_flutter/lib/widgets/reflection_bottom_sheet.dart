import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/habit_model.dart';
import '../notifiers/habit_notifier.dart';

class ReflectionBottomSheet extends ConsumerStatefulWidget {
  final HabitModel habit;
  final DateTime date;

  const ReflectionBottomSheet({
    super.key,
    required this.habit,
    required this.date,
  });

  @override
  ConsumerState<ReflectionBottomSheet> createState() =>
      _ReflectionBottomSheetState();
}

class _ReflectionBottomSheetState extends ConsumerState<ReflectionBottomSheet> {
  late String _selectedStatus;
  String? _selectedMood;
  late final TextEditingController _noteController;

  final List<Map<String, String>> _moodOptions = const [
    {'emoji': '😄', 'label': 'Senang'},
    {'emoji': '😐', 'label': 'Biasa'},
    {'emoji': '😫', 'label': 'Lelah'},
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.habit.getRecordOn(widget.date);
    _selectedStatus = existing?.status ?? 'completed';
    _selectedMood = existing?.mood;
    _noteController = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final note = _noteController.text.trim();
    await ref.read(habitNotifierProvider.notifier).updateHabitRecord(
          widget.habit.id,
          widget.date,
          status: _selectedStatus,
          mood: _selectedMood,
          note: note.isEmpty ? null : note,
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedStatus == 'rest'
                ? 'Status "${widget.habit.title}" disetel Libur (Streak tetap aman!)'
                : 'Jurnal refleksi berhasil disimpan!',
          ),
          backgroundColor: const Color(0xFF334155),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(widget.date);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Judul
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF), // Light purple
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.mood,
                    color: Color(0xFF9333EA),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bagaimana jurnalmu hari ini?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.habit.title} • $formattedDate',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 1. Pilihan Status
            const Text(
              'Status Kebiasaan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'completed',
                  icon: Icon(Icons.check_circle_outline, size: 18),
                  label: Text('Selesai'),
                ),
                ButtonSegment<String>(
                  value: 'skipped',
                  icon: Icon(Icons.skip_next_outlined, size: 18),
                  label: Text('Lewati'),
                ),
                ButtonSegment<String>(
                  value: 'rest',
                  icon: Icon(Icons.hotel_outlined, size: 18),
                  label: Text('Libur'),
                ),
              ],
              selected: {_selectedStatus},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedStatus = newSelection.first;
                });
              },
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                side: WidgetStateProperty.all(
                  BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Pilihan Mood (Emoji)
            const Text(
              'Bagaimana perasaanmu? (Mood)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: _moodOptions.map((mood) {
                final isSelected = _selectedMood == mood['emoji'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMood =
                              isSelected ? null : mood['emoji'];
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF3E8FF)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF9333EA)
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              mood['emoji']!,
                              style: const TextStyle(fontSize: 26),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mood['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF9333EA)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 3. Catatan Refleksi
            const Text(
              'Catatan Refleksi (Opsional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: _selectedStatus == 'skipped'
                    ? 'Mengapa dilewati hari ini? Tulis alasanmu...'
                    : (_selectedStatus == 'rest'
                        ? 'Waktunya istirahat & recovery tubuh...'
                        : 'Bagaimana perasaan atau progresmu hari ini?'),
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Color(0xFF9333EA), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B), // Sleek Slate
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Simpan Jurnal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
