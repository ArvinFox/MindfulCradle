import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../models/journal_entry.dart';
import '../../providers/language_provider.dart';
import '../../utils/journal_analysis.dart';
import '../../widgets/app_background.dart';

class JournalDetailScreen extends StatelessWidget {
  final JournalEntry entry;

  const JournalDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isSinhala =
        Provider.of<LanguageProvider>(context).currentLang == 'si';
    final lang = isSinhala ? 'si' : 'en';
    final sentimentColor = _sentimentColor(entry.sentiment);
    final sentimentEmoji = JournalAnalysis.sentimentEmoji(entry.sentiment);
    final sentimentLabel = JournalAnalysis.sentimentLabel(
      entry.sentiment,
      lang,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(
          isSinhala ? 'සඟරා ලිපිය' : 'Journal Entry',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.text,
          ),
        ),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date
              Text(
                _formatDate(entry.createdAt, isSinhala),
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),

              // Title
              if (entry.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    entry.title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                      height: 1.3,
                    ),
                  ),
                ),

              // Sentiment badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: sentimentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: sentimentColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sentimentEmoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      isSinhala
                          ? 'හැඟීම: $sentimentLabel'
                          : 'Mood: $sentimentLabel',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sentimentColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Divider(color: AppColors.border),
              const SizedBox(height: 18),

              // Content
              Text(
                entry.content,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: AppColors.text,
                  height: 1.8,
                ),
              ),

              if (entry.semanticTags.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(
                  isSinhala ? 'මාතෘකා' : 'Topics',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.semanticTags.map((tag) {
                    final labelData = JournalAnalysis.sentimentTagLabel(
                      tag,
                      lang,
                    );
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        '# ${labelData['label'] ?? tag}',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _sentimentColor(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return AppColors.success;
      case 'negative':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  String _formatDate(DateTime dt, bool isSinhala) {
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
