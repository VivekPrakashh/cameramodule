import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraFlowScreen extends StatefulWidget {
  const CameraFlowScreen({super.key, required this.cameras});
  final List<CameraDescription> cameras;

  @override
  State<CameraFlowScreen> createState() => _CameraFlowScreenState();
}

class _CameraFlowScreenState extends State<CameraFlowScreen>
    with WidgetsBindingObserver {
  late CameraController _controller;
  bool _isInitialized = false;
  String _status = 'Preparing camera…';
  double _minZoom = 1.0;
  double _maxZoom = 5.0;

  int _countdown = 5; // shows on-screen countdowns between actions
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final back = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    _controller = CameraController(
      back,
      ResolutionPreset.high,
      enableAudio: true, // needed for video
    );

    try {
      await _controller.initialize();

      // Prepare zoom range
      try {
        _minZoom = await _controller.getMinZoomLevel();
        _maxZoom = await _controller.getMaxZoomLevel();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _status = 'Camera ready';
      });

      // Start the scripted capture flow
      _runScriptedFlow();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Failed to initialize camera: $e';
      });
    }
  }

  /// Utility: on-screen countdown before each step
  Future<void> _waitWithCountdown(int seconds, String status) async {
    if (!mounted) return;
    setState(() {
      _status = status;
      _countdown = seconds;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
      }
    });

    await Future.delayed(Duration(seconds: seconds));
  }

  /// Scripted camera flow
  Future<void> _runScriptedFlow() async {
    // First photo (normal)
    await _waitWithCountdown(5, 'Hold still… Taking first photo in');
    try {
      await _controller.setZoomLevel(_minZoom);
      final XFile file1 = await _controller.takePicture();
      await GallerySaver.saveImage(file1.path, albumName: 'AutoCam');
      setState(() => _status = 'First photo saved');
    } catch (e) {
      setState(() => _status = 'Error taking first photo: $e');
      return;
    }

    // Second photo (zoomed out)
    await _waitWithCountdown(5, 'Zooming out… Second photo in');
    try {
      await _controller.setZoomLevel(_maxZoom);
      final XFile file2 = await _controller.takePicture();
      await GallerySaver.saveImage(file2.path, albumName: 'AutoCam');
      setState(() => _status = 'Second (zoomed-out) photo saved');
    } catch (e) {
      setState(() => _status = 'Error taking second photo: $e');
      return;
    }

    // Video (5 seconds)
    await _waitWithCountdown(5, 'Get ready… Starting 5s video in');
    Future<void> recordVideo() async {
      // Request audio permission for video recording
      if (!await Permission.microphone.request().isGranted) {
        setState(() => _status = 'Microphone permission denied');
        return;
      }

      try {
        // Ensure controller is initialized
        if (!_controller.value.isInitialized) {
          setState(() => _status = 'Camera not initialized');
          return;
        }

        // Start video recording
        await _controller.startVideoRecording();

        // Wait for 5 seconds
        await Future.delayed(const Duration(seconds: 5));

        // Stop and save video
        final XFile video = await _controller.stopVideoRecording();
        await GallerySaver.saveVideo(video.path, albumName: 'AutoCam');

        setState(() => _status = 'Video saved');
      } catch (e) {
        setState(() => _status = 'Error recording video: $e');
      }
    }

    setState(() => _status = 'Done! 2 photos + 1 video saved.');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child:
            !_isInitialized
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _status,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                )
                : Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_controller),
                    // Top status bar
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                _status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.timer, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  '$_countdown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
