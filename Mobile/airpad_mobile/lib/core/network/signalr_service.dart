import 'package:get/get.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'dart:developer';
import 'dart:async';
import '../../features/discovery/views/connection_view.dart';
import '../../features/discovery/controllers/connection_controller.dart';

class SignalRService extends GetxService {
  HubConnection? _hubConnection;
  Timer? _heartbeatTimer;

  // Sub-pixel movement accumulators — kept here so they survive widget
  // rebuilds and reconnects.
  double remainderX = 0.0;
  double remainderY = 0.0;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Future<void> connect(String ip, String pin) async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
    }

    _heartbeatTimer?.cancel();

    final url = "http://$ip:5001/airpadhub?pin=$pin";

    _hubConnection = HubConnectionBuilder()
        .withUrl(url)
        .withAutomaticReconnect()
        .build();

    // The keepAlive ping timer fires on Dart's single event-loop isolate.
    // Pushing it far out ensures it never fires during active mouse use.
    // On local Wi-Fi a 30-second cadence is more than sufficient.
    _hubConnection!.keepAliveIntervalInMilliseconds = 30000;
    _hubConnection!.serverTimeoutInMilliseconds = 90000;

    _hubConnection!.onclose(({error}) {
      log("Connection Closed: $error");
      _handleDisconnect();
    });

    await _hubConnection!.start();
    log("SignalR Connected to $ip");
  }

  void _handleDisconnect() {
    _heartbeatTimer?.cancel();

    if (Get.currentRoute != '/ConnectionView') {
      Get.delete<ConnectionController>();
      Get.offAll(() => const ConnectionView());
    }
  }

  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    remainderX = 0.0;
    remainderY = 0.0;
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _hubConnection = null;
    }
  }

  /// Sends a mouse-move delta using fire-and-forget [send()].
  ///
  /// Advantages over the previous UDP approach:
  /// — No round-trip ACK → no added latency
  /// — Active TCP/WebSocket keeps the PC Wi-Fi adapter awake (no PSM freeze)
  /// — Works through any firewall/NAT — only port 5001 needed
  /// — No separate socket, no extra port, no PSM workarounds
  void moveMouse(int dx, int dy) {
    if (isConnected) {
      // send() queues to the WebSocket write buffer and returns immediately.
      // The Dart isolate is never blocked waiting for a server response.
      _hubConnection!.send('MoveMouse', args: [dx, dy]);
    }
  }

  Future<void> invoke(String methodName, {List<Object>? args}) async {
    if (isConnected) {
      try {
        await _hubConnection!.invoke(methodName, args: args);
      } catch (e) {
        log("Error invoking $methodName: $e");
      }
    } else {
      log("Cannot invoke $methodName, not connected.");
    }
  }
}
