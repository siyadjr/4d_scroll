import 'package:flutter/material.dart';
import 'package:motion_media/core/cutom_widgets/custom_scroll_indicator.dart';

class CustomScaffold extends StatelessWidget {
  final Widget body;
  final Color backgroundColor;

  const CustomScaffold({
    super.key,
    required this.body,
    this.backgroundColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: body,
      
    );
  }
}
