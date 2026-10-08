import 'package:flutter/material.dart';

class TemplateScreen extends StatelessWidget {
  const TemplateScreen({super.key});

  static const List<Map<String, dynamic>> dummyTemplates = [
    {
      'category': 'Kesehatan',
      'items': [
        {
          'title': 'Minum air putih, jaga kesehatan',
          'icon': '🚰',
          'pop': true,
        },
        {
          'title': 'Menyikat gigi',
          'icon': '🦷',
          'pop': true,
        },
        {
          'title': 'Mandi',
          'icon': '🚿',
          'pop': false,
        },
        {
          'title': 'Pergi tidur lebih awal',
          'icon': '🌙',
          'pop': true,
        },
        {
          'title': 'Bangun pagi',
          'icon': '🌅',
          'pop': false,
        },
        {
          'title': 'Ambil Pengingat Pil',
          'icon': '💊',
          'pop': false,
        },
        {
          'title': 'Istirahat',
          'icon': '☕',
          'pop': false,
        },
        {
          'title': 'Makan buah-buahan',
          'icon': '🍐',
          'pop': false,
        },
      ],
    },
    {
      'category': 'Kehidupan',
      'items': [
        {
          'title': 'Belajar',
          'icon': '🎓',
          'pop': true,
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Templat Tugas',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          for (final group in dummyTemplates) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                group['category'] as String,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final item in (group['items'] as List<Map<String, dynamic>>))
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item['icon'] as String,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    title: Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item['pop'] == true) ...[
                          const Text(
                            '🔥',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                        ],
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context, {
                        'title': item['title'] as String,
                        'category': group['category'] as String,
                      });
                    },
                  ),
                ),
              ),
          ],
          // Opsi 'Buat Kustom' di bagian paling bawah list
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  title: const Text(
                    'Buat Kebiasaan Sendiri',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF2563EB),
                  ),
                  onTap: () {
                    Navigator.pop(context, 'custom');
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
