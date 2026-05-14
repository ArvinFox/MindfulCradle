import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/language_provider.dart';

class ConnectivityBanner extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final bool useSafeArea;
  final bool showShadow;
  final BorderRadiusGeometry borderRadius;

  const ConnectivityBanner({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.useSafeArea = true,
    this.showShadow = true,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    final hasInternet = context.watch<ConnectivityProvider>().hasInternet;
    if (hasInternet) return const SizedBox.shrink();

    final lang = context.watch<LanguageProvider>().currentLang;
    final message = lang == 'si'
        ? 'අන්තර්ජාල සම්බන්ධතාවයක් නොමැත'
        : 'No internet connection';

    final banner = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color.fromARGB(171, 211, 47, 47),
        borderRadius: borderRadius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );

    if (!useSafeArea) return banner;
    return SafeArea(child: banner);
  }
}
