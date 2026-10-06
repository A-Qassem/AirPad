import 'package:get/get.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'dart:developer';
import 'dart:async';
import 'dart:io';
import '../../features/discovery/views/connection_view.dart';
import '../../features/discovery/controllers/connection_controller.dart';

class SignalRService extends GetxService {
  HubConnection? _hubConnection;
  Timer? _heartbeatTimer;

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

    // Make the app detect server drops aggressively (5 seconds instead of 30)
    _hubConnection!.serverTimeoutInMilliseconds = 5000;
    _hubConnection!.keepAliveIntervalInMilliseconds = 2000;

    _hubConnection!.onclose(({error}) {
      log("Connection Closed: $error");
      _handleDisconnect();
    });

    await _hubConnection!.start();
    log("SignalR Connected to $ip");
    
    _startHeartbeat(ip);
  }

  void _startHeartbeat(String ip) {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        // Aggressive instant-check: try to establish a split-second TCP connection
        final socket = await Socket.connect(ip, 5001, timeout: const Duration(seconds: 1));
        socket.destroy();
      } catch (e) {
        log("Heartbeat failed (Server Offline): $e");
        _handleDisconnect();
      }
    });
  }

  void _handleDisconnect() {
    _heartbeatTimer?.cancel();
    if (Get.currentRoute != '/ConnectionView') {
      Get.delete<ConnectionController>(); // Force a fresh state
      Get.offAll(() => const ConnectionView());
    }
  }

  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    if (_hubConnection != null) {
      await _hubConnection!.stop();
      _hubConnection = null;
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
