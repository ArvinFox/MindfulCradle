import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry contentPadding;

  const AuthScaffold({
    super.key,
    required this.child,
    this.maxWidth = 400,
    this.contentPadding = const EdgeInsets.all(30),
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/login/app_background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.background.withOpacity(0.10),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Container(
                width: isMobile ? size.width * 0.9 : maxWidth,
                padding: contentPadding,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 3,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.05),
                      spreadRadius: -2,
                      blurRadius: 10,
                      offset: const Offset(-5, -5),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
