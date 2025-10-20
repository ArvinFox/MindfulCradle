import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/constants/colors.dart';
import '/providers/language_provider.dart';

class DASS21HintOverlay extends StatefulWidget {
  final bool visible;
  final VoidCallback onClose;
  final bool isMobile;
  final Duration duration;
  final Curve curve;

  const DASS21HintOverlay({
    super.key,
    required this.visible,
    required this.onClose,
    required this.isMobile,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<DASS21HintOverlay> createState() => _DASS21HintOverlayState();
}

class _DASS21HintOverlayState extends State<DASS21HintOverlay>
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
        ? "උදවු නැවත බැලීමට ප්‍රශ්න පිටුවේ පහළ වම් කොනේ ඇති ? ලකුණ ක්ලික් කරන්න"
        : "To see the hints again click on the ? on the bottom left corner on the questionnaire page";

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Table data for 1-4
    final tableData = [
      isSinhala ? "මට කිසිසේත් අදාළ නැත." : "Did not apply to me at all",
      isSinhala
          ? "මට තරමක් දුරට හෝ සමහර වෙලාවට අදාළයි"
          : "Applied to me to some degree, or some of the time",
      isSinhala
          ? "මට සැලකිය යුතු ප්‍රමාණයකට හෝ සැලකිය යුතු කාලයකට අදාළයි"
          : "Applied to me to a considerable degree, or a good part of time",
      isSinhala
          ? "මට බොහෝ දුරට හෝ බොහෝ වෙලාවට අදාළයි"
          : "Applied to me very much, or most of the time",
    ];

    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1.0 : 0.0,
        duration: widget.duration,
        curve: widget.curve,
        child: Stack(
          children: [
            // Blur background
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.visible ? 6.0 : 0.0,
                sigmaY: widget.visible ? 6.0 : 0.0,
              ),
              child: Container(
                color: Colors.black.withOpacity(widget.visible ? 0.25 : 0.0),
              ),
            ),

            // Pulsing question mark
            Positioned(
              bottom: 40,
              left: 40,
              child: AnimatedOpacity(
                opacity: widget.visible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.help_outline,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Hint card
            Center(
              child: AnimatedScale(
                scale: widget.visible ? 1.0 : 0.95,
                duration: widget.duration,
                curve: widget.curve,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: screenWidth * 0.85,
                    maxHeight: screenHeight * 0.7,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 6,
                      radius: const Radius.circular(3),
                      interactive: true,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon + title
                            Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.help_outline,
                                    color: Colors.orangeAccent,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
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
                            const SizedBox(height: 16),

                            // Intro text above table
                            Text(
                              isSinhala
                                  ? "මෙම පරීක්ෂණය සඳහා පිළිතුරු 1 - 4 සංඛ්‍යාවන් භාවිතා වේ."
                                  : "For this questionnaire, please answer using numbers 1 - 4.",
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: AppColors.text,
                                height: 1.5,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Table header + rows
                            Table(
                              columnWidths: const {
                                0: IntrinsicColumnWidth(),
                                1: FlexColumnWidth(),
                              },
                              border: TableBorder(
                                horizontalInside: BorderSide(
                                    width: 1, color: Colors.grey.shade300),
                              ),
                              defaultVerticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
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
                                        isSinhala
                                            ? "අර්ථය / පිළිතුර"
                                            : "Meaning / Answer",
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
                                // Table rows
                                for (int i = 0; i < 4; i++)
                                  _buildTableRow((i + 1).toString(), tableData[i]),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Text(
                              noteText,
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppColors.text.withOpacity(0.8),
                                decoration: TextDecoration.none,
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: widget.onClose,
                                child: Text(
                                  isSinhala ? "හරි" : "OK",
                                  style: GoogleFonts.poppins(
                                    color: AppColors.buttonText,
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
            ),
          ],
        ),
      ),
    );
  }
}
