import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable result tile for displaying questionnaire scores
/// Supports both row-based and column-based layouts
class QuestionnaireResultTile extends StatelessWidget {
  final String title;
  final String scoreText;
  final String? classification;
  final Color tileColor;
  final bool isColumnLayout;
  final double screenWidth;

  const QuestionnaireResultTile({
    super.key,
    required this.title,
    required this.scoreText,
    this.classification,
    required this.tileColor,
    this.isColumnLayout = false,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = screenWidth < 600;
    final titleFont = isMobile ? (isColumnLayout ? 18.0 : 16.0) : 18.0;
    final scoreFont = isMobile ? (isColumnLayout ? 18.0 : 24.0) : 28.0;
    final classFont = isMobile ? (isColumnLayout ? 15.0 : 14.0) : 16.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isColumnLayout ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: tileColor, width: 1.5),
      ),
      child: isColumnLayout
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: titleFont,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  scoreText,
                  style: GoogleFonts.poppins(
                    fontSize: scoreFont,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (classification != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    classification!,
                    style: GoogleFonts.poppins(
                      fontSize: classFont,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: titleFont,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      scoreText,
                      style: GoogleFonts.poppins(
                        fontSize: scoreFont,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (classification != null)
                      Text(
                        classification!,
                        style: GoogleFonts.poppins(
                          fontSize: classFont,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// Small category tile used in grid layouts (PWS18)
class QuestionnaireCategoryTile extends StatelessWidget {
  final String title;
  final double? score;
  final Color tileColor;
  final String? classification;

  const QuestionnaireCategoryTile({
    super.key,
    required this.title,
    this.score,
    required this.tileColor,
    this.classification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: tileColor, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          if (score != null) ...[
            const SizedBox(height: 6),
            Text(
              score!.toStringAsFixed(2),
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (classification != null) ...[
              const SizedBox(height: 2),
              Text(
                classification!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
