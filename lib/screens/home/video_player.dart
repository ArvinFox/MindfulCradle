import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/cupertino.dart';
import '../../constants/colors.dart';
import '../../models/video_model.dart';
import '../../providers/video_provider.dart';

class YouTubeVideoPlayerPage extends StatefulWidget {
  final VideoModel video;
  final String userId;
  final String youtubeId; //language-specific ID

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
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
      ),
    );

    if (_watchedSeconds > 0) {
      _controller.seekTo(Duration(seconds: _watchedSeconds)); 
    }

    _controller.addListener(_youtubeListener);
    _startProgressTimer();
  }

  void _youtubeListener() {
    if (mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    setState(() {});
  }

  void _startProgressTimer() {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    _progressTimer?.cancel();

    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_controller.value.isPlaying && mounted) {
        _watchedSeconds += 1;
        if (_watchedSeconds % 5 == 0) {
          videoProvider.updateProgress(
            userId: widget.userId,
            videoId: widget.video.id,
            watchedSeconds: _watchedSeconds,
          );
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _progressTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _startProgressTimer();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAndSaveProgress();
    _controller.dispose();
    super.dispose();
  }

  void _stopAndSaveProgress() {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    _progressTimer?.cancel();
    _controller.removeListener(_youtubeListener);
    _controller.pause();
    
    videoProvider.updateProgress(
      userId: widget.userId,
      videoId: widget.video.id,
      watchedSeconds: _watchedSeconds,
    );
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    double progress = widget.video.duration > 0
        ? (_watchedSeconds / widget.video.duration).clamp(0.0, 1.0)
        : 0.0;

    return WillPopScope(
      onWillPop: () async {
        _stopAndSaveProgress();
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        return true;
      },
      child: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true, 
          progressIndicatorColor: AppColors.primary, 
          onReady: () {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          },
        ),
        builder: (context, player) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              elevation: 4, 
              leading: CupertinoNavigationBarBackButton(
                color: Colors.white,
                onPressed: () {
                  _stopAndSaveProgress();
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                  Navigator.of(context).pop();
                },
              ),
              title: Text(
                widget.video.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600, 
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              centerTitle: true,
            ),
            body: Column(
              children: [
                const SizedBox(height: 0),
                
                // Video Player
                Container(
                  color: Colors.black,
                  child: player,
                ),
                
                // Progress Bar Section
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.30), 
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
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(20)),
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}