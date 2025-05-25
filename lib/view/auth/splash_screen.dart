import 'package:flutter/material.dart';
import 'package:motion_media/core/secured/medias_api.dart';
import 'package:motion_media/core/theme/app_colour.dart';
import 'package:motion_media/view/home/dummy.dart';
import 'package:motion_media/view/home/feed.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (ctx) => FeedScreen()),
      );
    });
    return Scaffold(
      backgroundColor: AppColour().decorateColour,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome Back', style: TextStyle(color: Colors.white)),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
