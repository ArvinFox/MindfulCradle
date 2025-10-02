import 'package:flutter/material.dart';
import 'package:mamamind/constants/app_config.dart';
import 'package:provider/provider.dart';
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

  Future<bool?> confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not found")));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          AppConfig.appName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await confirmLogout(context);
              if (confirmed ?? false) {
                await authProvider.logout();
                videoProvider.reset();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
          ),
        ],
      ),
      body: videos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentLang == 'en'
                        ? "Welcome, ${user.fullName}!"
                        : "ආයුබෝවන්, ${user.fullName}!",
                    style: TextStyle(
                      fontSize: isMobile ? 26 : 34,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentLang == 'en'
                        ? "Take a moment to relax and meditate daily."
                        : "දිනපතා විරාම ගෙන නිතරම ධ්‍යානය කරන්න.",
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    currentLang == 'en'
                        ? "Meditation Sessions"
                        : "ධ්‍යානය සැසි",
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
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
                                // Pass the correct YouTube ID for the current language
                                final youtubeId = video.getYoutubeId(currentLang);
                                HomeRoutes.goToVideoPlayer(
                                  context,
                                  video,
                                  user.id,
                                  youtubeId,
                                );
                              }
                            : () {},
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
