import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isSmall = width < 390;
          final horizontalPadding = isSmall ? 14.0 : 20.0;
          final verticalPadding = isSmall ? 20.0 : 32.0;
          final cardWidth = width < 600
              ? (width - (horizontalPadding * 2))
              : maxWidth;
          final adaptiveContentPadding = width < 380
              ? const EdgeInsets.all(18)
              : contentPadding;

          return Stack(
            children: [
              // PNG background — full cover, falls back to gradient+blobs on error
              Positioned.fill(
                child: Image.asset(
                  'assets/login/Mindful_Cradle_Login_Background.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback: soothing gradient + ambient blobs
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFF8F5F2), Color(0xFFF4F0EC)],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -80,
                          right: -60,
                          child: Container(
                            width: 260,
                            height: 260,
                            decoration: const BoxDecoration(
                              color: Color(0x265E8C7B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -80,
                          left: -60,
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: const BoxDecoration(
                              color: Color(0x1FD4856A),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: cardWidth),
                      child: Container(
                        width: double.infinity,
                        padding: adaptiveContentPadding,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                            const BoxShadow(
                              color: Color(0x0F4E7A6A),
                              blurRadius: 40,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
