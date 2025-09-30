// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'routes/app_routes.dart';
// import 'constants/colors.dart';
// import 'providers/user_provider.dart';
// import 'providers/video_provider.dart';
// import 'screens/login/login_page.dart';

// class MamaMindApp extends StatelessWidget {
//   const MamaMindApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => UserProvider()),
//         ChangeNotifierProvider(create: (_) => VideoProvider()),
//       ],
//       child: MaterialApp(
//         title: 'MamaMind',
//         debugShowCheckedModeBanner: false,
//         theme: ThemeData(
//           primaryColor: AppColors.primary,
//           scaffoldBackgroundColor: AppColors.background,
//           textTheme: Theme.of(context).textTheme.apply(
//                 bodyColor: AppColors.text,
//                 displayColor: AppColors.text,
//               ),
//         ),
//         home: const LoginPage(),
//         routes: AppRoutes.routes,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:mamamind/constants/app_config.dart';
import 'package:mamamind/screens/auth/login_page.dart';
import 'package:mamamind/screens/main_screen.dart';
import 'package:mamamind/screens/splashScreen/splash_screen.dart';
import 'package:mamamind/screens/auth/user_registration_page.dart'; // <- import registration page
import 'constants/colors.dart';
import 'routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

class MamaMindApp extends StatelessWidget {
  const MamaMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        Widget home;

        if (authProvider.isInitializing) {
          home = const SplashPage();
        } else if (authProvider.isLoggedIn) {
          final user = authProvider.user;

          // Check if the user has completed registration
          if (user != null && (user.toMap()['isUserRegistrationComplete'] ?? false) == false) {
            home = UserRegistrationPage(user: user);
          } else {
            home = const MainScreen();
          }
        } else {
          home = const LoginPage();
        }

        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.background,
            textTheme: Theme.of(context).textTheme.apply(
                  bodyColor: AppColors.text,
                  displayColor: AppColors.text,
                ),
          ),
          home: home,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}

