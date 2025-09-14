import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'video_tile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void onVideoTap(String title) {
    // For now just show a message. Later can navigate to video player
    print('Tapped on $title');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("MamaMind"),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              "Welcome, Mom-to-be!",
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

            // Video Grid
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
              itemCount: 8, // 8 meditation videos
              itemBuilder: (context, index) {
                return VideoTile(
                  title: 'Session ${index + 1}',
                  isLocked: index >= 3, // example: lock videos after 3
                  isMobile: isMobile,
                  onTap: () => onVideoTap('Session ${index + 1}'),
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
