import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../core/network/signalr_service.dart';

class RemoteView extends StatefulWidget {
  const RemoteView({super.key});

  @override
  State<RemoteView> createState() => _RemoteViewState();
}

class _RemoteViewState extends State<RemoteView> {
  final FocusNode _keyboardFocusNode = FocusNode();
  final TextEditingController _keyboardController = TextEditingController();
  String _lastText = "";

  int? _serverVolume;
  int? _serverBrightness;
  String _mediaTitle = "Unknown Title";
  String _mediaArtist = "Unknown Artist";
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode.addListener(() {
      if (!_keyboardFocusNode.hasFocus) {
        _keyboardController.clear();
        _lastText = "";
      }
    });

    final signalRService = Get.find<SignalRService>();
    signalRService.on('UpdateSystemState', _onSystemStateUpdate);
  }

  void _onSystemStateUpdate(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      final state = args.first as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _serverVolume = state['volume'] as int? ?? _serverVolume;
          _serverBrightness = state['brightness'] as int? ?? _serverBrightness;
          _mediaTitle = state['mediaTitle'] as String? ?? _mediaTitle;
          _mediaArtist = state['mediaArtist'] as String? ?? _mediaArtist;
          _isPlaying = state['isPlaying'] as bool? ?? _isPlaying;
        });
      }
    }
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _keyboardController.dispose();

    final signalRService = Get.find<SignalRService>();
    signalRService.off('UpdateSystemState', handler: _onSystemStateUpdate);

    super.dispose();
  }

  void _onTextChanged(String text) {
    final signalRService = Get.find<SignalRService>();
    if (text.length > _lastText.length) {
      String added = text.substring(_lastText.length);
      signalRService.invoke('TypeText', args: [added]);
    } else if (text.length < _lastText.length) {
      int backspaces = _lastText.length - text.length;
      for (int i = 0; i < backspaces; i++) {
        signalRService.invoke('PressKey', args: [0x08]); // Backspace
      }
    }
    _lastText = text;
  }

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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      InfiniteWheelScroller(
                        label: "Scroll",
                        onUp: () => signalRService.invoke('Scroll', args: [120]),
                        onDown: () => signalRService.invoke('Scroll', args: [-120]),
                      ),
                      InfiniteWheelScroller(
                        label: "Brightness",
                        serverValue: _serverBrightness,
                        onUp: () => signalRService.invoke('BrightnessUp'),
                        onDown: () => signalRService.invoke('BrightnessDown'),
                      ),
                      InfiniteWheelScroller(
                        label: "Volume",
                        serverValue: _serverVolume,
                        onUp: () => signalRService.invoke('VolumeUp'),
                        onDown: () => signalRService.invoke('VolumeDown'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Misc Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLabeledMediaButton(Icons.bluetooth, 'Bluetooth', Colors.blue, () => signalRService.invoke('ToggleBluetooth')),
                    const SizedBox(width: 32),
                    _buildLabeledMediaButton(Icons.flip_to_front, 'Alt Tab', Colors.pinkAccent, () => signalRService.invoke('AppSwitcher')),
                  ],
                ),
                const SizedBox(height: 24),

                // Media Player Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.music_note, color: Colors.blueAccent, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_mediaTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(_mediaArtist, style: const TextStyle(color: Colors.white54, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLabeledMediaButton(Icons.skip_previous, 'Prev', Colors.white54, () => signalRService.invoke('MediaPrevTrack')),
                          _buildLabeledMediaButton(_isPlaying ? Icons.pause : Icons.play_arrow, _isPlaying ? 'Pause' : 'Play', Colors.white, () => signalRService.invoke('MediaPlayPause')),
                          _buildLabeledMediaButton(Icons.skip_next, 'Next', Colors.white54, () => signalRService.invoke('MediaNextTrack')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Padding to clear the collapsed touchpad
              ],
            ),
          ),

          // Expandable Touchpad (Overlays on top of the UI)
          Align(
            alignment: Alignment.bottomCenter,
            child: ExpandableTouchpad(
              onToggleKeyboard: () {
                if (_keyboardFocusNode.hasFocus) {
                  _keyboardFocusNode.unfocus();
                } else {
                  _keyboardFocusNode.requestFocus();
                }
              },
            ),
          ),

          // Hidden TextField for native keyboard
          Positioned(
            top: -100,
            child: SizedBox(
              width: 10,
              height: 10,
              child: TextField(
                focusNode: _keyboardFocusNode,
                controller: _keyboardController,
                onChanged: _onTextChanged,
                autocorrect: false,
                enableSuggestions: false,
              ),
            ),
          ),

          // Shortcut Toolbar (shows only when keyboard is up)
          if (MediaQuery.of(context).viewInsets.bottom > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildShortcutToolbar(),
            ),
        ],
      ),
    );
  }

  Widget _buildShortcutToolbar() {
    final signalRService = Get.find<SignalRService>();
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.start,
        children: [
          _shortcutBtn('Esc', () => signalRService.invoke('PressKey', args: [0x1B])),
          _shortcutBtn('Tab', () => signalRService.invoke('PressKey', args: [0x09])),
          _shortcutBtn('Ctrl+C', () => signalRService.invoke('SendShortcut', args: [[0x11, 0x43]])),
          _shortcutBtn('Ctrl+V', () => signalRService.invoke('SendShortcut', args: [[0x11, 0x56]])),
          _shortcutBtn('Ctrl+X', () => signalRService.invoke('SendShortcut', args: [[0x11, 0x58]])),
          _shortcutBtn('Ctrl+Z', () => signalRService.invoke('SendShortcut', args: [[0x11, 0x5A]])),
          _shortcutBtn('Ctrl+A', () => signalRService.invoke('SendShortcut', args: [[0x11, 0x41]])),
          _shortcutBtn('Win', () => signalRService.invoke('PressKey', args: [0x5B])),
          _shortcutBtn('Win+V', () => signalRService.invoke('SendShortcut', args: [[0x5B, 0x56]])),
          _shortcutBtn('Enter', () => signalRService.invoke('PressKey', args: [0x0D])),
        ],
      ),
    );
  }

  Widget _shortcutBtn(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
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
  final int? serverValue;

  const InfiniteWheelScroller({
    super.key,
    required this.label,
    required this.onUp,
    required this.onDown,
    this.serverValue,
  });

  @override
  State<InfiniteWheelScroller> createState() => _InfiniteWheelScrollerState();
}

class _InfiniteWheelScrollerState extends State<InfiniteWheelScroller> {
  int _lastIndex = 0;
  int _localValue = 50;

  @override
  void initState() {
    super.initState();
    if (widget.serverValue != null) {
      _localValue = widget.serverValue!;
    }
  }

  @override
  void didUpdateWidget(covariant InfiniteWheelScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.serverValue != null && widget.serverValue != oldWidget.serverValue) {
      _localValue = widget.serverValue!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(widget.label, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)),
        if (widget.serverValue != null) ...[
          const SizedBox(height: 8),
          Text('$_localValue', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 8),
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
                if (widget.serverValue != null) {
                  setState(() { _localValue = (_localValue - 2).clamp(0, 100); });
                }
              } else if (index < _lastIndex) {
                widget.onUp(); // Rolling up
                if (widget.serverValue != null) {
                  setState(() { _localValue = (_localValue + 2).clamp(0, 100); });
                }
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

class ExpandableTouchpad extends StatefulWidget {
  final VoidCallback onToggleKeyboard;

  const ExpandableTouchpad({super.key, required this.onToggleKeyboard});

  @override
  State<ExpandableTouchpad> createState() => _ExpandableTouchpadState();
}

class _ExpandableTouchpadState extends State<ExpandableTouchpad> {
  bool _isOpen = false;
  double _sensitivity = 1.0;
  // Sub-pixel remainders now live in SignalRService so they survive
  // widget rebuilds and SignalR reconnects.
  late final SignalRService _signalRService;

  @override
  void initState() {
    super.initState();
    _signalRService = Get.find<SignalRService>();
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isOpen) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHintChip(Icons.touch_app, 'Tap', 'Left Click'),
                const SizedBox(width: 16),
                _buildHintChip(Icons.fingerprint, 'Hold', 'Right Click'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                const Icon(Icons.speed, color: Colors.white54, size: 18),
                const SizedBox(width: 8),
                const Text('Sensitivity', style: TextStyle(color: Colors.white54, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _sensitivity,
                    min: 0.2,
                    max: 3.0,
                    activeColor: Colors.blueAccent,
                    inactiveColor: Colors.white12,
                    onChanged: (val) {
                      setState(() {
                        _sensitivity = val;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
          height: _isOpen ? 300 : 64,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(_isOpen ? 30 : 32),
            border: Border.all(color: _isOpen ? Colors.blueAccent.withOpacity(0.5) : Colors.white12),
            boxShadow: _isOpen 
                ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 20)] 
                : [const BoxShadow(color: Colors.transparent, blurRadius: 0)],
          ),
          child: _isOpen
              ? Stack(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        double dxRaw = (details.delta.dx * _sensitivity) + _signalRService.remainderX;
                        double dyRaw = (details.delta.dy * _sensitivity) + _signalRService.remainderY;
                        
                        int dx = dxRaw.truncate();
                        int dy = dyRaw.truncate();
                        
                        _signalRService.remainderX = dxRaw - dx;
                        _signalRService.remainderY = dyRaw - dy;
                        
                        if (dx != 0 || dy != 0) {
                           _signalRService.moveMouse(dx, dy);
                        }
                      },
                      onTap: () => _signalRService.invoke('LeftClick'),
                      onLongPress: () => _signalRService.invoke('RightClick'),
                      child: Center(
                         child: Icon(Icons.touch_app, color: Colors.blueAccent.withOpacity(0.1), size: 100),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 32),
                        onPressed: () => setState(() => _isOpen = false),
                      )
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isOpen = true),
                        borderRadius: BorderRadius.circular(32),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mouse, color: Colors.blueAccent, size: 28),
                                SizedBox(width: 8),
                                Text('Touchpad', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 32, color: Colors.white12), // Divider
                    Expanded(
                      child: InkWell(
                        onTap: widget.onToggleKeyboard,
                        borderRadius: BorderRadius.circular(32),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.keyboard, color: Colors.blueAccent, size: 28),
                                SizedBox(width: 8),
                                Text('Keyboard', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildHintChip(IconData icon, String action, String result) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C), // Solid dark grey background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3C3C3C)), // Solid border
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 16),
          const SizedBox(width: 6),
          Text(
            '$action: ',
            style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            result,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
