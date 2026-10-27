import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Konfigurasi zona waktu lokal agar sesuai dengan jam perangkat
  void _configureLocalTimeZone() {
    tz.initializeTimeZones();
    try {
      final offsetHours = DateTime.now().timeZoneOffset.inHours;
      String locationName = 'Asia/Jakarta'; // Default zona waktu Indonesia (WIB)

      if (offsetHours == 8) {
        locationName = 'Asia/Makassar'; // WITA
      } else if (offsetHours == 9) {
        locationName = 'Asia/Jayapura'; // WIT
      } else {
        // Coba cocokkan dengan lokasi lain di timezone database
        final systemTz = DateTime.now().timeZoneName;
        if (tz.timeZoneDatabase.locations.containsKey(systemTz)) {
          locationName = systemTz;
        } else {
          final matchingLocation = tz.timeZoneDatabase.locations.values.firstWhere(
            (loc) => loc.currentTimeZone.offset == DateTime.now().timeZoneOffset,
            orElse: () => tz.getLocation('Asia/Jakarta'),
          );
          locationName = matchingLocation.name;
        }
      }
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      // Fallback aman jika terjadi anomali sistem
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }
  }

  /// Inisialisasi plugin notifikasi dan timezone
  Future<void> init() async {
    if (_isInitialized) return;

    _configureLocalTimeZone();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notificationsPlugin.initialize(settings: initSettings);
      _isInitialized = true;
    } catch (_) {
      // Menangani environment tanpa native channel (misal saat flutter test)
    }
  }

  /// Meminta izin notifikasi (khusus Android 13+ dan iOS).
  ///
  /// Setiap permintaan izin dibungkus try-catch terpisah sehingga penolakan
  /// atau error pada satu izin tidak menghambat izin lain maupun alur utama
  /// aplikasi (tidak pernah melempar exception ke pemanggil).
  Future<void> requestPermission() async {
    // 1. Izin notifikasi Android 13+ (POST_NOTIFICATIONS)
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    } catch (_) {
      // Izin ditolak / environment non-mobile (test): lanjutkan tanpa crash
    }

    // 2. Izin alarm presisi Android 12+/14+ (SCHEDULE_EXACT_ALARM)
    try {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestExactAlarmsPermission();
    } catch (_) {
      // Izin ditolak / tidak didukung: lanjutkan tanpa crash
    }

    // 3. Izin notifikasi iOS
    try {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {
      // Mengabaikan error pada environment non-iOS/test
    }
  }

  /// Menjadwalkan pengingat harian pada jam dan menit tertentu
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    try {
      if (!_isInitialized) {
        await init();
      }

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // Jika waktu hari ini sudah terlewat, jadwalkan mulai besok
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'habit_daily_reminders',
        'Pengingat RutinKu',
        channelDescription: 'Notifikasi pengingat harian untuk rutinitas RutinKu',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // Mengabaikan pemanggilan native pada platform yang tidak mendukung (cth. widget test)
    }
  }

  /// Membatalkan jadwal notifikasi berdasarkan ID
  Future<void> cancelReminder(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
    } catch (_) {
      // Mengabaikan pemanggilan native pada environment test
    }
  }

  /// Membatalkan semua notifikasi
  Future<void> cancelAllReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {
      // Mengabaikan pemanggilan native pada environment test
    }
  }
}
