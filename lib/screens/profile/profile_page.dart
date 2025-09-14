import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Profile"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(Icons.person, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              "Name: Jane Doe",
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Email: jane.doe@example.com",
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Settings",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text("Language"),
              trailing: DropdownButton<String>(
                value: "English",
                items: const [
                  DropdownMenuItem(value: "English", child: Text("English")),
                  DropdownMenuItem(value: "සිංහල", child: Text("සිංහල")),
                ],
                onChanged: (val) {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
