import 'package:flutter/material.dart';
import 'package:motion_media/controller/scroll_indicator_controller.dart';
import 'package:motion_media/controller/feed_provider.dart';
import 'package:motion_media/view/home/scroll_indicator.dart';
import 'package:motion_media/view/home/video_thread.dart';
import 'package:provider/provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

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
      Provider.of<FeedProvider>(
        context,
        listen: false,
      ).getFeedDatas().then((_) => _updateMainIndicators());
    });
  }

  void _onPageChange() {
    final newPage = _pageController.page?.round() ?? 0;
    if (newPage != _currentPage) {
      _currentPage = newPage;
      _updateMainIndicators();
    }
  }

  void _updateMainIndicators() {
    final feed = Provider.of<FeedProvider>(context, listen: false);
    final main = feed.posts.where((p) => p.parentVideoId == null).toList();
    final ctrl = Provider.of<ScrollIndicatorController>(context, listen: false);

    final childCount =
        main.isNotEmpty ? (main[_currentPage].childVideoCount ?? 0) : 0;

    ctrl.updateIndicators(
      top: _currentPage > 0,
      topCount: _currentPage,
      bottom: _currentPage < main.length - 1,
      bottomCount: main.length - _currentPage - 1,
      left: false,
      leftCount: 0,
      right: childCount > 0,
      rightCount: childCount,
    );
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
              return const Center(child: CircularProgressIndicator());
            }
            final main =
                feed.posts.where((p) => p.parentVideoId == null).toList();
            if (main.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam_off,
                      size: 64,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No videos available',
                      style: TextStyle(color: Colors.white),
                    ),
                    ElevatedButton(
                      onPressed: feed.getFeedDatas,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              );
            }
            return Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: main.length,
                  onPageChanged: (_) => _updateMainIndicators(),
                  itemBuilder: (_, i) {
                    if(main[i].childVideoCount>0){
                      _updateMainIndicators();
                    }
                    return VideoThread(
                      post: main[i],
                      scrollDirection: Axis.horizontal,
                    );
                  },
                ),
                const Positioned(
                  bottom: 16,
                  right: 16,
                  child: ScrollIndicator(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
