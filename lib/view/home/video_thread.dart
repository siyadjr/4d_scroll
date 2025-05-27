import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motion_media/controller/play_controller.dart';
import 'package:motion_media/controller/scroll_indicator_controller.dart';
import 'package:motion_media/model/post_model.dart';
import 'package:motion_media/view/home/manage_video_player.dart';

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
  final _debounce = Debouncer(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final newPage = _pageController.page?.round() ?? 0;
      if (newPage != _currentPage && mounted) {
        _debounce(() {
          setState(() {
            _currentPage = newPage;
          });
         
          if (newPage == 0 && widget.onBackScroll != null) {
            // widget.onBackScroll!();
          }
        });
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

  // Determine current Post
  Post currentPost = (_currentPage == 0) ? widget.post : replies[_currentPage - 1];

  // Left indicator: Enable if currentPost has a parent (not top-level)
  final hasParent = currentPost.parentPost != null;

  // Right indicator: Enable if currentPost has children (childVideoCount > 0)
  final hasChildren = (currentPost.childVideoCount ?? 0) > 0;

  // Number of children for the indicator count
  final childrenCount = currentPost.childVideoCount ?? 0;

  // Determine which indicators to show based on scroll direction
  bool left = false, right = false, top = false, bottom = false;
  int leftCount = 0, rightCount = 0, topCount = 0, bottomCount = 0;

  if (widget.scrollDirection == Axis.vertical) {
    // Vertical scroll means scrolling top<->bottom
    // So children scroll on horizontal axis (left/right)
    left = hasParent;
    leftCount = hasParent ? 1 : 0;
    right = hasChildren;
    rightCount = childrenCount;

    // For root, preserve top/bottom indicators if needed
    top = widget.isRoot ? provider.top : false;
    bottom = widget.isRoot ? provider.bottom : false;
    topCount = widget.isRoot ? provider.topCount : 0;
    bottomCount = widget.isRoot ? provider.bottomCount : 0;
  } else {
    // Horizontal scroll means scrolling left<->right
    // So children scroll on vertical axis (top/bottom)
    top = hasChildren;
    topCount = childrenCount;
    bottom = false; // Usually no "bottom" in this design, but can be extended
    left = hasParent;
    leftCount = hasParent ? 1 : 0;
    right = false;

    bottomCount = 0;
    rightCount = 0;
  }

  provider.updateIndicators(
    left: left,
    leftCount: leftCount,
    right: right,
    rightCount: rightCount,
    top: top,
    bottom: bottom,
    topCount: topCount,
    bottomCount: bottomCount,
  );
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

      _updateScrollIndicators();
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

class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  bool _isWaiting = false;

  Debouncer({required this.milliseconds});

  call(VoidCallback callback) {
    if (_isWaiting) return;
    _isWaiting = true;
    action = callback;
    Future.delayed(Duration(milliseconds: milliseconds), () {
      _isWaiting = false;
      action?.call();
    });
  }
}

