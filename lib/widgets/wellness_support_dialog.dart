import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/colors.dart';
import '../widgets/gradient_button.dart';
import '../services/crisis_detection_service.dart';

/// The action the user chose in the wellness support sheet.
enum WellnessAction {
  /// User dismissed without choosing a feature.
  none,

  /// User wants to open the AI Companion chat.
  chat,

  /// User wants to take a wellness questionnaire.
  questionnaire,

  /// User wants to go to the Mindfulness Sessions on the home page.
  meditate,
}

/// Displays an empathetic bottom-sheet offering:
///  - [CrisisLevel.crisis]  → helpline phone numbers + Chat with Companion
///  - [CrisisLevel.distress] → gentle wellness recommendations
///
/// Returns the [WellnessAction] chosen (or [WellnessAction.none] on dismiss).
///
/// ```dart
/// final action = await WellnessSupportDialog.show(context, level, isSinhala);
/// ```
class WellnessSupportDialog {
  WellnessSupportDialog._();

  static Future<WellnessAction> show(
    BuildContext context,
    CrisisLevel level,
    bool isSinhala,
  ) async {
    assert(level != CrisisLevel.none, 'Only call show() for crisis/distress');

    final result = await showModalBottomSheet<WellnessAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // Crisis sheet must not be accidentally dismissed by dragging.
      enableDrag: level == CrisisLevel.distress,
      isDismissible: level == CrisisLevel.distress,
      builder: (_) => level == CrisisLevel.crisis
          ? _CrisisSheet(isSinhala: isSinhala)
          : _DistressSheet(isSinhala: isSinhala),
    );

    return result ?? WellnessAction.none;
  }
}

// ── Crisis sheet ───────────────────────────────────────────────────────────

class _CrisisSheet extends StatelessWidget {
  final bool isSinhala;
  const _CrisisSheet({required this.isSinhala});

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final si = isSinhala;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Text('💚', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              si ? 'ඔබ තනිව නොසිටින්න' : "You're Not Alone",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Body
            Text(
              si
                  ? 'ඔබ දැන් ඉතා අපහසු හැඟීම් දරන සේ පෙනෙයි. ඔබේ හැඟීම් වලංගු ය — ඔබ ආදරයෙන් සහ සහාය ලැබිය යුතු ය. කරුණාකර ඔබ ආදරය කරන කෙනෙකු හෝ පහත සේවාවකට ළඟා වන්න.'
                  : "It sounds like you're carrying something very heavy right now. Your feelings are valid and you deserve care and support. Please reach out to someone you trust, or contact one of these services.",
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.65,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Helpline: Sumithrayo
            _HelplineCard(
              name: si ? 'සුමිතුරෝ (පැය 24)' : 'Sumithrayo (24/7)',
              subtitle: si ? 'හැඟීම් සහාය සේවා' : 'Emotional support helpline',
              number: '0112 696 666',
              onTap: () => _call('0112696666'),
            ),
            const SizedBox(height: 10),

            // Helpline: CCCline
            _HelplineCard(
              name: si
                  ? 'CCCline – සෞඛ්‍ය අමාත්‍යාංශය'
                  : 'CCCline – Ministry of Health',
              subtitle: si ? 'මානසික සෞඛ්‍ය සහාය' : 'Mental health support',
              number: '1333',
              onTap: () => _call('1333'),
            ),
            const SizedBox(height: 24),

            // Chat with Companion
            SizedBox(
              width: double.infinity,
              child: GradientButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop(WellnessAction.chat);
                },
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                label: Text(
                  si ? 'AI සහකාරයා සමඟ කතා කරන්න' : 'Chat with our Companion',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 10),

            // Dismiss
            TextButton(
              onPressed: () => Navigator.of(context).pop(WellnessAction.none),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: Text(
                si ? 'හරි, මම හොඳයි' : "I'm okay for now",
                style: GoogleFonts.roboto(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Distress sheet ─────────────────────────────────────────────────────────

class _DistressSheet extends StatelessWidget {
  final bool isSinhala;
  const _DistressSheet({required this.isSinhala});

  @override
  Widget build(BuildContext context) {
    final si = isSinhala;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Text('🌸', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            si ? 'ඔබ හා අපි ඉන්නෙමු 🌸' : "We're Here for You 🌸",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Body
          Text(
            si
                ? 'ඔබ දැන් ශාරීරිකව හෝ මානසිකව දුෂ්කරතා අනුභව කරන සේ පෙනෙයි. ගර්භනී කාලය ශාරීරිකවත් මානසිකවත් අභියෝගාත්මක විය හැකිය. ඔබ ඇසීමට සූදානම් කෙනෙකු සිටිනවා. මෙය ඔබට ලිහිල් කිරීමට ගෙනෙමු:'
                : "It sounds like you might be going through a tough time. That's completely understandable — pregnancy can be emotionally challenging. You deserve support. Here are a few things that might help:",
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.65,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),

          // Action: Meditate
          _ActionButton(
            emoji: '🧘',
            label: si
                ? 'Mindfulness සැසියක් කරන්න'
                : 'Try a Mindfulness Session',
            sublabel: si
                ? 'සිත සන්සුන් කරන්න'
                : 'Calm your mind with guided meditation',
            color: AppColors.primary,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop(WellnessAction.meditate);
            },
          ),
          const SizedBox(height: 10),

          // Action: Questionnaire
          _ActionButton(
            emoji: '📋',
            label: si ? 'Wellness ඇගයීමක් කරන්න' : 'Take a Wellness Assessment',
            sublabel: si
                ? 'ඔබේ සෞඛ්‍ය ගමන නිරීක්ෂණය කරන්න'
                : 'Track your emotional wellbeing',
            color: const Color(0xFF7B68EE),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop(WellnessAction.questionnaire);
            },
          ),
          const SizedBox(height: 10),

          // Action: Chat
          _ActionButton(
            emoji: '💬',
            label: si
                ? 'AI සහකාරයා සමඟ කතා කරන්න'
                : 'Chat with our AI Companion',
            sublabel: si
                ? 'ඔබේ හැඟීම් ගැන කතා කරන්න'
                : 'Share how you\'re feeling',
            color: const Color(0xFF2196F3),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop(WellnessAction.chat);
            },
          ),
          const SizedBox(height: 16),

          // Dismiss
          TextButton(
            onPressed: () => Navigator.of(context).pop(WellnessAction.none),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text(
              si ? 'පසුව කරන්නම්' : 'Maybe later',
              style: GoogleFonts.roboto(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpline card ──────────────────────────────────────────────────────────

class _HelplineCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String number;
  final VoidCallback onTap;

  const _HelplineCard({
    required this.name,
    required this.subtitle,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE8F5E9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                number,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action button ──────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    Text(
                      sublabel,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
