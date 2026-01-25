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

    // Wait for auth to be ready
    while (authProvider.isInitializing) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Listener for future auth changes
    _authListener = () async {
      final user = authProvider.user;
      if (user != null && mounted) {
        videoProvider.reset();
        videoProvider.setUser(user, context);
        await videoProvider.waitForInitialProgress();
        if (mounted) setState(() => _loading = false);
      }
    };
    authProvider.addListener(_authListener);

    // Immediate check
    final user = authProvider.user;
    if (user != null && mounted) {
      videoProvider.reset();
      videoProvider.setUser(user, context);
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
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            currentLang == 'en'
                ? "User data loading failed"
                : "පරිශීලක දත්ත පූරණය අසාර්ථක විය",
            style: GoogleFonts.roboto(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppConfig.appName,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
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
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 110, 24, 25),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentLang == 'en'
                            ? "Welcome, ${user.fullName.split(' ').first}!"
                            : "ආයුබෝවන්, ${user.fullName.split(' ').first}!",
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentLang == 'en'
                            ? "Take a moment to step back and find your inner peace." 
                            : "කාර්යබහුල දවසින් මදකට මිදී, සිත නිවාගන්නට සොඳුරු මොහොතක්.",
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // GRID CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Title
                        Row(
                          children: [
                            Container(
                              height: 20,
                              width: 4,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentLang == 'en'
                                  ? "Meditation Sessions"
                                  : "ධ්‍යානය සැසි",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Clean Grid
                        GridView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isMobile ? 2 : 3,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.0,
                              ),
                          itemCount: videos.length,
                          itemBuilder: (context, index) {
                            final video = videos[index];
                            final isUnlocked = videoProvider.isVideoUnlocked(
                              video,
                            );

                            return VideoTile(
                              title: currentLang == 'en'
                                  ? video.title
                                  : video.titleSi,
                              isLocked: !isUnlocked,
                              isMobile: isMobile,
                              onTap: isUnlocked
                                  ? () {
                                      HapticFeedback.lightImpact();
                                      final youtubeId = video.getYoutubeId(
                                        currentLang,
                                      );
                                      HomeRoutes.goToVideoPlayer(
                                        context,
                                        video,
                                        user.id,
                                        youtubeId,
                                      );
                                    }
                                  : () {
                                      HapticFeedback.vibrate();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            currentLang == 'en'
                                                ? "Complete previous session."
                                                : "පෙර සැසිය සම්පූර්ණ කරන්න.",
                                            style: GoogleFonts.roboto(),
                                          ),
                                          backgroundColor:
                                              Colors.orange.shade800,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          duration: const Duration(seconds: 1),
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
                ),
              ],
            ),
    );
  }
}
