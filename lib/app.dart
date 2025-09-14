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
import 'package:mamamind/screens/home/home_page.dart';
import 'package:mamamind/screens/home/video_player.dart';
import 'package:mamamind/screens/main_screen.dart';
import 'package:mamamind/screens/signup/signup_page.dart';
import 'package:video_player/video_player.dart';
import 'screens/login/login_page.dart';
import 'constants/colors.dart';

class MamaMindApp extends StatelessWidget {
  const MamaMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MamaMind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: AppColors.text,
              displayColor: AppColors.text,
            ),
      ),
      home: const MainScreen(), // simple UI page for now
    );
  }
}
