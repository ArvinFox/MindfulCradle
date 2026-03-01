import 'dart:convert';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('Background message received: ${message.messageId}');
  }
}

/// Notification service for handling push notifications and local reminders
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  // Notification channels
  static const String _channelId = 'mindful_cradle_reminders';
  static const String _channelName = 'Mindful Cradle Reminders';
  static const String _channelDescription =
      'Reminders for meditation, wellness, and companion chat';

  // Notification IDs for different reminder types
  static const int _meditationReminderId = 100;
  static const int _companionChatReminderId = 101;
  static const int _wellnessTipReminderId = 102;
  static const int _questionnairesReminderId = 103;
  static const int _hydrationReminderId = 104;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone database
      tz.initializeTimeZones();

      // Set timezone to device's local timezone
      // This automatically uses the device's timezone setting
      final String timeZoneName = DateTime.now().timeZoneName;
      try {
        final location = tz.getLocation(timeZoneName);
        tz.setLocalLocation(location);
      } catch (e) {
        // If device timezone not found in database, try common alternatives
        try {
          // Get UTC offset and try to find appropriate timezone
          final offset = DateTime.now().timeZoneOffset;
          if (kDebugMode) {
            debugPrint(
              'Device timezone "$timeZoneName" not found. Using UTC offset: $offset',
            );
          }
          // Default to UTC as fallback
          tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (e2) {
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
      }

      if (kDebugMode) {
        debugPrint('Timezone initialized: ${tz.local.name}');
        debugPrint('Device timezone: ${DateTime.now().timeZoneName}');
        debugPrint('UTC offset: ${DateTime.now().timeZoneOffset}');
      }

      // Initialize local notifications first (must be before permissions)
      await _initializeLocalNotifications();

      // Request permissions (both FCM and local notifications)
      await _requestPermissions();

      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();

      _initialized = true;
      if (kDebugMode) {
        debugPrint('NotificationService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing NotificationService: $e');
      }
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    // Request FCM permissions
    final NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint('FCM permission status: ${settings.authorizationStatus}');
    }

    // Request Android 13+ notification permissions through local notifications
    final androidImplementation = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      final granted = await androidImplementation
          .requestNotificationsPermission();
      if (kDebugMode) {
        debugPrint('Android notifications permission granted: $granted');
      }

      // Request exact alarm permission for Android 12+
      final exactAlarmGranted = await androidImplementation
          .requestExactAlarmsPermission();
      if (kDebugMode) {
        debugPrint('Exact alarms permission granted: $exactAlarmGranted');
      }
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get FCM token
    _fcmToken = await _fcm.getToken();
    if (kDebugMode) {
      debugPrint('FCM Token: $_fcmToken');
    }

    // Listen for token refresh
    _fcm.onTokenRefresh.listen((token) {
      _fcmToken = token;
      if (kDebugMode) {
        debugPrint('FCM Token refreshed: $token');
      }
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification when app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message.data);
      }
    });

    // Handle notification when app is in background and opened
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message.data);
    });
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Foreground message: ${message.notification?.title}');
    }

    // Show local notification when app is in foreground
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Mindful Cradle',
        body: message.notification!.body ?? '',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _handleNotificationTap(data);
    }
  }

  /// Handle notification tap navigation
  void _handleNotificationTap(Map<String, dynamic> data) {
    if (kDebugMode) {
      debugPrint('Notification tapped with data: $data');
    }
    // TODO: Implement navigation based on notification type
    // This can be enhanced to navigate to specific screens
  }

  /// Show a local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id ?? Random().nextInt(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedule a meditation reminder
  Future<void> scheduleMeditationReminder({
    required String language,
    required int hourOfDay,
    required int minute,
  }) async {
    final messages = _getMeditationMessages(language);
    final message = messages[Random().nextInt(messages.length)];

    await _scheduleNotification(
      id: _meditationReminderId,
      title: message['title']!,
      body: message['body']!,
      hourOfDay: hourOfDay,
      minute: minute,
      payload: jsonEncode({'type': 'meditation', 'route': '/meditation'}),
    );

    await _saveSchedule('meditation', hourOfDay, minute);
  }

  /// Schedule a companion chat reminder
  Future<void> scheduleCompanionChatReminder({
    required String language,
    required int hourOfDay,
    required int minute,
  }) async {
    final messages = _getCompanionMessages(language);
    final message = messages[Random().nextInt(messages.length)];

    await _scheduleNotification(
      id: _companionChatReminderId,
      title: message['title']!,
      body: message['body']!,
      hourOfDay: hourOfDay,
      minute: minute,
      payload: jsonEncode({'type': 'chat', 'route': '/chat'}),
    );

    await _saveSchedule('companion', hourOfDay, minute);
  }

  /// Schedule a wellness tip reminder
  Future<void> scheduleWellnessTipReminder({
    required String language,
    required int hourOfDay,
    required int minute,
  }) async {
    final messages = _getWellnessMessages(language);
    final message = messages[Random().nextInt(messages.length)];

    await _scheduleNotification(
      id: _wellnessTipReminderId,
      title: message['title']!,
      body: message['body']!,
      hourOfDay: hourOfDay,
      minute: minute,
      payload: jsonEncode({'type': 'wellness', 'route': '/home'}),
    );

    await _saveSchedule('wellness', hourOfDay, minute);
  }

  /// Schedule a questionnaires reminder
  Future<void> scheduleQuestionnairesReminder({
    required String language,
    required int hourOfDay,
    required int minute,
  }) async {
    final messages = _getQuestionnairesMessages(language);
    final message = messages[Random().nextInt(messages.length)];

    await _scheduleNotification(
      id: _questionnairesReminderId,
      title: message['title']!,
      body: message['body']!,
      hourOfDay: hourOfDay,
      minute: minute,
      payload: jsonEncode({
        'type': 'questionnaires',
        'route': '/questionnaires',
      }),
    );

    await _saveSchedule('questionnaires', hourOfDay, minute);
  }

  /// Schedule a hydration reminder
  Future<void> scheduleHydrationReminder({
    required String language,
    required int hourOfDay,
    required int minute,
  }) async {
    final messages = _getHydrationMessages(language);
    final message = messages[Random().nextInt(messages.length)];

    await _scheduleNotification(
      id: _hydrationReminderId,
      title: message['title']!,
      body: message['body']!,
      hourOfDay: hourOfDay,
      minute: minute,
      payload: jsonEncode({'type': 'hydration', 'route': '/home'}),
    );

    await _saveSchedule('hydration', hourOfDay, minute);
  }

  /// Schedule a notification at specific time daily
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hourOfDay,
    required int minute,
    String? payload,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hourOfDay,
        minute,
      );

      // If the scheduled time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      if (kDebugMode) {
        debugPrint('Current time: ${now.toString()}');
        debugPrint('Scheduled time: ${scheduledDate.toString()}');
        debugPrint('Time until notification: ${scheduledDate.difference(now)}');
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      if (kDebugMode) {
        debugPrint('✅ Successfully scheduled notification ID $id');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error scheduling notification ID $id: $e');
      }
      rethrow;
    }
  }

  /// Cancel a specific reminder
  Future<void> cancelReminder(String type) async {
    int id;
    switch (type) {
      case 'meditation':
        id = _meditationReminderId;
        break;
      case 'companion':
        id = _companionChatReminderId;
        break;
      case 'wellness':
        id = _wellnessTipReminderId;
        break;
      case 'questionnaires':
        id = _questionnairesReminderId;
        break;
      case 'hydration':
        id = _hydrationReminderId;
        break;
      default:
        return;
    }

    await _localNotifications.cancel(id);
    await _removeSchedule(type);

    if (kDebugMode) {
      debugPrint('Cancelled $type reminder');
    }
  }

  /// Cancel all reminders
  Future<void> cancelAllReminders() async {
    await _localNotifications.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_schedules');

    if (kDebugMode) {
      debugPrint('Cancelled all reminders');
    }
  }

  /// Save notification schedule to preferences
  Future<void> _saveSchedule(String type, int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    final schedules = prefs.getString('notification_schedules');
    final Map<String, dynamic> schedulesMap = schedules != null
        ? jsonDecode(schedules)
        : {};

    schedulesMap[type] = {'hour': hour, 'minute': minute, 'enabled': true};
    await prefs.setString('notification_schedules', jsonEncode(schedulesMap));
  }

  /// Remove notification schedule from preferences
  Future<void> _removeSchedule(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final schedules = prefs.getString('notification_schedules');
    if (schedules != null) {
      final Map<String, dynamic> schedulesMap = jsonDecode(schedules);
      schedulesMap.remove(type);
      await prefs.setString('notification_schedules', jsonEncode(schedulesMap));
    }
  }

  /// Get saved notification schedules
  Future<Map<String, dynamic>> getSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final schedules = prefs.getString('notification_schedules');
    return schedules != null ? jsonDecode(schedules) : {};
  }

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  // Notification message templates

  List<Map<String, String>> _getMeditationMessages(String language) {
    if (language == 'si') {
      return [
        {
          'title': '🧘‍♀️ භාවනා කාලය',
          'body': 'ඔබේ මනස සහ ශරීරය සනීප කර ගැනීමට භාවනා වීඩියෝවක් නරඹන්න.',
        },
        {
          'title': '✨ විවේක කාලය',
          'body': 'අද ඔබේ දිනය සඳහා භාවනා වැඩසටහනක් අත්විඳින්න.',
        },
        {
          'title': '🌸 මනසේ සාමය',
          'body': 'නිවැරදි මනසක් සඳහා භාවනා වීඩියෝවක් නරඹන්න.',
        },
      ];
    } else {
      return [
        {
          'title': '🧘‍♀️ Meditation Time',
          'body': 'Watch a meditation video to relax your mind and body.',
        },
        {
          'title': '✨ Relaxation Break',
          'body': 'Take a moment for yourself. Try a meditation session today.',
        },
        {
          'title': '🌸 Inner Peace',
          'body': 'Watch a meditation video for a peaceful mind.',
        },
      ];
    }
  }

  List<Map<String, String>> _getCompanionMessages(String language) {
    if (language == 'si') {
      return [
        {
          'title': '💬 ඔබේ සහායකයා මෙහි සිටී',
          'body': 'තනිව හැඟෙනවාද? ඔබේ Mindful Cradle සහායකයා සමඟ කතා කරන්න.',
        },
        {
          'title': '🤗 අප සමඟ කතා කරන්න',
          'body':
              'ඔබට කිසියම් ප්‍රශ්නයක් තිබේද? AI සහායකයා ඔබට උදව් කිරීමට සූදානම්.',
        },
        {
          'title': '💙 ඔබ තනි නැත',
          'body': 'ඕනෑම වේලාවක ඔබේ සහායකයා සමඟ සංවාදයක් ආරම්භ කරන්න.',
        },
      ];
    } else {
      return [
        {
          'title': '💬 Your Companion is Here',
          'body': 'Feeling alone? Chat with your Mindful Cradle companion.',
        },
        {
          'title': '🤗 Let\'s Talk',
          'body': 'Have any questions? Your AI companion is ready to help.',
        },
        {
          'title': '💙 You\'re Not Alone',
          'body': 'Start a conversation with your companion anytime.',
        },
      ];
    }
  }

  List<Map<String, String>> _getWellnessMessages(String language) {
    if (language == 'si') {
      return [
        {
          'title': '🌟 සෞඛ්‍ය උපදෙස්',
          'body': 'අද සඳහා ඔබේ දෛනික සෞඛ්‍ය ක්‍රියාකාරකම් පරීක්ෂා කරන්න.',
        },
        {
          'title': '💪 ඔබේ සෞඛ්‍යය',
          'body': 'ඔබේ සහ ඔබේ දරුවාගේ යහපැවැත්ම පිළිබඳව සිතන්න.',
        },
        {
          'title': '🌱 සෞඛ්‍ය සටහනක්',
          'body': 'අද ඔබ දැනෙන ආකාරය සටහන් කර ගැනීමට අමතක නොකරන්න.',
        },
      ];
    } else {
      return [
        {
          'title': '🌟 Wellness Tip',
          'body': 'Check your daily wellness activities for today.',
        },
        {
          'title': '💪 Your Health Matters',
          'body':
              'Take a moment to think about your and your baby\'s wellbeing.',
        },
        {
          'title': '🌱 Health Check-in',
          'body': 'Don\'t forget to track how you\'re feeling today.',
        },
      ];
    }
  }

  List<Map<String, String>> _getQuestionnairesMessages(String language) {
    if (language == 'si') {
      return [
        {
          'title': '📋 මානසික සෞඛ්‍ය පරීක්ෂාව',
          'body':
              'ඔබේ මානසික යහපැවැත්ම පරීක්ෂා කිරීමට ප්‍රශ්නාවලියක් සම්පූර්ණ කරන්න.',
        },
        {
          'title': '🎯 සතියේ පරීක්ෂාව',
          'body': 'මෙම සතියේ ඔබේ මානසික සෞඛ්‍යය පරීක්ෂා කර ගන්න.',
        },
      ];
    } else {
      return [
        {
          'title': '📋 Mental Health Check',
          'body': 'Complete a questionnaire to assess your mental wellbeing.',
        },
        {
          'title': '🎯 Weekly Assessment',
          'body': 'Check your mental health progress this week.',
        },
      ];
    }
  }

  List<Map<String, String>> _getHydrationMessages(String language) {
    if (language == 'si') {
      return [
        {
          'title': '💧 ජලය පානය කරන්න',
          'body':
              'ඔබේ ශරීරය සෞඛ්‍යයෙන් තබා ගැනීමට ජලය පානය කිරීමට අමතක නොකරන්න.',
        },
        {
          'title': '🚰 ජලය කාලය',
          'body': 'ඔබ සහ ඔබේ දරුවා සඳහා ජලය පානය කරන්න.',
        },
      ];
    } else {
      return [
        {
          'title': '💧 Stay Hydrated',
          'body': 'Don\'t forget to drink water to keep yourself healthy.',
        },
        {
          'title': '🚰 Water Time',
          'body': 'Drink some water for you and your baby.',
        },
      ];
    }
  }

  /// Set up default reminders (recommended times)
  Future<void> setupDefaultReminders(String language) async {
    // Morning meditation: 8:00 AM
    await scheduleMeditationReminder(
      language: language,
      hourOfDay: 8,
      minute: 0,
    );

    // Afternoon companion chat: 2:00 PM
    await scheduleCompanionChatReminder(
      language: language,
      hourOfDay: 14,
      minute: 0,
    );

    // Evening wellness check: 7:00 PM
    await scheduleWellnessTipReminder(
      language: language,
      hourOfDay: 19,
      minute: 0,
    );

    // Hydration reminders: 10:00 AM
    await scheduleHydrationReminder(
      language: language,
      hourOfDay: 10,
      minute: 0,
    );

    if (kDebugMode) {
      debugPrint('Default reminders set up successfully');
    }
  }
}
