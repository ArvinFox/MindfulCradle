import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/cupertino.dart';
import '../../constants/colors.dart';
import '../../models/video_model.dart';
import '../../providers/video_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../widgets/connectivity_banner.dart';

class YouTubeVideoPlayerPage extends StatefulWidget {
  final VideoModel video;
  final String userId;
  final String youtubeId;

  const YouTubeVideoPlayerPage({
    super.key,
    required this.video,
    required this.userId,
    required this.youtubeId,
  });

  @override
  State<YouTubeVideoPlayerPage> createState() => _YouTubeVideoPlayerPageState();
}

class _YouTubeVideoPlayerPageState extends State<YouTubeVideoPlayerPage>
    with WidgetsBindingObserver {
  late YoutubePlayerController _controller;
  int _watchedSeconds = 0;
  Timer? _progressTimer;

  List<String> _hints = [];
  String _currentHint = "";
  Timer? _hintTimer;
  bool _hintVisible = true;
  bool _wasFullScreen = false;
  bool _isDisposing = false; // Flag to prevent multiple disposal calls
  bool _isExiting = false; // Flag to make video player invisible during exit

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    _watchedSeconds = videoProvider.getLastWatchedSecond(widget.video.id);

    _controller = YoutubePlayerController(
      initialVideoId: widget.youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: false,
        controlsVisibleAtStart: true,
        disableDragSeek: false,
        loop: true,
        isLive: false,
        forceHD: false,
        enableCaption: false,
      ),
    );

    _controller.addListener(_youtubeListener);
    _startProgressTimer();
    _loadHints();
  }

  Future<void> _loadHints() async {
    try {
      final langProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );
      final langCode = langProvider.currentLang;

      final jsonString = await rootBundle.loadString(
        'languages/video_hints.json',
      );
      final Map<String, dynamic> data = json.decode(jsonString);

      setState(() {
        _hints = List<String>.from(data[langCode] ?? data["en"]);
        _currentHint = _hints.isNotEmpty ? (_hints..shuffle()).first : "";
      });

      _startHintRotation();
    } catch (e) {
      if (kDebugMode) debugPrint("Error loading hints.");
    }
  }

  void _startHintRotation() {
    _hintTimer?.cancel();
    _hintTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_hints.isEmpty) return;
      setState(() => _hintVisible = false);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _currentHint = (_hints..shuffle()).first;
          _hintVisible = true;
        });
      });
    });
  }

  void _youtubeListener() {
    if (!mounted) return;

    // With loop enabled, video will automatically restart, so we don't need to handle ended state
    // The timer will continue running as the video loops

    if (_controller.value.isFullScreen != _wasFullScreen) {
      _wasFullScreen = _controller.value.isFullScreen;
      if (_wasFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }

    setState(() {});
  }

  void _startProgressTimer() {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    _progressTimer?.cancel(); // Cancel any existing timer

    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_controller.value.isPlaying && mounted && !_isDisposing) {
        _watchedSeconds += 1;
        if (_watchedSeconds % 5 == 0) {
          videoProvider.updateProgress(
            context: context,
            userId: widget.userId,
            videoId: widget.video.id,
            watchedSeconds: _watchedSeconds,
          );
        }
      }
    });
  }

  Future<void> _flushProgress() async {
    // Note: This is called from dispose, so context might not be valid
    // Progress should already be saved in _handleExit, but this is a safety measure
    try {
      final videoProvider = Provider.of<VideoProvider>(context, listen: false);
      await videoProvider.updateProgress(
        context: context,
        userId: widget.userId,
        videoId: widget.video.id,
        watchedSeconds: _watchedSeconds,
      );
    } catch (e) {
      // Context might not be valid in dispose, progress was already saved in _handleExit
      debugPrint('Could not flush progress in dispose: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _progressTimer?.cancel();
      _flushProgress();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _startProgressTimer();
    }
  }

  @override
  void dispose() {
    if (_isDisposing) return; // Prevent multiple disposal calls
    _isDisposing = true;

    WidgetsBinding.instance.removeObserver(this);

    // Cancel all timers first
    _progressTimer?.cancel();
    _hintTimer?.cancel();

    // Stop video playback immediately
    if (_controller.value.isPlaying) {
      _controller.pause();
    }

    // Remove listener and dispose controller
    _controller.removeListener(_youtubeListener);
    _controller.dispose();

    // Flush any remaining progress
    _flushProgress();

    // Force portrait when page is destroyed
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Ensure bars are visible when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  /// Handles exiting: Saves progress -> Resets Orientation -> Checks Achievements -> Pops
  Future<void> _handleExit({bool isSystemBack = false}) async {
    if (_isDisposing) return; // Prevent multiple exit calls

    // Make video player invisible immediately and pause playback
    setState(() => _isExiting = true);
    _controller.pause();

    _progressTimer?.cancel();
    _controller.removeListener(_youtubeListener);

    // Save Progress synchronously to ensure it's saved before navigation
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    await videoProvider.updateProgress(
      context: context,
      userId: widget.userId,
      videoId: widget.video.id,
      watchedSeconds: _watchedSeconds,
    );

    // Handle Achievements & Pop
    final achProvider = Provider.of<AchievementProvider>(
      context,
      listen: false,
    );

    if (!isSystemBack) {
      // Navigate immediately without delay
      Navigator.of(context).pop();
    }

    // Trigger Pending Dialogs (shows on the home screen) - do this after navigation
    achProvider.showPendingAchievements(context);

    // Do orientation reset after navigation to avoid delaying the UI
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    double progress = widget.video.duration > 0
        ? (_watchedSeconds / widget.video.duration).clamp(0.0, 1.0)
        : 0.0;

    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isSinhala = langProvider.currentLang == "si";

    return WillPopScope(
      onWillPop: () async {
        // HANDLE FULL SCREEN BACK PRESS
        if (_controller.value.isFullScreen) {
          _controller.toggleFullScreenMode();
          return false;
        }
        await _handleExit(isSystemBack: true);
        return true;
      },
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.primary,
        ),
        builder: (context, player) {
          return Stack(
            children: [
              Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  backgroundColor: AppColors.primary,
                  elevation: 4,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () async {
                      await _handleExit(isSystemBack: false);
                    },
                  ),

                  title: Text(
                    langProvider.currentLang == "si"
                        ? widget.video.titleSi
                        : widget.video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  centerTitle: true,
                ),
                body: Column(
                  children: [
                    // Video Player Area - Make invisible during exit to prevent artifacts
                    Opacity(opacity: _isExiting ? 0.0 : 1.0, child: player),

                    // Fixed Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Instructions & Hints
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.12,
                              child: Image.asset(
                                'assets/video_player/video_player_background.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSinhala ? "උපදෙස්:" : "Instructions:",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.65),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(
                                        0.25,
                                      ),
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: isSinhala
                                      ? RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 15.5,
                                              height: 1.6,
                                              color: AppColors.text,
                                            ),
                                            children: [
                                              TextSpan(
                                                text:
                                                    "Mindful Cradle යනු ගැබ්ණි මව්වරුන් සඳහා නිර්මාණය කළ මනෝනිබඳ යෙදුමකි. මෙය ඔබගේ මනස හා ශරීරය සන්සුන් තත්ත්වයක තබා ගැනීමට උපකාරී වේ.\n\n",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const TextSpan(
                                                text:
                                                    "🌸 සන්සුන් ස්ථානයක වාඩි වන්න.\n🌸 හුස්ම ගැනීම මත අවධානය යොමු කරන්න.\n🌸 හිතාමතා අරමුණක් තබා ගන්න — “මම සහ මගේ බිළිඳා සුරක්ෂිතයි.”\n🌸 මෘදු සංගීතයක් අසන්න.\n🌸 මනස විවේකයෙන් තබා ගැනීමට මෙම වීඩියෝව භාවිතා කරන්න.",
                                              ),
                                            ],
                                          ),
                                        )
                                      : RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 15.5,
                                              height: 1.6,
                                              color: AppColors.text,
                                            ),
                                            children: [
                                              TextSpan(
                                                text:
                                                    "Mindful Cradle is a mindful app designed for pregnant mothers. It helps you stay calm and emotionally balanced during your pregnancy.\n\n",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const TextSpan(
                                                text:
                                                    "🌸 Sit comfortably in a quiet space.\n🌸 Gently focus on your breath.\n🌸 Set a kind intention — 'My baby and I are safe and peaceful.'\n🌸 Play relaxing background music.\n🌸 Use this video to remain mindful and relaxed.",
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 30),
                                Text(
                                  isSinhala ? "උපදේශන සටහන්:" : "Hints:",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_currentHint.isNotEmpty)
                                  AnimatedOpacity(
                                    opacity: _hintVisible ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 300),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.12,
                                        ),
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(
                                            0.3,
                                          ),
                                          width: 1.0,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.all(18),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.psychology_outlined,
                                            color: AppColors.primary,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _currentHint,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                height: 1.5,
                                                color: Colors.black87,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ConnectivityBanner(),
              ),
            ],
          );
        },
      ),
    );
  }
}
