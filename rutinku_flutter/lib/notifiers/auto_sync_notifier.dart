import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit_model.dart';
import '../repositories/habit_repository.dart';
import '../repositories/sync_repository.dart';
import '../services/app_logger.dart';
import 'habit_notifier.dart';
import 'sync_notifier.dart';
import 'today_notifier.dart';

/// Status sinkronisasi otomatis ke Supabase.
enum AutoSyncStatus {
  /// Belum login (atau Supabase tidak tersedia): tidak ada sinkronisasi.
  notLoggedIn,

  /// Dimatikan oleh pengguna lewat sakelar di layar Cloud Sync.
  off,

  /// Ada perubahan lokal yang menunggu dikirim (jeda / offline).
  pending,

  /// Sedang mengirim / mengambil data.
  syncing,

  /// Data HP dan cloud sama.
  synced,

  /// Percobaan terakhir gagal (mis. tidak ada internet); akan dicoba lagi.
  error,

  /// HP dan cloud punya data berbeda dan HP ini belum pernah sinkron:
  /// pengguna harus memilih Backup (data HP) atau Restore (data cloud).
  conflict,
}

@immutable
class AutoSyncState {
  const AutoSyncState({
    this.status = AutoSyncStatus.notLoggedIn,
    this.enabled = true,
    this.lastSyncedAt,
  });

  final AutoSyncStatus status;
  final bool enabled;
  final DateTime? lastSyncedAt;

  AutoSyncState copyWith({
    AutoSyncStatus? status,
    bool? enabled,
    DateTime? lastSyncedAt,
  }) =>
      AutoSyncState(
        status: status ?? this.status,
        enabled: enabled ?? this.enabled,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
}

/// Jeda sebelum perubahan dikirim (beberapa ketukan beruntun = 1 upload).
/// Bisa diganti di tes.
final autoSyncDebounceProvider =
    Provider<Duration>((ref) => const Duration(seconds: 5));

/// Jeda percobaan ulang setelah gagal (mis. offline).
final autoSyncRetryProvider =
    Provider<Duration>((ref) => const Duration(minutes: 1));

/// Sinkronisasi otomatis "snapshot" ke Supabase (tabel `user_data`):
/// - backup otomatis beberapa detik setelah data rutinitas berubah;
/// - restore otomatis saat login di HP yang datanya masih kosong;
/// - berhenti dan meminta pilihan pengguna bila data HP & cloud berbeda dan
///   HP ini belum pernah sinkron (agar cloud tidak tertimpa diam-diam);
/// - gagal/offline -> tetap "menunggu", dicoba lagi otomatis dan saat
///   aplikasi dibuka kembali.
///
/// autoDispose: hidup selama `MainScreen` (setelah login) memakainya, dan
/// dibangun ulang (cek awal lagi) setelah logout -> login.
final autoSyncProvider =
    NotifierProvider.autoDispose<AutoSyncNotifier, AutoSyncState>(
        AutoSyncNotifier.new);

class AutoSyncNotifier extends Notifier<AutoSyncState> {
  static final _log = AppLogger.get('autosync');

  static const String enabledKey = 'rutinku_auto_sync_enabled';
  static const String lastSyncKey = 'rutinku_last_sync_at';
  static const String pendingKey = 'rutinku_sync_pending';

  late SyncRepository _repo;
  late Clock _clock;
  late Duration _debounce;
  late Duration _retryDelay;

  Timer? _debounceTimer;
  Timer? _retryTimer;
  String? _lastSeenJson;
  String? _lastSyncedJson;
  bool _disposed = false;

  @override
  AutoSyncState build() {
    _repo = ref.watch(syncRepositoryProvider);
    _clock = ref.watch(clockProvider);
    _debounce = ref.watch(autoSyncDebounceProvider);
    _retryDelay = ref.watch(autoSyncRetryProvider);
    _disposed = false;

    final observer = _ResumeObserver(_onResume);
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() {
      _disposed = true;
      _debounceTimer?.cancel();
      _retryTimer?.cancel();
      WidgetsBinding.instance.removeObserver(observer);
    });

    // Setiap perubahan daftar rutinitas (tambah/edit/centang/hapus/restore).
    ref.listen<AsyncValue<List<HabitModel>>>(habitNotifierProvider,
        (_, next) {
      final habits = next.value;
      if (habits == null || next.isLoading) return;
      final json = jsonEncode(habits.map((h) => h.toMap()).toList());
      final first = _lastSeenJson == null;
      if (json == _lastSeenJson) return;
      _lastSeenJson = json;
      if (!first) _onLocalChange();
    }, fireImmediately: true);

    Future.microtask(_start);
    return const AutoSyncState();
  }

  // ---------------------------------------------------------------------------
  // API untuk UI
  // ---------------------------------------------------------------------------

  /// Sakelar "Sinkron otomatis" di layar Cloud Sync.
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, enabled);
    _log.info('Sinkron otomatis ${enabled ? 'dinyalakan' : 'dimatikan'}');
    if (!enabled) {
      _debounceTimer?.cancel();
      _retryTimer?.cancel();
      _update((s) => s.copyWith(status: AutoSyncStatus.off, enabled: false));
      return;
    }
    _update((s) => s.copyWith(enabled: true));
    await _start();
  }

  /// Tombol "Sinkronkan sekarang".
  Future<void> syncNow() async {
    if (!state.enabled || state.status == AutoSyncStatus.conflict) return;
    if (!_loggedIn()) return;
    await _backup();
  }

  /// Dipanggil setelah Backup/Restore manual berhasil: data HP & cloud kini
  /// sama, konflik (jika ada) selesai.
  Future<void> recordManualSync() async {
    // Hanya memperbarui status; tidak boleh menggagalkan backup/restore
    // manual yang sudah berhasil.
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastSyncedJson = prefs.getString(HabitRepository.storageKey) ?? '[]';
      await _markSynced(prefs);
    } catch (e, s) {
      _log.warning('Gagal mencatat sinkron manual', e, s);
    }
  }

  // ---------------------------------------------------------------------------
  // Alur internal
  // ---------------------------------------------------------------------------

  Future<void> _start() async {
    try {
      await _startUnsafe();
    } catch (e, st) {
      // Mis. penyimpanan lokal tidak tersedia: jangan sampai crash.
      _log.warning('Sinkron otomatis tidak dapat dimulai', e, st);
      _update((s) => s.copyWith(status: AutoSyncStatus.notLoggedIn));
    }
  }

  Future<void> _startUnsafe() async {
    if (_disposed) return;
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    final enabled = prefs.getBool(enabledKey) ?? true;
    final last = DateTime.tryParse(prefs.getString(lastSyncKey) ?? '');
    _update((s) => s.copyWith(enabled: enabled, lastSyncedAt: last));

    if (!_loggedIn()) {
      _update((s) => s.copyWith(status: AutoSyncStatus.notLoggedIn));
      return;
    }
    if (!enabled) {
      _update((s) => s.copyWith(status: AutoSyncStatus.off));
      return;
    }
    await _initialSync(prefs, hasSyncedBefore: last != null);
  }

  Future<void> _initialSync(
    SharedPreferences prefs, {
    required bool hasSyncedBefore,
  }) async {
    final localJson = prefs.getString(HabitRepository.storageKey) ?? '[]';
    final local = _decode(localJson);
    _update((s) => s.copyWith(status: AutoSyncStatus.syncing));
    try {
      final cloud = await _repo.fetchHabitsFromCloud();
      if (_disposed) return;

      if (local.isEmpty && cloud.isNotEmpty) {
        // HP baru / data HP kosong -> pulihkan dari cloud.
        await _repo.restoreHabitsFromCloud();
        _log.info('Restore otomatis: ${cloud.length} rutinitas dari cloud');
        _lastSyncedJson = prefs.getString(HabitRepository.storageKey) ?? '[]';
        ref.invalidate(habitNotifierProvider);
        await _markSynced(prefs);
        return;
      }
      if (cloud.isEmpty) {
        if (local.isEmpty) {
          _lastSyncedJson = localJson;
          await _markSynced(prefs);
        } else {
          await _backup();
        }
        return;
      }
      final same = _encode(local) == _encode(cloud);
      if (same) {
        _lastSyncedJson = localJson;
        await _markSynced(prefs);
        return;
      }
      if (!hasSyncedBefore) {
        _log.warning('Data HP & cloud berbeda, menunggu pilihan pengguna');
        _update((s) => s.copyWith(status: AutoSyncStatus.conflict));
        return;
      }
      // HP ini sudah pernah sinkron: data HP adalah yang terbaru.
      await _backup();
    } catch (e, s) {
      _log.warning('Sinkron awal gagal', e, s);
      _failed();
    }
  }

  void _onLocalChange() {
    if (!state.enabled ||
        state.status == AutoSyncStatus.conflict ||
        state.status == AutoSyncStatus.notLoggedIn ||
        state.status == AutoSyncStatus.off) {
      return;
    }
    if (!_loggedIn()) return;
    _update((s) => s.copyWith(status: AutoSyncStatus.pending));
    SharedPreferences.getInstance()
        .then((p) => p.setBool(pendingKey, true))
        .catchError((Object _) => false);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, _backup);
  }

  void _onResume() {
    if (_disposed || !state.enabled) return;
    if (state.status == AutoSyncStatus.pending ||
        state.status == AutoSyncStatus.error) {
      _backup();
    }
  }

  Future<void> _backup() async {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    if (_disposed) return;
    final SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e, s) {
      _log.warning('Penyimpanan lokal tidak tersedia', e, s);
      return;
    }
    final localJson = prefs.getString(HabitRepository.storageKey) ?? '[]';
    if (localJson == _lastSyncedJson) {
      await _markSynced(prefs);
      return;
    }
    _update((s) => s.copyWith(status: AutoSyncStatus.syncing));
    try {
      await _repo.backupHabitsToCloud();
      if (_disposed) return;
      _lastSyncedJson = localJson;
      _log.info('Backup otomatis berhasil');
      await _markSynced(prefs);
    } catch (e, s) {
      _log.warning('Backup otomatis gagal, akan dicoba lagi', e, s);
      await prefs.setBool(pendingKey, true);
      _failed();
    }
  }

  void _failed() {
    if (_disposed) return;
    _update((s) => s.copyWith(status: AutoSyncStatus.error));
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, _backup);
  }

  Future<void> _markSynced(SharedPreferences prefs) async {
    final now = _clock();
    await prefs.setString(lastSyncKey, now.toIso8601String());
    await prefs.setBool(pendingKey, false);
    _update((s) => s.copyWith(status: AutoSyncStatus.synced, lastSyncedAt: now));
  }

  bool _loggedIn() {
    try {
      return _repo.isLoggedIn;
    } catch (_) {
      // Supabase belum diinisialisasi (mis. di widget test) = belum login.
      return false;
    }
  }

  /// Mengubah state hanya selama notifier masih hidup (aman dipanggil dari
  /// callback async yang selesai setelah layar ditutup).
  void _update(AutoSyncState Function(AutoSyncState) change) {
    if (!_disposed) state = change(state);
  }

  static List<HabitModel> _decode(String json) {
    try {
      final list = jsonDecode(json);
      if (list is! List) return [];
      return list
          .map((e) => HabitModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String _encode(List<HabitModel> habits) =>
      jsonEncode(habits.map((h) => h.toMap()).toList());
}

class _ResumeObserver extends WidgetsBindingObserver {
  _ResumeObserver(this.onResume);

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResume();
  }
}
