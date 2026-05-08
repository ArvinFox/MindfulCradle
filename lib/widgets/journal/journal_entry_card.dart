import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/colors.dart';
import '../../models/journal_entry.dart';
import '../../utils/journal_analysis.dart';

/// Google Keep-style card for a single journal entry.
///
/// - Tap     → opens detail screen (via [onTap])
/// - Long press → triggers delete confirmation (via [onDelete])
class JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final Color cardColor;
  final bool isSinhala;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const JournalEntryCard({
    super.key,
    required this.entry,
    required this.cardColor,
    required this.isSinhala,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final lang = isSinhala ? 'si' : 'en';
    final sentimentEmoji = JournalAnalysis.sentimentEmoji(entry.sentiment);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              if (entry.title.isNotEmpty) ...[
                Text(
                  entry.title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
              ],
              // Content preview
              Text(
                entry.content,
                style: GoogleFonts.roboto(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
                maxLines: entry.title.isEmpty ? 6 : 4,
                overflow: TextOverflow.ellipsis,
              ),
              // Semantic tags (max 2)
              if (entry.semanticTags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: entry.semanticTags.take(2).map((tag) {
                    final data = JournalAnalysis.sentimentTagLabel(tag, lang);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data['label'] ?? tag,
                        style: GoogleFonts.roboto(
                          fontSize: 9.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 10),
              // Bottom row: short date + sentiment emoji
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _shortDate(entry.createdAt, isSinhala),
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      color: AppColors.textMuted.withValues(alpha: 0.55),
                    ),
                  ),
                  Text(sentimentEmoji, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortDate(DateTime dt, bool si) {
    final m = si
        ? [
            'ජන',
            'පෙබ',
            'මාර්',
            'අප්‍ර',
            'මැයි',
            'ජූනි',
            'ජූලි',
            'අගෝ',
            'සැප්',
            'ඔක්',
            'නොව',
            'දෙස',
          ]
        : [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
    return '${dt.day} ${m[dt.month - 1]}';
  }
}
