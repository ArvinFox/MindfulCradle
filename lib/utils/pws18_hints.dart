import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/constants/colors.dart';
import '/providers/language_provider.dart';

/// Shows the PWS-18 hint as a full-screen dialog that covers the entire screen.
class PWS18HintOverlay {
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onClose,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'PWS18 Hint',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, _, __) => _PWS18HintContent(
        onClose: () {
          Navigator.of(ctx).pop();
          onClose();
        },
      ),
      transitionBuilder: (_, anim1, __, child) {
        final t = Curves.easeOutBack.transform(anim1.value.clamp(0.0, 1.0));
        return Transform.scale(
          scale: 0.85 + 0.15 * t,
          child: Opacity(
            opacity: anim1.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
    );
  }
}

class _PWS18HintContent extends StatefulWidget {
  final VoidCallback onClose;
  const _PWS18HintContent({required this.onClose});

  @override
  State<_PWS18HintContent> createState() => _PWS18HintContentState();
}

class _PWS18HintContentState extends State<_PWS18HintContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  TableRow _buildTableRow(String number, String text) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.primary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text(
            text,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppColors.text,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLang;
    final isSinhala = lang == 'si';
    final noteText = isSinhala
        ? "උදවු නැවත බැලීමට ප්‍රශ්න පිටුවේ ඉහළ දකුණු කොනේ ඇති ? ලකුණ ක්ලික් කරන්න"
        : "To see the hints again, tap the ? icon at the top right of the questionnaire page";

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Table data for 1-7
    final tableData = [
      isSinhala ? "දැඩි ලෙස එකඟ" : "Strongly Agree",
      isSinhala ? "ටිකක් එකඟ" : "Somewhat Agree",
      isSinhala ? "සාමාන්‍යයෙන් එකඟ" : "A Little Agree",
      isSinhala ? "එකඟ නැත/නැත" : "Neither Agree nor Disagree",
      isSinhala ? "සාමාන්‍යයෙන් අසම්මත" : "A Little Disagree",
      isSinhala ? "ටිකක් අසම්මත" : "Somewhat Disagree",
      isSinhala ? "දැඩි ලෙස අසම්මත" : "Strongly Disagree",
    ];

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth * 0.88,
          maxHeight: screenHeight * 0.82,
        ),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              thickness: 5,
              radius: const Radius.circular(3),
              interactive: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pulsing icon + title
                    Center(
                      child: Column(
                        children: [
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.10),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.30),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.help_outline_rounded,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isSinhala ? "උදවු" : "Hint",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              color: AppColors.primary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 12),

                    // Intro text
                    Text(
                      isSinhala
                          ? "මෙම පරීක්ෂණය සඳහා පිළිතුරු 1 - 7 සංඛ්‍යාවන් භාවිතා වේ."
                          : "For this questionnaire, please answer using numbers 1 - 7.",
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppColors.text,
                        height: 1.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Table
                    Table(
                      columnWidths: const {
                        0: IntrinsicColumnWidth(),
                        1: FlexColumnWidth(),
                      },
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          width: 1,
                          color: Colors.grey.shade200,
                        ),
                      ),
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                          ),
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Text(
                                  isSinhala ? "සංඛ්‍යාව" : "Number",
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                isSinhala ? "අර්ථය / පිළිතුර" : "Meaning / Answer",
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.primary,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                        for (int i = 0; i < 7; i++)
                          _buildTableRow((i + 1).toString(), tableData[i]),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Note box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              noteText,
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 3,
                          shadowColor: AppColors.primary.withOpacity(0.35),
                        ),
                        onPressed: widget.onClose,
                        child: Text(
                          isSinhala ? "හරි" : "Got it!",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            decoration: TextDecoration.none,
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
    );
  }
}