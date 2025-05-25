import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:motion_media/model/post_model.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final int id;
  final Post? parentPost;
  final bool autoPlay;
  final bool muted;
  final VoidCallback? onVideoTap;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.id,
    this.parentPost,
    this.autoPlay = true,
    this.muted = false,
    this.onVideoTap,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isBuffering = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _shouldPlay = false;

  @override
  bool get wantKeepAlive => true; // Prevents state disposal when scrolling

  @override
  void initState() {
    super.initState();
    _shouldPlay = widget.autoPlay;
    _initializeVideo();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle autoPlay changes (this is how we control single video playback)
    if (widget.autoPlay != oldWidget.autoPlay) {
      _shouldPlay = widget.autoPlay;
      if (_isInitialized && _controller != null) {
        if (_shouldPlay) {
          _controller!.play();
        } else {
          _controller!.pause();
        }
      }
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _controller!.initialize();
      _controller!.setLooping(true);

      if (widget.muted) {
        _controller!.setVolume(0);
      }

      _controller!.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Start playing only if autoPlay was true
        if (_shouldPlay) {
          _controller!.play();
        }
      }
    } catch (e) {
      log('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video';
        });
      }
    }
  }

  void _videoListener() {
    if (_controller == null) return;

    final isBuffering = _controller!.value.isBuffering;
    if (_isBuffering != isBuffering && mounted) {
      setState(() {
        _isBuffering = isBuffering;
      });
    }
  }

  void _togglePlayPause() {
    if (!_isInitialized || _hasError || _controller == null) return;

    // Call the onVideoTap callback to notify parent components
    if (widget.onVideoTap != null) {
      widget.onVideoTap!();
    }

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _shouldPlay = false;
      } else {
        _controller!.play();
        _shouldPlay = true;
      }
    });
  }

  void _retryVideoLoad() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    _initializeVideo();
  }

  Widget _buildParentInfo() {
    if (widget.parentPost?.parentVideoId == null) return const SizedBox();

    return Positioned(
      top: 16,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Semi-transparent white
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.parentPost!.parentPost!.thumbnail_url,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Text
                  Flexible(
                    child: Text(
                      'Reply to ${widget.parentPost?.parentPost?.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black12,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retryVideoLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(color: Colors.black26),
        const CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildBufferingIndicator() {
    return _isBuffering
        ? const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          )
        : const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized || _controller == null) {
      return _buildLoadingWidget();
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The actual video player
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),

            // Parent post info header (now in the middle top with white container)
            _buildParentInfo(),

            // Buffering indicator
            _buildBufferingIndicator(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
      _controller = null;
    }
    super.dispose();
  }
}