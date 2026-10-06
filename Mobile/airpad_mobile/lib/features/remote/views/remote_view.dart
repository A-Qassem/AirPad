import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../core/network/signalr_service.dart';

class RemoteView extends StatelessWidget {
  const RemoteView({super.key});

  @override
  Widget build(BuildContext context) {
    final signalRService = Get.find<SignalRService>();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("AirPad Remote", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Top Utilities Row with Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabeledButton(Icons.bedtime, 'Sleep', Colors.indigoAccent, () => signalRService.invoke('Sleep')),
                _buildLabeledButton(Icons.lock, 'Lock', Colors.redAccent, () => signalRService.invoke('LockScreen')),
                _buildLabeledButton(Icons.volume_off, 'Mute', Colors.orangeAccent, () => signalRService.invoke('VolumeMute')),
                _buildLabeledButton(Icons.screenshot, 'Screenshot', Colors.greenAccent, () => signalRService.invoke('TakeScreenshot')),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // Scrollers and Media Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InfiniteWheelScroller(
                  label: "Scroll",
                  onUp: () => signalRService.invoke('Scroll', args: [120]),
                  onDown: () => signalRService.invoke('Scroll', args: [-120]),
                ),
                
                // Center Media Pad
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLabeledMediaButton(Icons.language, 'Language', Colors.cyanAccent, () => signalRService.invoke('LanguageSwap')),
                        const SizedBox(width: 16),
                        _buildLabeledMediaButton(Icons.flip_to_front, 'Alt Tab', Colors.pinkAccent, () => signalRService.invoke('AppSwitcher')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLabeledMediaButton(Icons.skip_previous, 'Prev', Colors.white24, () => signalRService.invoke('MediaPrevTrack')),
                        const SizedBox(width: 16),
                        _buildLabeledMediaButton(Icons.play_arrow, 'Play', Colors.blueAccent, () => signalRService.invoke('MediaPlayPause')),
                        const SizedBox(width: 16),
                        _buildLabeledMediaButton(Icons.skip_next, 'Next', Colors.white24, () => signalRService.invoke('MediaNextTrack')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RepeatableLabeledButton(
                          icon: Icons.brightness_low,
                          label: 'Dim',
                          color: Colors.orangeAccent,
                          onTap: () => signalRService.invoke('BrightnessDown'),
                        ),
                        const SizedBox(width: 16),
                        RepeatableLabeledButton(
                          icon: Icons.brightness_high,
                          label: 'Bright',
                          color: Colors.orangeAccent,
                          onTap: () => signalRService.invoke('BrightnessUp'),
                        ),
                      ],
                    ),
                  ],
                ),
                
                InfiniteWheelScroller(
                  label: "Volume",
                  onUp: () => signalRService.invoke('VolumeUp'),
                  onDown: () => signalRService.invoke('VolumeDown'),
                ),
              ],
            ),
          ),
          
          const Spacer(),

          // Touchpad Area
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white12),
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final dx = details.delta.dx.toInt();
                  final dy = details.delta.dy.toInt();
                  if (dx != 0 || dy != 0) {
                     signalRService.invoke('MoveMouse', args: [dx, dy]);
                  }
                },
                onTap: () => signalRService.invoke('LeftClick'),
                onLongPress: () => signalRService.invoke('RightClick'),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.touch_app, color: Colors.blueAccent, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Touchpad Active',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap = Left Click | Hold = Right Click',
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)
              ]
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildLabeledMediaButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class RepeatableLabeledButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const RepeatableLabeledButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<RepeatableLabeledButton> createState() => _RepeatableLabeledButtonState();
}

class _RepeatableLabeledButtonState extends State<RepeatableLabeledButton> {
  Timer? _timer;
  bool _isRepeating = false;

  void _startTimer() {
    _isRepeating = false;
    _timer = Timer(const Duration(milliseconds: 300), () {
      _isRepeating = true;
      _timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
        widget.onTap();
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startTimer(),
      onTapUp: (_) {
        _stopTimer();
        if (!_isRepeating) {
          widget.onTap();
        }
      },
      onTapCancel: () => _stopTimer(),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withOpacity(0.3)),
            ),
            child: Icon(widget.icon, color: widget.color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w500),
          ),
          Text(
            '(Hold)',
            style: TextStyle(color: Colors.orangeAccent.withOpacity(0.6), fontSize: 8, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class InfiniteWheelScroller extends StatefulWidget {
  final String label;
  final VoidCallback onUp;
  final VoidCallback onDown;

  const InfiniteWheelScroller({
    super.key,
    required this.label,
    required this.onUp,
    required this.onDown,
  });

  @override
  State<InfiniteWheelScroller> createState() => _InfiniteWheelScrollerState();
}

class _InfiniteWheelScrollerState extends State<InfiniteWheelScroller> {
  int _lastIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.label, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        Container(
          width: 60,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
            ]
          ),
          child: ListWheelScrollView.useDelegate(
            itemExtent: 24, // Space between lines
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              if (index > _lastIndex) {
                widget.onDown(); // Rolling down
              } else if (index < _lastIndex) {
                widget.onUp(); // Rolling up
              }
              _lastIndex = index;
            },
            childDelegate: ListWheelChildLoopingListDelegate(
              children: List.generate(20, (index) {
                // Creates the tick marks on the wheel
                return Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
