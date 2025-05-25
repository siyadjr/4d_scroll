import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motion_media/controller/play_controller.dart';
import 'package:motion_media/controller/scroll_indicator_controller.dart';
import 'package:motion_media/model/post_model.dart';
import 'package:motion_media/view/home/widgets/video_player.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class VideoThread extends StatefulWidget {
  final Post post;
  final Axis scrollDirection;
  final bool isRoot;
  final Function? onBackScroll;

  const VideoThread({
    super.key,
    required this.post,
    required this.scrollDirection,
    this.isRoot = true,
    this.onBackScroll,
  });

  @override
  State<VideoThread> createState() => _VideoThreadState();
}

class _VideoThreadState extends State<VideoThread> {
  List<Post> replies = [];
  bool isLoading = true;
  bool hasError = false;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? 0;
      if (newPage != _currentPage && mounted) {
        setState(() {
          _currentPage = newPage;
        });
        _handlePageChange(newPage);
      }
    });
    _fetchReplies();
    log('Reached video is ${widget.post.id}');

    if (widget.isRoot) {
      Future.microtask(() {
        Provider.of<PlayController>(
          context,
          listen: false,
        ).setActivePost(widget.post.id);
      });
    }
  }

  void _updateScrollIndicators() {
    final provider = Provider.of<ScrollIndicatorController>(
      context,
      listen: false,
    );
    provider.setRightCount(replies.length);
    replies.isNotEmpty
        ? provider.rightToggleTrue()
        : provider.rightToggleFalse();
  }

  bool get _shouldShowLeftIndicator {
    final parent = widget.post.parentPost;

    // Show left only if this is not a third-level (1.1.1) or shallower post
    // i.e., if grandparent exists → this is 1.1.1.1 or deeper
    return parent != null && parent.parentPost != null;
  }

  void _handlePageChange(int newPage) {
    final provider = Provider.of<ScrollIndicatorController>(
      context,
      listen: false,
    );

    if (newPage == 0) {
      _updateScrollIndicators();

      if (widget.onBackScroll != null) {
        widget.onBackScroll!();
      }

      // ✨ Hide left indicator if we're at 1.1.1 level (post has parent, but parent has no parent)
      final isThirdLevel = _shouldShowLeftIndicator;
      log(isThirdLevel.toString());

      if (isThirdLevel) {
        provider.leftToggleFalse();
      } else {
        provider.leftToggleTrue();
      }
    } else {
      provider.leftToggleTrue();
      provider.setLeftCount(newPage);
      final isLastReply = newPage == replies.length;
      if (isLastReply) {
        provider.rightToggleFalse();
      } else {
        provider.setRightCount(replies.length - newPage);
        provider.rightToggleTrue();
      }
    }
  }

  Future<void> _fetchReplies() async {
    if (!mounted) return;

    try {
      final response = await Dio().get(
        'https://api.wemotions.app/posts/${widget.post.id}/replies',
      );

      final data = response.data;
      final fetchedReplies =
          (data['post'] as List).map((json) {
            final reply = Post.fromJson(json);
            return Post(
              id: reply.id,
              category: reply.category,
              slug: reply.slug,
              parentVideoId: reply.parentVideoId,
              childVideoCount: reply.childVideoCount,
              title: reply.title,
              thumbnail_url: reply.thumbnail_url,
              videoLink: reply.videoLink,
              parentPost: widget.post,
            );
          }).toList();

      if (!mounted) return;

      setState(() {
        replies = fetchedReplies;
        isLoading = false;
      });

      final provider = Provider.of<ScrollIndicatorController>(
        context,
        listen: false,
      );

      if (widget.isRoot) {
        _updateScrollIndicators();
      } else {
        if (fetchedReplies.isEmpty) {
          provider.rightToggleFalse();

          // ✨ Special case: Only show left if this is deep enough (1.1.1.1 or more)
          final isDeep =
              widget.post.parentPost != null &&
              widget.post.parentPost!.parentPost != null;
          isDeep ? provider.leftToggleTrue() : provider.leftToggleFalse();
        } else {
          provider.rightToggleTrue();
        }
      }
    } catch (e, stack) {
      log("Error fetching replies", error: e, stackTrace: stack);
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Failed to load replies',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                hasError = false;
              });
              _fetchReplies();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('thread-${widget.post.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= 0.7 && mounted) {
          if (_currentPage == 0) {
            Provider.of<PlayController>(
              context,
              listen: false,
            ).setActivePost(widget.post.id);
          } else if (_currentPage <= replies.length) {
            Provider.of<PlayController>(
              context,
              listen: false,
            ).setActivePost(replies[_currentPage - 1].id);
          }
        }
      },
      child:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasError
              ? _buildErrorView()
              : _buildThreadContent(),
    );
  }

  Widget _buildThreadContent() {
    final totalPages = 1 + replies.length;

    return Stack(
      children: [
        PageView.builder(
          scrollDirection: widget.scrollDirection,
          controller: _pageController,
          physics: const ClampingScrollPhysics(),
          itemCount: replies.isEmpty ? 1 : totalPages,
          itemBuilder: (context, index) {
            if (index == 0) {
              return ManagedVideoPlayer(
                videoUrl: widget.post.videoLink,
                postId: widget.post.id,
                parentPost: widget.post,
              );
            } else {
              final reply = replies[index - 1];
              final childAxis =
                  widget.scrollDirection == Axis.horizontal
                      ? Axis.vertical
                      : Axis.horizontal;
              return VideoThread(
                post: reply,
                scrollDirection: childAxis,
                isRoot: false,
                onBackScroll: () {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                  _updateScrollIndicators();
                },
              );
            }
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

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
        return VideoPlayerWidget(
          videoUrl: videoUrl,
          id: postId,
          parentPost: parentPost,
          autoPlay: isActive,
          onVideoTap: () {
            Provider.of<PlayController>(
              context,
              listen: false,
            ).setActivePost(postId);
          },
        );
      },
    );
  }
}
