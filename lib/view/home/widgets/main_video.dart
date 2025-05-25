import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motion_media/model/post_model.dart';
import 'package:motion_media/view/home/widgets/video_player.dart';

class MainVideoWithReplies extends StatefulWidget {
  final Post post;
  const MainVideoWithReplies({super.key, required this.post});

  @override
  State<MainVideoWithReplies> createState() => _MainVideoWithRepliesState();
}

class _MainVideoWithRepliesState extends State<MainVideoWithReplies> {
  List<Post> replies = [];
  bool isLoading = true;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
    _fetchReplies();
  }

  Future<void> _fetchReplies() async {
    try {
      final response = await Dio().get(
        'https://api.wemotions.app/posts/${widget.post.id}/replies',
      );
      final data = response.data;
      final fetchedReplies =
          (data['post'] as List).map((json) => Post.fromJson(json)).toList();
      setState(() {
        replies = fetchedReplies;
        isLoading = false;
      });
    } catch (e) {
      log("Error fetching replies: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final totalPages = 1 + replies.length; 
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            scrollDirection: Axis.horizontal,
            controller: _pageController,
            itemCount: totalPages,
            itemBuilder: (context, index) {
              final reply = replies[index ];
              return index == 0
                  ? VideoPlayerWidget(
                    videoUrl: widget.post.videoLink,
                    id: widget.post.id,
                  )
                  : MainVideoWithReplies(post: reply);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalPages,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? Colors.blue : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
