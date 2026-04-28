import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../models/journal_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/journal_analysis.dart';
import 'journal_write_screen.dart';
import 'journal_detail_screen.dart';
import '../../widgets/app_background.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId != null) {
      Provider.of<JournalProvider>(context, listen: false).load(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSinhala =
        Provider.of<LanguageProvider>(context).currentLang == 'si';
    final journalProvider = Provider.of<JournalProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id ?? '';

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
          isSinhala ? 'මගේ සඟරාව' : 'My Journal',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () async {
          HapticFeedback.lightImpact();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JournalWriteScreen()),
          );
        },
        icon: const Icon(Icons.edit_rounded),
        label: Text(
          isSinhala ? 'නව ලිපිය' : 'New Entry',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: AppBackground(
        child: journalProvider.loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : journalProvider.entries.isEmpty
            ? _buildEmptyState(isSinhala)
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: journalProvider.entries.length,
                itemBuilder: (context, index) {
                  return _buildEntryCard(
                    journalProvider.entries[index],
                    isSinhala,
                    userId,
                    journalProvider,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEntryCard(
    JournalEntry entry,
    bool isSinhala,
    String userId,
    JournalProvider provider,
  ) {
    final sentimentColor = _sentimentColor(entry.sentiment);
    final sentimentEmoji = JournalAnalysis.sentimentEmoji(entry.sentiment);
    final lang = isSinhala ? 'si' : 'en';
    final sentimentLabel = JournalAnalysis.sentimentLabel(
      entry.sentiment,
      lang,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JournalDetailScreen(entry: entry),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title.isEmpty
                            ? (isSinhala ? '(මාතෘකාව නැත)' : '(No title)')
                            : entry.title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: sentimentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$sentimentEmoji $sentimentLabel',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sentimentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.content,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.semanticTags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: entry.semanticTags.map((tag) {
                      final labelData = JournalAnalysis.sentimentTagLabel(
                        tag,
                        lang,
                      );
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          labelData['label'] ?? tag,
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(entry.createdAt, isSinhala),
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: AppColors.textMuted.withValues(alpha: 0.7),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _confirmDelete(
                        context,
                        entry,
                        userId,
                        provider,
                        isSinhala,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    JournalEntry entry,
    String userId,
    JournalProvider provider,
    bool isSinhala,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isSinhala ? 'ලිපිය මකන්නද?' : 'Delete Entry?',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        content: Text(
          isSinhala
              ? 'මෙම ලිපිය ස්ථිරව ඉවත් කෙරේ.'
              : 'This entry will be permanently removed.',
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isSinhala ? 'අවලංගු' : 'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.delete(userId: userId, entryId: entry.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              isSinhala ? 'මකන්න' : 'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSinhala) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.book_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSinhala ? 'ඔබේ හැඟීම් ලියා ගන්න' : 'Write your first entry',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSinhala
                  ? 'ඔබේ ගැබ් ගැනීමේ ගමනේ සිතුවිලි හා හැඟීම් සටහන් කරන්න'
                  : 'Track your thoughts and feelings throughout your pregnancy journey',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
