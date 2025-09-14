import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class VideoTile extends StatelessWidget {
  final String title;
  final bool isLocked;
  final bool isMobile;
  final VoidCallback onTap;

  const VideoTile({
    super.key,
    required this.title,
    this.isLocked = false,
    required this.isMobile,
    required this.onTap,
  });

  void _showLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Locked Session"),
        content: const Text(
            "This session is locked. To unlock it, you need to complete the previous sessions."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isLocked) {
            _showLockedDialog(context);
          } else {
            onTap();
          }
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withOpacity(0.3),
        highlightColor: AppColors.primary.withOpacity(0.1),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Play button with its own InkWell
                    Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          if (isLocked) {
                            _showLockedDialog(context);
                          } else {
                            onTap();
                          }
                        },
                        borderRadius: BorderRadius.circular(50),
                        splashColor: AppColors.primary.withOpacity(0.3),
                        highlightColor: AppColors.primary.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.play_circle_fill,
                            size: isMobile ? 48 : 64,
                            color: isLocked ? Colors.grey : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 32,
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
}
