import 'dart:developer';

import 'package:flutter/material.dart';

class PlayController extends ChangeNotifier {
  int? _activePostId;

  int? get activePostId => _activePostId;

  void setActivePost(int? postId) {
    log('this is current post id $postId');
    if (_activePostId != postId) {
      _activePostId = postId;
      notifyListeners();
    }
  }
}
