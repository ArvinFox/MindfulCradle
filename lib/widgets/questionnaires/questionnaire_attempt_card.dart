import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

class QuestionnaireAttemptCard extends StatelessWidget {
  final int attemptNumber;
  final bool isSinhala;
  final bool isCompleted;
  final bool isLocked;
  final bool isExpanded;
  final String statusText;
  final String? completedDateText;
  final VoidCallback? onToggleExpanded;
  final VoidCallback? onStart;
  final Widget? results;

  const QuestionnaireAttemptCard({
    super.key,
    required this.attemptNumber,
    required this.isSinhala,
    required this.isCompleted,
    required this.isLocked,
    required this.isExpanded,
    required this.statusText,
    required this.onToggleExpanded,
    required this.onStart,
    this.completedDateText,
    this.results,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = AppColors.surface;
    final borderColor = isCompleted
        ? AppColors.completed.withValues(alpha: 0.5)
        : Colors.grey.withValues(alpha: 0.2);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: isCompleted ? onToggleExpanded : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.completed
                          : (isLocked ? Colors.grey[400] : AppColors.primary),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check
                          : (isLocked
                                ? Icons.lock_outline
                                : Icons.play_arrow_rounded),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSinhala
                              ? 'අදියර $attemptNumber'
                              : 'Attempt $attemptNumber',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: isCompleted
                                ? AppColors.completed
                                : (isLocked ? Colors.grey : AppColors.primary),
                            fontWeight: isCompleted || !isLocked
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: AppColors.text.withValues(alpha: 0.6),
                        size: 32,
                      ),
                    )
                  else if (!isLocked)
                    ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        isSinhala ? 'අරඹන්න' : 'Start',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: (isCompleted && isExpanded)
                ? Column(
                    children: [
                      Container(height: 1, color: borderColor),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            if (completedDateText != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(
                                  completedDateText!,
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: AppColors.text.withValues(
                                      alpha: 0.6,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (results != null) results!,
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
