import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit_model.dart';
import '../repositories/habit_repository.dart';
import '../repositories/sync_repository.dart';
import '../services/app_logger.dart';
import '../services/notification_service.dart';
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

/// Membatalkan semua pengingat di HP (dipakai saat data lokal berganti
/// akun). Bisa diganti di tes.
final autoSyncCancelRemindersProvider = Provider<Future<void> Function()>(
    (ref) => NotificationService().cancelAllReminders);

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

  /// ID akun pemilik data rutinitas lokal. Data lokal (SharedPreferences)
  /// dipakai bersama semua akun di HP yang sama, jadi harus ditandai agar
  /// rutinitas akun A tidak muncul (dan ter-backup) di akun B.
  static const String ownerKey = 'rutinku_data_owner';

  /// Kunci yang disimpan per akun saat berganti akun.
  static const List<String> perAccountKeys = [
    HabitRepository.storageKey,
    lastSyncKey,
    pendingKey,
  ];

  /// Kunci simpanan data lokal milik akun [userId] yang sedang tidak login.
  static String stashKey(String key, String userId) => '${key}__$userId';

  late SyncRepository _repo;
  late Clock _clock;
  late Duration _debounce;
  late Duration _retryDelay;

  Timer? _debounceTimer;
  Timer? _retryTimer;
  String? _lastSeenJson;
  String? _lastSyncedJson;
  bool _disposed = false;

  /// True selama cek awal: perubahan daftar rutinitas yang dipicu oleh
  /// pergantian akun / restore otomatis tidak boleh memicu upload.
  bool _initializing = false;

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

  /// Dipanggil sebelum logout: kirim perubahan yang tertunda (jika bisa),
  /// lalu pindahkan data lokal ke simpanan milik akun ini dan kosongkan
  /// layar, agar akun berikutnya tidak melihat rutinitas akun ini. Data
  /// tidak dihapus: akan dikembalikan saat akun yang sama login lagi.
  Future<void> prepareLogout() async {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    try {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getBool(pendingKey) ?? false;
      if (_loggedIn() &&
          state.enabled &&
          state.status != AutoSyncStatus.conflict &&
          (pending ||
              state.status == AutoSyncStatus.pending ||
              state.status == AutoSyncStatus.error)) {
        await _backup(scheduleRetry: false);
      }
      final owner = prefs.getString(ownerKey) ?? _userId();
      if (owner != null) await _stash(prefs, owner);
      await prefs.remove(ownerKey);
      await _cancelReminders();
      _lastSyncedJson = null;
      _update((s) => const AutoSyncState(status: AutoSyncStatus.notLoggedIn));
      ref.invalidate(habitNotifierProvider);
      _log.info('Data lokal disimpan untuk akun sebelumnya (logout)');
    } catch (e, s) {
      _log.warning('Gagal menyiapkan logout', e, s);
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
    _update((s) => s.copyWith(enabled: enabled));

    if (!_loggedIn()) {
      _update((s) => s.copyWith(status: AutoSyncStatus.notLoggedIn));
      return;
    }

    _initializing = true;
    try {
      // Pastikan data lokal milik akun yang login (berlaku juga saat
      // sinkron otomatis dimatikan).
      await _ensureOwner(prefs);
      if (_disposed) return;
      final last = DateTime.tryParse(prefs.getString(lastSyncKey) ?? '');
      _update((s) => s.copyWith(lastSyncedAt: last));
      if (!enabled) {
        _update((s) => s.copyWith(status: AutoSyncStatus.off));
        return;
      }
      await _initialSync(prefs, hasSyncedBefore: last != null);
    } finally {
      _initializing = false;
    }
    // Perubahan pengguna selama cek awal tetap dikirim.
    if (state.status == AutoSyncStatus.synced &&
        (prefs.getString(HabitRepository.storageKey) ?? '[]') !=
            _lastSyncedJson) {
      _onLocalChange();
    }
  }

  /// Menukar data lokal bila milik akun lain: data akun lama disimpan
  /// (tidak dihapus), data akun ini dikembalikan dari simpanan bila ada.
  /// Data tanpa pemilik (versi lama aplikasi) dianggap milik akun ini.
  Future<void> _ensureOwner(SharedPreferences prefs) async {
    final uid = _userId();
    if (uid == null) return;
    final owner = prefs.getString(ownerKey);
    if (owner == uid) return;

    var changed = false;
    if (owner != null) {
      await _stash(prefs, owner);
      changed = true;
      _log.info('Data lokal milik akun lain disimpan, berganti akun');
    }
    final restored = await _unstash(prefs, uid);
    changed = changed || restored;
    await prefs.setString(ownerKey, uid);

    if (changed) {
      _lastSyncedJson = null;
      await _cancelReminders();
      ref.invalidate(habitNotifierProvider);
    }
  }

  /// Memindahkan data lokal saat ini ke simpanan milik [userId].
  Future<void> _stash(SharedPreferences prefs, String userId) async {
    for (final key in perAccountKeys) {
      final value = prefs.get(key);
      final target = stashKey(key, userId);
      if (value is String) {
        await prefs.setString(target, value);
      } else if (value is bool) {
        await prefs.setBool(target, value);
      } else {
        await prefs.remove(target);
      }
      await prefs.remove(key);
    }
  }

  /// Mengembalikan simpanan milik [userId]; false bila tidak ada.
  Future<bool> _unstash(SharedPreferences prefs, String userId) async {
    final hasStash = perAccountKeys
        .any((key) => prefs.containsKey(stashKey(key, userId)));
    if (!hasStash) return false;
    for (final key in perAccountKeys) {
      final source = stashKey(key, userId);
      final value = prefs.get(source);
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else {
        await prefs.remove(key);
      }
      await prefs.remove(source);
    }
    _log.info('Data lokal akun ini dikembalikan dari simpanan');
    return true;
  }

  Future<void> _cancelReminders() async {
    try {
      await ref.read(autoSyncCancelRemindersProvider)();
    } catch (e, s) {
      _log.warning('Gagal membatalkan pengingat', e, s);
    }
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
    if (_initializing) return;
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

  Future<void> _backup({bool scheduleRetry = true}) async {
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
      _failed(scheduleRetry: scheduleRetry);
    }
  }

  void _failed({bool scheduleRetry = true}) {
    if (_disposed) return;
    _update((s) => s.copyWith(status: AutoSyncStatus.error));
    _retryTimer?.cancel();
    if (scheduleRetry) _retryTimer = Timer(_retryDelay, _backup);
  }

  Future<void> _markSynced(SharedPreferences prefs) async {
    final now = _clock();
    await prefs.setString(lastSyncKey, now.toIso8601String());
    await prefs.setBool(pendingKey, false);
    _update((s) => s.copyWith(status: AutoSyncStatus.synced, lastSyncedAt: now));
  }

  String? _userId() {
    try {
      return _repo.currentUserId;
    } catch (_) {
      return null;
    }
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
