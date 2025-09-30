import 'package:flutter/material.dart';
import 'package:mamamind/constants/app_config.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/video_provider.dart';
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
    final user = videoProvider.user;
    final videos = videoProvider.videos;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    if (_loading || authProvider.isInitializing) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not found")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(AppConfig.appName),
        elevation: 4,
        iconTheme: const IconThemeData(color: AppColors.buttonText),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome, ${user.fullName}!",
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Take a moment to relax and meditate daily.",
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 20,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Meditation Sessions",
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
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
                            ? () =>
                                HomeRoutes.goToVideoPlayer(context, video, user.id)
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
