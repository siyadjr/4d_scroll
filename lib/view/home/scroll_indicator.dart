import 'package:flutter/material.dart';
import 'package:motion_media/controller/scroll_indicator_controller.dart';
import 'package:motion_media/core/cutom_widgets/custom_scroll_indicator.dart';
import 'package:provider/provider.dart';

class ScrollIndicator extends StatelessWidget {
  const ScrollIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScrollIndicatorController>(
      builder: (context, provider, child) {
        return SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Top Dot
              Positioned(top: 0, child: Dot(isActive: provider.top,count: provider.topCount,)),

              // Bottom Dot
              Positioned(bottom: 0, child: Dot(isActive: provider.bottom,count: provider.bottomCount,)),

              // Left Dot
              Positioned(left: 0, child: Dot(isActive: provider.left,count: provider.leftCount,)),

              // Right Dot
              Positioned(right: 0, child: Dot(isActive: provider.right,count: provider.rightCount,)),

              // Center Dot (Always visible or you can control with a flag)
              const Dot(
                isActive: true,
                color: Colors.pinkAccent,
              ), // Or pass another flag like `provider.center`
            ],
          ),
        );
      },
    );
  }
}
