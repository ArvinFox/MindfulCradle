import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/colors.dart';
import '../../services/notification_service.dart';
import '../../utils/translate.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/app_background.dart';

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
      AppSnackBar.success(
        context,
        context.t.notifications('defaultRemindersSet'),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        'Error: $e',
        duration: const Duration(seconds: 3),
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
      AppSnackBar.success(
        context,
        context.t.notifications('reminderScheduled'),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        'Error: $e',
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _cancelReminder(String type) async {
    try {
      await _notificationService.cancelReminder(type);
      await _loadSchedules();

      if (!mounted) return;
      AppSnackBar.warning(
        context,
        context.t.notifications('reminderCancelled'),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        'Error: $e',
        duration: const Duration(seconds: 3),
      );
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  Widget _buildPermissionPrompt({required bool isMobile}) {
    if (kDebugMode) {
      debugPrint('_buildPermissionPrompt called');
    }

    final isSinhala = context.isSinhala;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 28,
          vertical: isMobile ? 18 : 24,
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 680),
          padding: EdgeInsets.all(isMobile ? 22 : 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.10),
                AppColors.accent.withValues(alpha: 0.16),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isMobile ? 68 : 76,
                height: isMobile ? 68 : 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_off_rounded,
                  size: isMobile ? 32 : 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.t.notifications('notificationsDisabled'),
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 20 : 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                context.t.notifications('enableNotificationsDescription'),
                style: GoogleFonts.roboto(
                  fontSize: isMobile ? 14 : 15,
                  color: AppColors.text.withValues(alpha: 0.85),
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (kDebugMode) {
                      debugPrint('Enable Notifications button pressed');
                    }
                    _requestPermissions();
                  },
                  icon: Icon(Icons.notifications_active_rounded),
                  label: Text(
                    context.t.notifications('enableNotifications'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              if (!isSinhala) ...[
                const SizedBox(height: 14),
                Text(
                  'You can change this anytime from system settings.',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.text.withValues(alpha: 0.65),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard({required bool isMobile}) {
    final activeCount = _schedules.length;
    final isEnabled = _notificationsEnabled;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 48 : 54,
            height: isMobile ? 48 : 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.notifications('notificationSettings'),
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEnabled
                      ? '$activeCount ${context.t.notifications('customizeReminders').toLowerCase()}'
                      : context.t.notifications('notificationsDisabled'),
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: AppColors.text.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isEnabled ? Colors.green : Colors.orange).withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isEnabled
                  ? context.t.common('yes').toUpperCase()
                  : context.t.common('no').toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isEnabled ? Colors.green[700] : Colors.orange[700],
              ),
            ),
          ),
        ],
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.t.notifications('notificationSettings'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.text,
          ),
        ),
      ),
      body: AppBackground(
        child: _isLoading
            ? const SafeArea(
                top: false,
                child: Center(child: CircularProgressIndicator()),
              )
            : !_notificationsEnabled
            ? SafeArea(
                top: false,
                child: _buildPermissionPrompt(isMobile: isMobile),
              )
            : SafeArea(
                top: false,
                child: RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _loadSchedules,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 24,
                      isMobile ? 10 : 14,
                      isMobile ? 16 : 24,
                      (isMobile ? 16 : 24) +
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOverviewCard(isMobile: isMobile),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                context.t.notifications(
                                  'notificationDescription',
                                ),
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: AppColors.text.withValues(alpha: 0.86),
                                  height: 1.35,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_schedules.isEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _setupDefaultReminders,
                                  icon: Icon(Icons.auto_awesome_rounded),
                                  label: Text(
                                    context.t.notifications(
                                      'setupDefaultReminders',
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            if (_schedules.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  context.t.notifications('customizeReminders'),
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),

                            _buildReminderCard(
                              type: 'meditation',
                              icon: Icons.self_improvement_rounded,
                              title: context.t.notifications(
                                'meditationReminders',
                              ),
                              color: const Color(0xFF8E5AF7),
                            ),
                            const SizedBox(height: 12),
                            _buildReminderCard(
                              type: 'companion',
                              icon: Icons.chat_bubble_outline_rounded,
                              title: context.t.notifications(
                                'companionChatReminders',
                              ),
                              color: const Color(0xFF3A7BFF),
                            ),
                            const SizedBox(height: 12),
                            _buildReminderCard(
                              type: 'wellness',
                              icon: Icons.favorite_rounded,
                              title: context.t.notifications(
                                'wellnessReminders',
                              ),
                              color: const Color(0xFFE55493),
                            ),
                            const SizedBox(height: 12),
                            _buildReminderCard(
                              type: 'questionnaires',
                              icon: Icons.assignment_rounded,
                              title: context.t.notifications(
                                'questionnairesReminders',
                              ),
                              color: const Color(0xFF169A93),
                            ),
                            const SizedBox(height: 12),
                            _buildReminderCard(
                              type: 'hydration',
                              icon: Icons.water_drop_rounded,
                              title: context.t.notifications(
                                'hydrationReminders',
                              ),
                              color: const Color(0xFF27A5C6),
                            ),
                            const SizedBox(height: 22),
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
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      await _notificationService
                                          .cancelAllReminders();
                                      await _loadSchedules();
                                    }
                                  },
                                  icon: Icon(Icons.cancel_outlined),
                                  label: Text(
                                    context.t.notifications(
                                      'disableNotifications',
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: BorderSide(
                                      color: Colors.red.withValues(alpha: 0.50),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isScheduled
              ? color.withValues(alpha: 0.35)
              : Colors.grey.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isMobile ? 44 : 48,
            height: isMobile ? 44 : 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isMobile ? 22 : 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isScheduled ? color : Colors.grey).withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isScheduled
                        ? '${context.t.notifications('reminderTime')}: ${_formatTime(hour, minute)}'
                        : context.t.notifications('setTime'),
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isScheduled ? color : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  icon: Icon(
                    isScheduled ? Icons.edit_rounded : Icons.add_alarm_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  onPressed: () => _scheduleReminder(type),
                  tooltip: context.t.notifications('setTime'),
                ),
              ),
              if (isScheduled) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.12),
                    ),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _cancelReminder(type),
                    tooltip: context.t.common('delete'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
