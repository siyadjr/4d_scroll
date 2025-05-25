import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ChildVideoWidget extends StatefulWidget {
  final String videoUrl;

  const ChildVideoWidget({super.key, required this.videoUrl});

  @override
  State<ChildVideoWidget> createState() => _ChildVideoWidgetState();
}

class _ChildVideoWidgetState extends State<ChildVideoWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
