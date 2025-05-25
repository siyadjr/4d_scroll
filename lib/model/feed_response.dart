import 'package:motion_media/model/post_model.dart';

class FeedResponse {
  final int page;
  final int maxPageSize;
  final int pageSize;
  final List<Post> posts;

  FeedResponse({
    required this.page,
    required this.maxPageSize,
    required this.pageSize,
    required this.posts,
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    return FeedResponse(
      page: json['page'],
      maxPageSize: json['max_page_size'],
      pageSize: json['page_size'],
      posts: (json['posts'] as List).map((e) => Post.fromJson(e)).toList(),
    );
  }
}
