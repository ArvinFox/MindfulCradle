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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: langProvider.currentLang == 'en' ? 'English' : 'සිංහල',
              style: GoogleFonts.roboto(fontSize: 14, color: AppColors.text),
              iconEnabledColor: AppColors.text,
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'සිංහල', child: Text('සිංහල')),
              ],
              onChanged: (value) {
                if (value == null) return;
                langProvider.setLanguage(value == 'English' ? 'en' : 'si');
              },
            ),
          ),
        );
      },
    );
  }
}
