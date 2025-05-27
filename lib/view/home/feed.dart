import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:motion_media/controller/feed_provider.dart';
import 'package:motion_media/controller/play_controller.dart';
import 'package:motion_media/model/post_model.dart';
import 'package:motion_media/view/home/manage_video_player.dart';
import 'package:provider/provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      final playController = Provider.of<PlayController>(context, listen: false);

      feedProvider.getFeedDatas().then((_) {
        if (feedProvider.posts.isNotEmpty) {
          playController.setActivePost(feedProvider.posts.first.id);
        }
      });
    });
  }

  void _onPageChange() {
    final newPage = _pageController.page?.round() ?? 0;
    if (newPage != _currentPage) {
      _currentPage = newPage;
      final feed = Provider.of<FeedProvider>(context, listen: false);
      final post = feed.posts[_currentPage];
      Provider.of<PlayController>(context, listen: false).setActivePost(post.id);
    }
  }

  @override
  void dispose() {
    _pageController
      ..removeListener(_onPageChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Consumer<FeedProvider>(
          builder: (_, feed, __) {
            if (feed.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              );
            }
            final main = feed.posts;
            if (main.isEmpty) {
              return _buildEmptyState(feed);
            }
            return Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  physics:
                      feed.currentDepth > 0
                          ? const NeverScrollableScrollPhysics()
                          : const AlwaysScrollableScrollPhysics(),
                  itemCount: main.length,
                  onPageChanged: (index) {
                    log('Changed main feed page to $index');
                    feed.resetToMainFeed();
                    final post = main[index];
                    Provider.of<PlayController>(
                      context,
                      listen: false,
                    ).setActivePost(post.id);
                  },
                  itemBuilder: (_, i) {
                    return NestedFeedManager(post: main[i], depth: 0);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(FeedProvider feed) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'No posts available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below',
            style: TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => feed.getFeedDatas(),
            icon: const Icon(Icons.refresh, color: Colors.black),
            label: const Text(
              'Refresh Feed',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class NestedFeedManager extends StatefulWidget {
  final Post post;
  final int depth;

  const NestedFeedManager({super.key, required this.post, required this.depth});

  @override
  State<NestedFeedManager> createState() => _NestedFeedManagerState();
}

class _NestedFeedManagerState extends State<NestedFeedManager> {
  PageController? _horizontalController;
  PageController? _verticalController;

  @override
  void initState() {
    super.initState();
    _horizontalController = PageController();
    _verticalController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<FeedProvider>(context, listen: false);
      provider.getReplies(widget.post, widget.depth);
    });
  }

  @override
  void dispose() {
    _horizontalController?.dispose();
    _verticalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedProvider>(
      builder: (context, provider, child) {
        final replies =
            provider.getRepliesForPost(widget.post.id, widget.depth) ?? [];

        if (widget.depth == 0) {
          // Main feed level - show horizontal replies
          return PageView.builder(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            physics: provider.currentDepth > 1 
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            itemCount: 1 + replies.length,
            onPageChanged: (index) {
              final playController = Provider.of<PlayController>(context, listen: false);
              if (index == 0) {
                provider.setCurrentDepth(0);
                provider.setCurrentPost(widget.post);
                playController.setActivePost(widget.post.id);
              } else {
                provider.setCurrentDepth(1);
                provider.setCurrentPost(replies[index - 1]);
                playController.setActivePost(replies[index - 1].id);
              }
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                // Main post
                return ManagedVideoPlayer(
                  videoUrl: widget.post.videoLink,
                  postId: widget.post.id,
                  parentPost: widget.post,
                );
              } else {
                // Reply to main post
                final reply = replies[index - 1];
                return NestedFeedManager(post: reply, depth: 1);
              }
            },
          );
        } else {
          // Reply level - show vertical nested replies if available
          final currentPost = widget.post;
          final hasNestedReplies = currentPost.childVideoCount > 0;

          if (hasNestedReplies && replies.isNotEmpty) {
            return PageView.builder(
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              physics:
                  provider.currentDepth > widget.depth
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
              itemCount: 1 + replies.length,
              onPageChanged: (index) {
                final playController = Provider.of<PlayController>(context, listen: false);
                if (index == 0) {
                  // Going back to parent level
                  if (widget.depth == 1) {
                    // If we're at depth 1, go back to depth 1 (stay at reply level)
                    provider.setCurrentDepth(1);
                  } else {
                    // If we're deeper, go back one level
                    provider.setCurrentDepth(widget.depth - 1);
                  }
                  provider.setCurrentPost(currentPost);
                  playController.setActivePost(currentPost.id);
                } else {
                  provider.setCurrentDepth(widget.depth + 1);
                  provider.setCurrentPost(replies[index - 1]);
                  playController.setActivePost(replies[index - 1].id);
                }
              },
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Current reply - this allows going back to parent
                  return ManagedVideoPlayer(
                    videoUrl: currentPost.videoLink,
                    postId: currentPost.id,
                    parentPost: currentPost,
                  );
                } else {
                  // Nested reply
                  final nestedReply = replies[index - 1];
                  return NestedFeedManager(
                    post: nestedReply,
                    depth: widget.depth + 1,
                  );
                }
              },
            );
          } else if (provider.isLoadingReplies[currentPost.id] == true) {
            // Show loading for replies
            return Container(
              color: Colors.black,
              child: Stack(
                children: [
                  ManagedVideoPlayer(
                    videoUrl: currentPost.videoLink,
                    postId: currentPost.id,
                    parentPost: currentPost,
                  ),
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // No nested replies - just show the video
            return ManagedVideoPlayer(
              videoUrl: currentPost.videoLink,
              postId: currentPost.id,
              parentPost: currentPost,
            );
          }
        }
      },
    );
  }
}