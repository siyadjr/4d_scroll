import 'package:motion_media/core/secured/medias_api.dart';
import 'package:motion_media/model/post_model.dart';

class ReplyCache {
  static final Map<int, List<Post>> _cache = {};

  static Future<List<Post>> getReplies(int postId) async {
    if (_cache.containsKey(postId)) {
      return _cache[postId]!;
    }
    final replies = await MediasApi().getReplies(postId);
    _cache[postId] = replies;
    return replies;
  }

  static void clearCache() {
    _cache.clear();
  }
}