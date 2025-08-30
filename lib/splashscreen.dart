import 'dart:async';

import 'package:camcontrol/cameraflow.dart';
import 'package:camera/camera.dart';

import 'package:flutter/material.dart';

//late List<CameraDescription> cameras;

class SplashWaitScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const SplashWaitScreen({super.key, required this.cameras});

  @override
  State<SplashWaitScreen> createState() => _SplashWaitScreenState();
}

class _SplashWaitScreenState extends State<SplashWaitScreen> {
  static const int waitSeconds = 5;
  int _secondsLeft = waitSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _goToCamera();
      }
    });
  }

  Future<void> _goToCamera() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CameraFlowScreen(cameras: widget.cameras),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (waitSeconds - _secondsLeft) / waitSeconds;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Wait for 5 seconds then launch the camera',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(value: progress.clamp(0, 1)),
                  Text('$_secondsLeft'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
