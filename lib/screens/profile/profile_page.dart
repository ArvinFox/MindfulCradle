import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    final authProvider = Provider.of<AuthProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);

    final user = authProvider.user;

    if (authProvider.isInitializing) {
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
        title: Text(
          langProvider.currentLang == 'en' ? "Profile" : "ප්‍රොෆයිල්",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(
                    langProvider.currentLang == 'en'
                        ? "Logout Confirmation"
                        : "පිටවීම තහවුරු කිරීම",
                  ),
                  content: Text(
                    langProvider.currentLang == 'en'
                        ? "Are you sure you want to logout?"
                        : "ඔබට පිටවීමට කැමතිද?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        langProvider.currentLang == 'en' ? "Cancel" : "අවලංගු කරන්න",
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        langProvider.currentLang == 'en' ? "Logout" : "පිටවන්න",
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed ?? false) {
                await authProvider.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              }
            },
          )
        ],
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
              "${langProvider.currentLang == 'en' ? "Name" : "නම"}: ${user.fullName}",
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${langProvider.currentLang == 'en' ? "Email" : "ඊමේල්"}: ${user.email}",
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              langProvider.currentLang == 'en' ? "Settings" : "සැකසුම්",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(langProvider.currentLang == 'en' ? "Language" : "භාෂාව"),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: langProvider.currentLang == 'en' ? "English" : "සිංහල",
                  items: const [
                    DropdownMenuItem(value: "English", child: Text("English")),
                    DropdownMenuItem(value: "සිංහල", child: Text("සිංහල")),
                  ],
                  onChanged: (val) {
                    if (val == null) return;
                    langProvider.setLanguage(val == "English" ? "en" : "si");
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
