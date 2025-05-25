import 'package:flutter/material.dart';
import 'package:motion_media/controller/feed_provider.dart';
import 'package:motion_media/controller/play_controller.dart';
import 'package:motion_media/controller/scroll_indicator_controller.dart';
import 'package:motion_media/view/auth/splash_screen.dart';

import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => ScrollIndicatorController()),
        ChangeNotifierProvider(create: (_) => PlayController()),
      ],
      child: MaterialApp(
        title: 'Motion Media',
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
