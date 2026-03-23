import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/colors.dart';
import '../../services/notification_service.dart';
import '../../utils/translate.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  Map<String, dynamic> _schedules = {};
  bool _isLoading = true;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndLoadSchedules();
  }

  Future<void> _checkPermissionsAndLoadSchedules() async {
    if (kDebugMode) {
      debugPrint('_checkPermissionsAndLoadSchedules called');
    }

    setState(() => _isLoading = true);

    // Check if notifications are enabled
    _notificationsEnabled = await _notificationService
        .areNotificationsEnabled();

    if (kDebugMode) {
      debugPrint('Notifications enabled: $_notificationsEnabled');
    }

    if (_notificationsEnabled) {
      await _loadSchedules();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSchedules() async {
    try {
      final schedules = await _notificationService.getSchedules();
      if (mounted) {
        setState(() {
          _schedules = schedules;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _requestPermissions() async {
    if (kDebugMode) {
      debugPrint('Requesting notification permissions...');
    }

    try {
      // First check the current status
      final currentStatus = await Permission.notification.status;
      if (kDebugMode) {
        debugPrint('Current permission status: $currentStatus');
      }

      if (currentStatus.isPermanentlyDenied) {
        if (kDebugMode) {
          debugPrint('Permission permanently denied, showing instructions');
        }
        // Show instructions dialog instead of directly opening settings
        _showPermissionInstructionsDialog();
        return;
      }

      final granted = await _notificationService.requestPermissions();

      if (kDebugMode) {
        debugPrint('Permission granted: $granted');
      }

      if (mounted) {
        setState(() => _notificationsEnabled = granted);
        if (granted) {
          await _loadSchedules();
          if (kDebugMode) {
            debugPrint('Permissions granted, loading schedules');
          }
        } else {
          if (kDebugMode) {
            debugPrint('Permissions not granted');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error requesting permissions: $e');
      }
    }
  }

  void _showPermissionInstructionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Enable Notifications',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To receive meditation and wellness reminders, you need to enable notifications for this app.',
                style: GoogleFonts.roboto(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Follow these steps:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Go to Settings\n2. Tap "Notifications"\n3. Turn on "Allow Notifications"',
                style: GoogleFonts.roboto(fontSize: 14, height: 1.6),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Open app settings
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setupDefaultReminders() async {
    final lang = context.currentLang;

    try {
      await _notificationService.setupDefaultReminders(lang);
      await _loadSchedules();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t.notifications('defaultRemindersSet')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _scheduleReminder(String type) async {
    final lang = context.currentLang;

    // Show time picker
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    try {
      switch (type) {
        case 'meditation':
          await _notificationService.scheduleMeditationReminder(
            language: lang,
            hourOfDay: pickedTime.hour,
            minute: pickedTime.minute,
          );
          break;
        case 'companion':
          await _notificationService.scheduleCompanionChatReminder(
            language: lang,
            hourOfDay: pickedTime.hour,
            minute: pickedTime.minute,
          );
          break;
        case 'wellness':
          await _notificationService.scheduleWellnessTipReminder(
            language: lang,
            hourOfDay: pickedTime.hour,
            minute: pickedTime.minute,
          );
          break;
        case 'questionnaires':
          await _notificationService.scheduleQuestionnairesReminder(
            language: lang,
            hourOfDay: pickedTime.hour,
            minute: pickedTime.minute,
          );
          break;
        case 'hydration':
          await _notificationService.scheduleHydrationReminder(
            language: lang,
            hourOfDay: pickedTime.hour,
            minute: pickedTime.minute,
          );
          break;
      }

      await _loadSchedules();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t.notifications('reminderScheduled')),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _cancelReminder(String type) async {
    try {
      await _notificationService.cancelReminder(type);
      await _loadSchedules();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t.notifications('reminderCancelled')),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  Widget _buildPermissionPrompt() {
    if (kDebugMode) {
      debugPrint('_buildPermissionPrompt called');
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Notifications Disabled',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To receive reminders for meditation, wellness activities, and companion chats, you need to enable notifications.',
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (kDebugMode) {
                    debugPrint('Enable Notifications button pressed');
                  }
                  _requestPermissions();
                },
                icon: const Icon(Icons.notifications_active),
                label: Text(
                  'Enable Notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint(
        'Build called - _isLoading: $_isLoading, _notificationsEnabled: $_notificationsEnabled',
      );
    }

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.t.notifications('notificationSettings'),
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 18 : 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_notificationsEnabled
          ? _buildPermissionPrompt()
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              color: AppColors.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                context.t.notifications(
                                  'notificationDescription',
                                ),
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Setup Default Reminders Button
                      if (_schedules.isEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _setupDefaultReminders,
                            icon: const Icon(Icons.auto_awesome),
                            label: Text(
                              context.t.notifications('setupDefaultReminders'),
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                      if (_schedules.isNotEmpty) ...[
                        Text(
                          context.t.notifications('customizeReminders'),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Meditation Reminders
                      _buildReminderCard(
                        type: 'meditation',
                        icon: Icons.self_improvement,
                        title: context.t.notifications('meditationReminders'),
                        color: Colors.purple,
                      ),

                      const SizedBox(height: 12),

                      // Companion Chat Reminders
                      _buildReminderCard(
                        type: 'companion',
                        icon: Icons.chat_bubble_outline,
                        title: context.t.notifications(
                          'companionChatReminders',
                        ),
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 12),

                      // Wellness Reminders
                      _buildReminderCard(
                        type: 'wellness',
                        icon: Icons.favorite,
                        title: context.t.notifications('wellnessReminders'),
                        color: Colors.pink,
                      ),

                      const SizedBox(height: 12),

                      // Questionnaires Reminders
                      _buildReminderCard(
                        type: 'questionnaires',
                        icon: Icons.assignment,
                        title: context.t.notifications(
                          'questionnairesReminders',
                        ),
                        color: Colors.teal,
                      ),

                      const SizedBox(height: 12),

                      // Hydration Reminders
                      _buildReminderCard(
                        type: 'hydration',
                        icon: Icons.water_drop,
                        title: context.t.notifications('hydrationReminders'),
                        color: Colors.cyan,
                      ),

                      const SizedBox(height: 24),

                      // Cancel All Button
                      if (_schedules.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    context.t.common('confirm'),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  content: Text(
                                    context.t.notifications(
                                      'allRemindersCancelled',
                                    ),
                                    style: GoogleFonts.roboto(),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(
                                        context.isSinhala
                                            ? 'නැත'
                                            : context.t.common('cancel'),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        context.isSinhala
                                            ? 'ඔව්'
                                            : context.t.common('confirm'),
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                await _notificationService.cancelAllReminders();
                                await _loadSchedules();
                              }
                            },
                            icon: const Icon(Icons.cancel),
                            label: Text(
                              context.t.notifications('disableNotifications'),
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildReminderCard({
    required String type,
    required IconData icon,
    required String title,
    required Color color,
  }) {
    final isScheduled = _schedules.containsKey(type);
    final schedule = _schedules[type];
    final hour = schedule?['hour'] ?? 0;
    final minute = schedule?['minute'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isScheduled)
                    Text(
                      _formatTime(hour, minute),
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            if (isScheduled)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _cancelReminder(type),
                tooltip: context.t.common('delete'),
              ),
            IconButton(
              icon: Icon(
                isScheduled ? Icons.edit : Icons.add_alarm,
                color: AppColors.primary,
              ),
              onPressed: () => _scheduleReminder(type),
              tooltip: context.t.notifications('setTime'),
            ),
          ],
        ),
      ),
    );
  }
}
