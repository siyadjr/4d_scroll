
import 'package:flutter/material.dart';
import 'package:motion_media/controller/play_controller.dart';
import 'package:motion_media/model/post_model.dart';
import 'package:motion_media/view/home/widgets/video_player.dart';
import 'package:provider/provider.dart';

class ManagedVideoPlayer extends StatelessWidget {  
  final String videoUrl;
  final int postId;
  final Post? parentPost;

  const ManagedVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.postId,
    this.parentPost,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayController>(
      builder: (context, playController, child) {
        final isActive = playController.activePostId == postId;
        return SizedBox.expand(
          child: VideoPlayerWidget(
            videoUrl: videoUrl,
            id: postId,
            parentPost: parentPost,
            autoPlay: isActive,
            onVideoTap: () {
              Provider.of<PlayController>(context, listen: false).setActivePost(postId);
            },
          ),
        );
      },
    );
  }
}