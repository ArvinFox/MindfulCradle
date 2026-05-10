import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/colors.dart';
import '../../utils/translate.dart';
import '../../widgets/app_background.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.primary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          t.privacyPolicy('appBarTitle'),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.text,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: AppBackground(
        overlayOpacity: 0.60,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PolicyHeader(),
              const SizedBox(height: 24),
              ..._buildContent(t),
              const SizedBox(height: 32),
              _ContactCard(),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  t.privacyPolicy('lastUpdated'),
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textMuted.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(Translate t) => [
    _Section(icon: Icons.info_outline_rounded,  title: t.privacyPolicy('s1Title'), body: t.privacyPolicy('s1Body')),
    _Section(icon: Icons.folder_open_rounded,   title: t.privacyPolicy('s2Title'), body: t.privacyPolicy('s2Body')),
    _Section(icon: Icons.psychology_rounded,    title: t.privacyPolicy('s3Title'), body: t.privacyPolicy('s3Body')),
    _Section(icon: Icons.storage_rounded,       title: t.privacyPolicy('s4Title'), body: t.privacyPolicy('s4Body')),
    _Section(icon: Icons.business_rounded,      title: t.privacyPolicy('s5Title'), body: t.privacyPolicy('s5Body')),
    _Section(icon: Icons.verified_user_rounded, title: t.privacyPolicy('s6Title'), body: t.privacyPolicy('s6Body')),
    _Section(icon: Icons.schedule_rounded,      title: t.privacyPolicy('s7Title'), body: t.privacyPolicy('s7Body')),
    _Section(icon: Icons.child_care_rounded,    title: t.privacyPolicy('s8Title'), body: t.privacyPolicy('s8Body')),
    _Section(icon: Icons.update_rounded,        title: t.privacyPolicy('s9Title'), body: t.privacyPolicy('s9Body')),
  ];
}
// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _PolicyHeader extends StatelessWidget {
  const _PolicyHeader();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
          const SizedBox(height: 12),
          Text(
            t.privacyPolicy('headerTitle'),
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.privacyPolicy('headerSubtitle'),
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.90),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Section({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textMuted,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                body,
                style: GoogleFonts.roboto(
                  fontSize: 13.5,
                  height: 1.65,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  static const _email = 'mamamindcorp@gmail.com';

  Future<void> _launchEmail() async {
    final uri = Uri(scheme: 'mailto', path: _email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.mail_outline_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.privacyPolicy('contactTitle'),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.privacyPolicy('contactBody'),
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _launchEmail,
                  child: Text(
                    _email,
                    style: GoogleFonts.roboto(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
