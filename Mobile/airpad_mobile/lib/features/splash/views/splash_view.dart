import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../discovery/views/connection_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  late VideoPlayerController _controller;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/splash.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoPlaying = true;
        });
        _controller.play();
      });

    _controller.addListener(() {
      if (_controller.value.isInitialized && 
          !_controller.value.isPlaying && 
          _controller.value.position >= _controller.value.duration) {
        // Video finished playing
        Get.offAll(() => const ConnectionView());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isVideoPlaying
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(color: Colors.blueAccent),
      ),
    );
  }
}
