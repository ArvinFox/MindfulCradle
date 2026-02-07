import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/language_provider.dart';

class AuthLanguageToggle extends StatelessWidget {
  const AuthLanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, _) {
        final isSinhala = langProvider.currentLang == 'si';
        final toggleLabel = isSinhala ? 'EN' : 'සි';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          ),
          child: TextButton(
            onPressed: () {
              langProvider.setLanguage(isSinhala ? 'en' : 'si');
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              toggleLabel,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ),
        );
      },
    );
  }
}
