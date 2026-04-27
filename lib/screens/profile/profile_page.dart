import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mamamind/utils/logout_util.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/translate.dart';
import '../../widgets/app_background.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _uploadingPhoto = false;

  Future<void> _pickAndUploadPhoto(AuthProvider authProvider) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await CloudinaryService.uploadAvatar(
        File(picked.path),
        authProvider.user!.id,
      );
      if (!mounted) return;
      if (url != null) {
        await authProvider.updatePhotoUrl(url);
        if (mounted) {
          AppSnackBar.success(
            context,
            Provider.of<LanguageProvider>(context, listen: false).currentLang ==
                    'si'
                ? 'පින්තූරය යාවත්කාලීන විය.'
                : 'Profile photo updated.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    final authProvider = Provider.of<AuthProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final user = authProvider.user;
    final isSinhala = langProvider.currentLang == 'si';

    if (authProvider.isInitializing) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: AppBackground(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: AppBackground(
          child: Center(
            child: Text(
              context.t.profile('userDataNotAvailable'),
              style: GoogleFonts.poppins(
                color: AppColors.text,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          context.t.profile('profile'),
          style: GoogleFonts.poppins(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            92 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.heroGradientStart,
                      AppColors.heroGradientMid,
                      AppColors.heroGradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _uploadingPhoto
                          ? null
                          : () => _pickAndUploadPhoto(authProvider),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: isMobile ? 92 : 102,
                            height: isMobile ? 92 : 102,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1.4,
                              ),
                            ),
                            child: _uploadingPhoto
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  )
                                : ClipOval(
                                    child: user.photoUrl != null
                                        ? Image.network(
                                            user.photoUrl!,
                                            fit: BoxFit.cover,
                                            width: isMobile ? 92 : 102,
                                            height: isMobile ? 92 : 102,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                  Icons.person_rounded,
                                                  size: 56,
                                                  color: Colors.white,
                                                ),
                                          )
                                        : const Icon(
                                            Icons.person_rounded,
                                            size: 56,
                                            color: Colors.white,
                                          ),
                                  ),
                          ),
                          // Camera badge
                          if (!_uploadingPhoto)
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.fullName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 22 : 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    context.t.profile('settings'),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildLanguageCard(context, isSinhala, langProvider),
              const SizedBox(height: 12),
              _buildNavCard(
                context: context,
                title: context.t.notifications('notificationSettings'),
                subtitle: isSinhala ? 'මතක් කිරීම් සකසන්න' : 'Manage reminders',
                icon: Icons.notifications_active_rounded,
                onTap: () =>
                    Navigator.pushNamed(context, '/notification-settings'),
              ),
              const SizedBox(height: 12),
              _buildNavCard(
                context: context,
                title: isSinhala ? 'දත්ත හා පෞද්ගලිකත්වය' : 'Data & Privacy',
                subtitle: isSinhala
                    ? 'GDPR පාලන සහ දත්ත අපනයනය'
                    : 'GDPR controls and data export',
                icon: Icons.privacy_tip_rounded,
                onTap: () => Navigator.pushNamed(context, '/gdpr-account'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    LogoutUtils.showLogoutDialog(
                      context: context,
                      authProvider: authProvider,
                      language: langProvider.currentLang,
                      redirectRoute: '/login',
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  label: Text(isSinhala ? 'ලොග් අවුට්' : 'Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide.none,
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    bool isSinhala,
    LanguageProvider langProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.language_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        title: Text(
          context.t.profile('languageSettings'),
          style: GoogleFonts.poppins(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: isSinhala ? 'si' : 'en',
              style: GoogleFonts.poppins(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              icon: const Icon(Icons.keyboard_arrow_down, size: 20),
              dropdownColor: Colors.white,
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Text(context.t.common('english')),
                ),
                DropdownMenuItem(
                  value: 'si',
                  child: Text(context.t.common('sinhala')),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  langProvider.setLanguage(val);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.roboto(color: AppColors.textMuted, fontSize: 12.5),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
