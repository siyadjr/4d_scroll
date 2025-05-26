import 'package:motion_media/model/post_model.dart';
import 'package:motion_media/model/reply_cache.dart';

class PostNode {
  final Post post;
  PostNode? parent;
  final List<PostNode> _children = [];
  List<PostNode>? replies; // Cached replies

  PostNode({
    required this.post,
    this.parent,
  });

  List<PostNode> get children => List.unmodifiable(_children);

  void addChild(PostNode child) {
    child.parent = this;
    if (!_children.any((c) => c.post.id == child.post.id)) {
      _children.add(child);
    }
  }

  Future<void> fetchReplies() async {
    if (replies != null) return;
    final fetchedReplies = await ReplyCache.getReplies(post.id);
    replies = fetchedReplies.map((reply) => PostNode(post: reply)..parent = this).toList();
  }
}