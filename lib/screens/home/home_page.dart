import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mamamind/constants/app_config.dart';
import '../../constants/colors.dart';
import '../../widgets/video_tile.dart';
import '../../providers/auth_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void onVideoTap(String title) {
    print('Tapped on $title');
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
    final user = authProvider.user;

    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          AppConfig.appName,
          style: TextStyle(
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: AppColors.buttonText, // text color visible on primary
          ),
        ),
        centerTitle: false, // aligned to left
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
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, ${user?.fullName ?? 'Mom-to-be'}!",
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
              itemCount: 8,
              itemBuilder: (context, index) {
                final isUnlocked =
                    user?.unlockedVideos.contains(index + 1) ?? (index < 3);
                return VideoTile(
                  title: 'Session ${index + 1}',
                  isLocked: !isUnlocked,
                  isMobile: isMobile,
                  onTap: () =>
                      isUnlocked ? onVideoTap('Session ${index + 1}') : null,
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
