import 'package:get/get.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'dart:developer';

class SignalRService extends GetxService {
  HubConnection? _hubConnection;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Future<void> connect(String ip, String pin) async {
    if (_hubConnection != null) {
      await _hubConnection!.stop();
    }

    final url = "http://$ip:5001/airpadhub?pin=$pin";
    
    _hubConnection = HubConnectionBuilder()
        .withUrl(url)
        .withAutomaticReconnect()
        .build();

    _hubConnection!.onclose(({error}) {
      log("Connection Closed: $error");
    });

    await _hubConnection!.start();
    log("SignalR Connected to $ip");
  }

  Future<void> stop() async {
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
