import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mamamind/constants/app_config.dart';
import 'package:mamamind/utils/logout_util.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/video_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/video_tile.dart';
import '../../routes/home_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  late VoidCallback _authListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initHome());
  }

  Future<void> _initHome() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);

    // Wait until AuthProvider finishes initializing
    while (authProvider.isInitializing) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Listen to user changes
    _authListener = () async {
      final user = authProvider.user;
      if (user != null) {
        videoProvider.reset();
        videoProvider.setUser(user);
        await videoProvider.waitForInitialProgress();
        if (mounted) setState(() => _loading = false);
      }
    };
    authProvider.addListener(_authListener);

    // Initial load if user already exists
    final user = authProvider.user;
    if (user != null) {
      videoProvider.reset();
      videoProvider.setUser(user);
      await videoProvider.waitForInitialProgress();
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.removeListener(_authListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final videoProvider = Provider.of<VideoProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final user = videoProvider.user;
    final videos = videoProvider.videos;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final currentLang = langProvider.currentLang;

    if (_loading || authProvider.isInitializing) {
      return Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
              child: CircularProgressIndicator(
            color: AppColors.primary,
          )));
    }

    if (user == null) {
      return Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
              child: Text(
            currentLang == 'en' ? "User data loading failed" : "පරිශීලක දත්ත පූරණය අසාර්ථක විය",
            style: GoogleFonts.roboto(),
          )));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          AppConfig.appName,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        elevation: 4,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: AppColors.primary,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: currentLang == 'en' ? 'Logout' : 'පිටවීම',
            onPressed: () {
              HapticFeedback.lightImpact();
              LogoutUtils.showLogoutDialog(
                context: context,
                authProvider: authProvider,
                language: langProvider.currentLang,
                redirectRoute: '/login',
              );
            },
          ),
        ],
      ),
      body: videos.isEmpty
          ? Center(
              child: Text(
                currentLang == 'en' ? "No sessions available." : "සැසි නොමැත.",
                style: GoogleFonts.roboto(color: Colors.grey.shade600),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Title
                  Text(
                    currentLang == 'en'
                        ? "Welcome, ${user.fullName.split(' ').first}!"
                        : "ආයුබෝවන්, ${user.fullName.split(' ').first}!",
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 30 : 36,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle/Motto
                  Text(
                    currentLang == 'en'
                        ? "Take a moment to relax and meditate daily."
                        : "දිනපතා විරාම ගෙන නිතරම ධ්‍යානය කරන්න.",
                    style: GoogleFonts.roboto(
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Section Header
                  Text(
                    currentLang == 'en'
                        ? "Meditation Sessions"
                        : "ධ්‍යානය සැසි",
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Video Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      final isUnlocked = videoProvider.isVideoUnlocked(video);

                      return VideoTile(
                        title: video.title,
                        isLocked: !isUnlocked,
                        isMobile: isMobile,
                        onTap: isUnlocked
                            ? () {
                                HapticFeedback.lightImpact();
                                final youtubeId = video.getYoutubeId(currentLang);
                                HomeRoutes.goToVideoPlayer(
                                  context,
                                  video,
                                  user.id,
                                  youtubeId,
                                );
                              }
                            : () {
                                HapticFeedback.vibrate();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      currentLang == 'en' ? "Complete the previous session to unlock this one." : "මෙය විවෘත කිරීමට පෙර සැසිය සම්පූර්ණ කරන්න.",
                                      style: GoogleFonts.roboto(),
                                    ),
                                    backgroundColor: Colors.orange.shade800,
                                  ),
                                );
                              },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}