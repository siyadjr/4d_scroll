import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:motion_media/core/secured/medias_api.dart';
import 'package:motion_media/model/post_model.dart';

class FeedProvider with ChangeNotifier {
  List<Post> posts = [];
  bool isLoading = false;

  Future<void> getFeedDatas() async {
    log('Got messages');
    isLoading = true;
    notifyListeners();
    try {
      final fetchedPosts = await MediasApi().getData(); // <- use a variable
      posts = fetchedPosts; // <- assign it to the provider's list
      if (posts.isEmpty) {
        log('not got ');
      }
    } catch (e) {
      print(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class VideoNode {
  String videoLink;
  VideoNode({required this.videoLink});
  List<VideoNode> childrens = [];
}
//https://api.wemotions.app/posts/{id}/replies it will be the childrens api
