import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motion_media/core/secured/medias_api.dart';
import 'package:motion_media/model/post_model.dart';

class FeedProvider with ChangeNotifier {
  List<Post> posts = [];
  Map<String, List<Post>> nestedReplies = {}; // Key: "postId_depth"
  bool isLoading = false;
  Map<int, bool> isLoadingReplies = {};
  
  int currentDepth = 0;
  Post? currentPost;

  void setCurrentDepth(int depth) {
    if (currentDepth != depth) {
      currentDepth = depth;
      notifyListeners();
    }
  }

  void setCurrentPost(Post post) {
    currentPost = post;
    notifyListeners();
  }

  void resetToMainFeed() {
    currentDepth = 0;
    currentPost = null;
    notifyListeners();
  }

  String _getReplyKey(int postId, int depth) {
    return "${postId}_$depth";
  }

  List<Post>? getRepliesForPost(int postId, int depth) {
    return nestedReplies[_getReplyKey(postId, depth)];
  }

  Future<void> getFeedDatas() async {
    log('Getting feed data...');
    isLoading = true;
    notifyListeners();
    try {
      final fetchedPosts = await MediasApi().getData();
      posts = fetchedPosts;
      if (posts.isEmpty) {
        log('No posts found.');
      } else {
        log('Posts fetched: ${posts.length}');
      }
    } catch (e) {
      log('Error fetching posts: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getReplies(Post post, int depth) async {
    final replyKey = _getReplyKey(post.id, depth);
    
    // Don't fetch if already loading or already have replies
    if (isLoadingReplies[post.id] == true || nestedReplies.containsKey(replyKey)) {
      return;
    }

    isLoadingReplies[post.id] = true;
    notifyListeners();
    
    try {
      final response = await Dio().get(
        'https://api.wemotions.app/posts/${post.id}/replies',
      );
    
      final data = response.data;
      final fetchedReplies = (data['post'] as List).map((json) {
        final reply = Post.fromJson(json);
        return Post(
          id: reply.id,
          slug: reply.slug,
          parentVideoId: reply.parentVideoId,
          childVideoCount: reply.childVideoCount,
          title: reply.title,
          thumbnail_url: reply.thumbnail_url,
          videoLink: reply.videoLink,
          parentPost: post,
        );
      }).toList();

      nestedReplies[replyKey] = fetchedReplies;
      log('Replies fetched for post ${post.id} at depth $depth: ${fetchedReplies.length}');
      
      // Automatically fetch next level replies for posts that have them
      for (final reply in fetchedReplies) {
        if (reply.childVideoCount > 0) {
          getReplies(reply, depth + 1);
        }
      }
      
    } catch (e) {
      log('Error fetching replies for post ${post.id} at depth $depth: $e');
    } finally {
      isLoadingReplies[post.id] = false;
      notifyListeners();
    }
  }
}