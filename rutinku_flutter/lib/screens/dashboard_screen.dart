import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/habit_notifier.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca state dari notifier secara reaktif
    final habitState = ref.watch(habitNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutinku'),
      ),
      // Menerapkan kondisi 1, 2, 3, dan 4 menggunakan .when()
      body: habitState.when(
        // Kondisi 1: Initial Loading
        loading: () => const Center(child: CircularProgressIndicator()),
        
        // Kondisi 4: Error State + Tombol Retry
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(error.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.read(habitNotifierProvider.notifier).retryFetch(),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
        
        data: (habits) {
          // Kondisi 2: Empty State
          if (habits.isEmpty) {
            return const Center(
              child: Text(
                'Belum ada rutinitas.\nYuk, buat kebiasaan pertamamu!',
                textAlign: TextAlign.center,
              ),
            );
          }
          // Kondisi 3: Data Berhasil Dimuat
          return ListView.builder(
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(habit.title),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHabitDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddHabitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Mencegah dialog ditutup saat loading
      builder: (context) => const _AddHabitForm(),
    );
  }
}

// Widget terpisah untuk Form (Kondisi 5 dan 6)
class _AddHabitForm extends ConsumerStatefulWidget {
  const _AddHabitForm();

  @override
  ConsumerState<_AddHabitForm> createState() => _AddHabitFormState();
}

class _AddHabitFormState extends ConsumerState<_AddHabitForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Kondisi 5: Validasi Input
    if (!_formKey.currentState!.validate()) return;

    // Kondisi 6: Loading saat Submit & cegah Double Tap
    setState(() => _isSubmitting = true);

    try {
      await ref.read(habitNotifierProvider.notifier).addHabit(_titleController.text);
      if (mounted) Navigator.pop(context); // Tutup dialog jika sukses
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Kebiasaan'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _titleController,
          enabled: !_isSubmitting, // Nonaktifkan input saat submit
          decoration: const InputDecoration(
            labelText: 'Nama Kebiasaan',
            hintText: 'Contoh: Minum Air Putih',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nama kebiasaan tidak boleh kosong';
            }
            if (value.trim().length < 3) {
              return 'Minimal 3 karakter';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}