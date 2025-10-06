import 'package:flutter/material.dart';
import 'package:mamamind/utils/logout_util.dart';
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

    const appBarTextStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w500,
      fontSize: 22,
    );

    if (authProvider.isInitializing) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            langProvider.currentLang == 'en' ? "User data not available" : "පරිශීලක දත්ත නොමැත",
            style: TextStyle(color: AppColors.text),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          langProvider.currentLang == 'en' ? "Profile" : "ප්‍රොෆයිල්",
          style: appBarTextStyle,
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(65),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.person, size: 80, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                user.fullName,
                style: TextStyle(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            Center(
              child: Text(
                user.email,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.text.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: AppColors.cardBackground,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Text(
                        langProvider.currentLang == 'en' ? "Settings" : "සැකසුම්",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                    
                    ListTile(
                      leading: Icon(Icons.language, color: AppColors.primary),
                      title: Text(
                        langProvider.currentLang == 'en' ? "Language" : "භාෂාව",
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: langProvider.currentLang == 'en' ? "en" : "si",
                          style: TextStyle(color: AppColors.text, fontSize: 16),
                          dropdownColor: AppColors.cardBackground,
                          items: const [
                            DropdownMenuItem(
                              value: "en",
                              child: Text("English"),
                            ),
                            DropdownMenuItem(value: "si", child: Text("සිංහල")),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              langProvider.setLanguage(val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  LogoutUtils.showLogoutDialog(
                    context: context,
                    authProvider: authProvider,
                    language: langProvider.currentLang,
                    redirectRoute: '/login',
                  );
                },
                icon: Icon(Icons.exit_to_app, color: Colors.redAccent),
                label: Text(
                  langProvider.currentLang == 'en' ? "Log Out" : "ලොග් අවුට්",
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}