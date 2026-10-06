import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/signalr_service.dart';

class RemoteView extends StatelessWidget {
  const RemoteView({super.key});

  @override
  Widget build(BuildContext context) {
    final signalRService = Get.find<SignalRService>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep dark background
      appBar: AppBar(
        title: const Text('AirPad Control', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStreamDeckButton(Icons.bedtime, 'Sleep', Colors.indigoAccent, () => signalRService.invoke('Sleep')),
              _buildStreamDeckButton(Icons.lock, 'Lock', Colors.redAccent, () => signalRService.invoke('LockScreen')),
              _buildStreamDeckButton(Icons.mic, 'Mic Mute', Colors.orangeAccent, () => signalRService.invoke('ToggleMic')),
              _buildStreamDeckButton(Icons.screenshot, 'Screenshot', Colors.greenAccent, () => signalRService.invoke('TakeScreenshot')),
              _buildStreamDeckButton(Icons.play_arrow, 'Play/Pause', Colors.blueAccent, () {}),
              _buildStreamDeckButton(Icons.volume_up, 'Volume Up', Colors.purpleAccent, () {}),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTouchpad,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.mouse, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStreamDeckButton(IconData icon, String label, Color accentColor, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: accentColor),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTouchpad() {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Drag Handle
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onPanUpdate: (details) {
                  final dx = details.delta.dx.toInt();
                  final dy = details.delta.dy.toInt();
                  if (dx != 0 || dy != 0) {
                     Get.find<SignalRService>().invoke('MoveMouse', args: [dx, dy]);
                  }
                },
                onTap: () => Get.find<SignalRService>().invoke('LeftClick'),
                onLongPress: () => Get.find<SignalRService>().invoke('RightClick'),
                child: Container(
                  color: Colors.transparent, // Catches touches
                  child: const Center(
                    child: Text(
                      'Touchpad Active\n(Tap: Left Click, Long Press: Right Click)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true, // Allows the bottom sheet to take up 80% of screen height
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 300),
      exitBottomSheetDuration: const Duration(milliseconds: 300),
    );
  }
}
