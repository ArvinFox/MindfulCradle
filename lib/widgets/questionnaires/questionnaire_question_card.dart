import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';

/// Reusable question card for questionnaires
/// Shows question text and answer options as ChoiceChips
class QuestionnaireQuestionCard extends StatelessWidget {
  final int questionId;
  final String questionText;
  final Map<String, String> options;
  final int? selectedValue;
  final Function(int) onAnswerSelected;
  final bool isMissing;
  final bool isMobile;
  final String missingText;

  const QuestionnaireQuestionCard({
    super.key,
    required this.questionId,
    required this.questionText,
    required this.options,
    this.selectedValue,
    required this.onAnswerSelected,
    this.isMissing = false,
    this.isMobile = false,
    this.missingText = '* Required',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isMissing
            ? BorderSide(color: Colors.red, width: 2.0)
            : BorderSide(color: AppColors.border, width: 1),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '$questionId. $questionText',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: isMobile ? 15 : 17,
                      color: AppColors.text,
                    ),
                  ),
                ),
                if (isMissing)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final chipWidth = (constraints.maxWidth / 4) - 8;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.entries.map((entry) {
                    final intVal = int.tryParse(entry.key) ?? 0;
                    final selected = selectedValue == intVal;
                    return SizedBox(
                      width: chipWidth.clamp(60.0, 150.0),
                      child: ChoiceChip(
                        label: Text(
                          entry.value,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: isMobile ? 13 : 14,
                            color: selected ? Colors.white : AppColors.text,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        selected: selected,
                        selectedColor: AppColors.completed,
                        backgroundColor: AppColors.cardBackground,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: selected
                                ? AppColors.completed
                                : AppColors.tileInactive.withValues(alpha: 0.5),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        shadowColor: selected
                            ? AppColors.completed.withValues(alpha: 0.7)
                            : AppColors.completed,
                        elevation: selected ? 8 : 0,
                        pressElevation: 2,
                        onSelected: (_) {
                          HapticFeedback.lightImpact();
                          onAnswerSelected(intVal);
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            if (isMissing)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  missingText,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
