import 'dart:async';
import 'package:camcontrol/splashscreen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// AutoCameraFlow
/// Flow:
/// 1) App launches -> splash screen with 5s wait + progress.
/// 2) Opens camera preview. After 5s, captures first (normal) photo.
/// 3) Wait 5s, zoom OUT (to device min zoom), then capture second photo.
/// 4) Wait 5s, record a 5s video.
/// 5) All media are saved to the device (Photos/Gallery) under album "AutoCam".
///
/// Notes:
/// - On most devices, the minimum zoom level is 1.0 (no true "zoom out").
/// This code sets the zoom to the camera's minZoomLevel (usually 1.0) for the second photo.
/// - Make sure to add the required permissions (Android/iOS snippets are in the chat message).

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auto Camera Flow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: SplashWaitScreen(cameras: cameras),
    );
  }
}
