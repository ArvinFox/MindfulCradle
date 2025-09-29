import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../constants/colors.dart';
import '../../models/video_model.dart';
import '../../providers/video_provider.dart';

class YouTubeVideoPlayerPage extends StatefulWidget {
  final VideoModel video;
  final String userId;

  const YouTubeVideoPlayerPage({
    super.key,
    required this.video,
    required this.userId,
  });

  @override
  State<YouTubeVideoPlayerPage> createState() => _YouTubeVideoPlayerPageState();
}

class _YouTubeVideoPlayerPageState extends State<YouTubeVideoPlayerPage> {
  late YoutubePlayerController _controller;
  int _watchedSeconds = 0;
  Timer? _progressTimer;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);

    // get last watched seconds for current user
    _watchedSeconds = videoProvider.getLastWatchedSecond(widget.video.id);

    _controller = YoutubePlayerController(
      initialVideoId: widget.video.youtubeId,
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
    setState(() {}); // refresh play/pause button
  }

  void _startProgressTimer() {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);

    // cancel previous timer just in case
    _progressTimer?.cancel();

    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_controller.value.isPlaying) {
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
  void dispose() {
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);
    _progressTimer?.cancel();
    _controller.removeListener(_youtubeListener);
    _controller.pause();

    // save last watched progress
    videoProvider.updateProgress(
      userId: widget.userId,
      videoId: widget.video.id,
      watchedSeconds: _watchedSeconds,
    );

    _controller.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppColors.primary,
        onReady: () {},
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            title: Text(widget.video.title),
            centerTitle: true,
          ),
          body: Column(
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _toggleControls,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    player,
                    if (_showControls)
                      IconButton(
                        iconSize: 64,
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                          _toggleControls();
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Watched: $_watchedSeconds sec / ${widget.video.duration} sec',
                style: const TextStyle(fontSize: 16, color: AppColors.text),
              ),
            ],
          ),
        );
      },
    );
  }
}
