import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/language_provider.dart';
import '../../screens/main_screen.dart';
import '../../services/crisis_detection_service.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/app_background.dart';
import '../../widgets/wellness_support_dialog.dart';

class JournalWriteScreen extends StatefulWidget {
  const JournalWriteScreen({super.key});

  @override
  State<JournalWriteScreen> createState() => _JournalWriteScreenState();
}

class _JournalWriteScreenState extends State<JournalWriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _saving = false;

  static const int _titleWordLimit = 15;
  static const int _contentWordLimit = 500;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) {
      final isSinhala =
          Provider.of<LanguageProvider>(context, listen: false).currentLang ==
          'si';
      AppSnackBar.warning(
        context,
        isSinhala ? 'කරුණාකර ලිපිය ලියන්න' : 'Please write something first',
      );
      return;
    }

    setState(() => _saving = true);

    final isSinhala =
        Provider.of<LanguageProvider>(context, listen: false).currentLang ==
        'si';
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id ?? '';
    final lang = isSinhala ? 'si' : 'en';
    final contentText = _contentController.text.trim();

    // ── Step 1: keyword crisis check — instant, no network required.
    final CrisisLevel crisisLevel = CrisisDetectionService.analyzeJournalText(
      contentText,
      lang,
    );

    // ── Step 2: save to Firestore.
    try {
      await Provider.of<JournalProvider>(context, listen: false).add(
        userId: userId,
        title: _titleController.text.trim(),
        content: contentText,
        language: lang,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackBar.error(
          context,
          isSinhala
              ? 'සෙව් කිරීම අසාර්ථකයි. නැවත උත්සාහ කරන්න.'
              : 'Failed to save. Please try again.',
        );
      }
      return;
    }

    // ── Step 3: spinner off — entry is safely in DB regardless of what follows.
    if (mounted) setState(() => _saving = false);

    if (!mounted) return;

    // ── Step 4: wellness dialog (shown BEFORE achievements so a crisis prompt
    //    is never blocked by an achievement popup).
    WellnessAction wellnessAction = WellnessAction.none;
    if (crisisLevel != CrisisLevel.none) {
      wellnessAction = await WellnessSupportDialog.show(
        context,
        crisisLevel,
        isSinhala,
      );
      if (!mounted) return;
    }

    // ── Step 5: achievements — fully fire-and-forget.
    // unlockAchievement() writes to Firestore; if the network is slow it can
    // hang seconds. We must NOT await it here or navigation is blocked.
    // showPendingAchievements() already uses navigatorKey.currentContext, so
    // the popup will appear on whichever screen is current after we navigate.
    if (context.mounted) {
      final achievementProvider = Provider.of<AchievementProvider>(
        context,
        listen: false,
      );
      final entryCount = Provider.of<JournalProvider>(
        context,
        listen: false,
      ).entries.length;
      // ignore: unawaited_futures
      () async {
        if (entryCount >= 1) {
          await achievementProvider.unlockAchievement(
            context,
            'first_journal',
            showUI: false,
          );
        }
        if (entryCount >= 5) {
          await achievementProvider.unlockAchievement(
            context,
            'journal_writer',
            showUI: false,
          );
        }
        await achievementProvider.showPendingAchievements(context);
      }();
    }

    if (!mounted) return;

    // ── Step 6: navigate based on wellness action.
    switch (wellnessAction) {
      case WellnessAction.chat:
        // Write wellness context so ChatBotPage can send a caring greeting.
        await SharedPreferences.getInstance().then((prefs) {
          prefs.setString(
            'wellness_trigger',
            crisisLevel == CrisisLevel.crisis ? 'crisis' : 'distress',
          );
          prefs.setString('wellness_trigger_lang', lang);
        });
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        MainScreen.switchToTab(2);
        return;
      case WellnessAction.questionnaire:
        Navigator.of(context).popUntil((route) => route.isFirst);
        MainScreen.switchToTab(1);
        return;
      case WellnessAction.meditate:
        Navigator.of(context).popUntil((route) => route.isFirst);
        MainScreen.switchToTab(0);
        return;
      case WellnessAction.none:
        break;
    }

    Navigator.pop(context);
    AppSnackBar.success(
      context,
      isSinhala ? 'ලිපිය සුරකිනු ලැබීය' : 'Entry saved',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSinhala =
        Provider.of<LanguageProvider>(context).currentLang == 'si';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isSinhala ? 'නව සඟරා ලිපිය' : 'New Journal Entry',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text(
                    isSinhala ? 'සුරකින්න' : 'Save',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
        ],
      ),
      body: AppBackground(
        overlayOpacity: 0.75,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date line
              Text(
                _formattedDate(isSinhala),
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 14),

              // Title field
              TextField(
                controller: _titleController,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
                decoration: InputDecoration(
                  hintText: isSinhala ? 'මාතෘකාව...' : 'Title...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
                minLines: 1,
                inputFormatters: [_WordLimitInputFormatter(_titleWordLimit)],
              ),

              Divider(color: AppColors.border, height: 28),

              // Content field
              TextField(
                controller: _contentController,
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  color: AppColors.text,
                  height: 1.7,
                ),
                decoration: InputDecoration(
                  hintText: isSinhala
                      ? 'ඔබේ හැඟීම් ලියන්න...'
                      : 'Write your thoughts and feelings...',
                  hintStyle: GoogleFonts.roboto(
                    fontSize: 15,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    height: 1.7,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                minLines: 12,
                inputFormatters: [_WordLimitInputFormatter(_contentWordLimit)],
              ),

              // Word counter — right-aligned below the content field
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _contentController,
                builder: (context, value, _) {
                  final t = value.text.trim();
                  final count =
                      t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
                  final isNear =
                      count >= (_contentWordLimit * 0.9).round();
                  final isMax = count >= _contentWordLimit;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$count\u00a0/\u00a0$_contentWordLimit '
                        '${isSinhala ? 'වචන' : 'words'}',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: isMax
                              ? AppColors.error
                              : isNear
                                  ? const Color(0xFFE07B2B)
                                  : AppColors.textMuted
                                      .withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Analysis preview hint
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isSinhala
                            ? 'ඔබ සුරකින විට, ඔබේ ලිපිය ස්වයංක්‍රීයව හැඟීම් විශ්ලේෂණය කෙරේ'
                            : 'When you save, your entry will be automatically analysed for sentiment and topics',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppColors.primary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formattedDate(bool isSinhala) {
    final now = DateTime.now();
    final months = isSinhala
        ? [
            'ජනවාරි',
            'පෙබරවාරි',
            'මාර්තු',
            'අප්‍රේල්',
            'මැයි',
            'ජූනි',
            'ජූලි',
            'අගෝස්තු',
            'සැප්තැම්බර්',
            'ඔක්තෝබර්',
            'නොවැම්බර්',
            'දෙසැම්බර්',
          ]
        : [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _WordLimitInputFormatter extends TextInputFormatter {
  const _WordLimitInputFormatter(this.maxWords);
  final int maxWords;

  static int _count(String text) {
    final t = text.trim();
    return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_count(newValue.text) <= maxWords) return newValue;
    // On paste / large insertion: truncate to the word limit.
    final words = newValue.text.trim().split(RegExp(r'\s+'));
    final truncated = words.take(maxWords).join(' ');
    return newValue.copyWith(
      text: truncated,
      selection: TextSelection.collapsed(offset: truncated.length),
    );
  }
}
