    import 'package:flutter/material.dart';

    class ScrollIndicatorController extends ChangeNotifier {
      // Directional visibility indicators
      bool _left = false;
      bool _right = false;
      bool _top = false;
      bool _bottom = false;

      // Directional child counts
      int _leftCount = 0;
      int _rightCount = 0;
      int _topCount = 0;
      int _bottomCount = 0;

      // Getters
      bool get left => _left;
      bool get right => _right;
      bool get top => _top;
      bool get bottom => _bottom;

      int get leftCount => _leftCount;
      int get rightCount => _rightCount;
      int get topCount => _topCount;
      int get bottomCount => _bottomCount;

      // Toggle methods
      void leftToggleTrue() {
        _left = true;
        notifyListeners();
      }

      void leftToggleFalse() {
        _left = false;
        notifyListeners();
      }

      void rightToggleTrue() {
        _right = true;
        notifyListeners();
      }

      void rightToggleFalse() {
        _right = false;
        notifyListeners();
      }

      void topToggleTrue() {
        _top = true;
        notifyListeners();
      }

      void topToggleFalse() {
        _top = false;
        notifyListeners();
      }

      void bottomToggleTrue() {
        _bottom = true;
        notifyListeners();
      }

      void bottomToggleFalse() {
        _bottom = false;
        notifyListeners();
      }

      // Setters for counts
      void setLeftCount(int count) {
        _leftCount = count;
        notifyListeners();
      }

      void setRightCount(int count) {
        _rightCount = count;
        notifyListeners();
      }

      void setTopCount(int count) {
        _topCount = count;
        notifyListeners();
      }

      void setBottomCount(int count) {
        _bottomCount = count;
        notifyListeners();
      }

      // Batch update method to set all indicators and counts at once
      void updateIndicators({
        bool? left,
        bool? right,
        bool? top,
        bool? bottom,
        int? leftCount,
        int? rightCount,
        int? topCount,
        int? bottomCount,
      }) {
        if (left != null) _left = left;
        if (right != null) _right = right;
        if (top != null) _top = top;
        if (bottom != null) _bottom = bottom;
        if (leftCount != null) _leftCount = leftCount;
        if (rightCount != null) _rightCount = rightCount;
        if (topCount != null) _topCount = topCount;
        if (bottomCount != null) _bottomCount = bottomCount;
        notifyListeners(); // Single notification for all changes
      }

      // Reset everything
      void resetAll() {
        _left = _right = _top = _bottom = false;
        _leftCount = _rightCount = _topCount = _bottomCount = 0;
        notifyListeners();
      }
    }