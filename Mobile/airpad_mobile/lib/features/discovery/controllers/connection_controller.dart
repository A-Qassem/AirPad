import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../../../core/network/udp_discovery.dart';
import '../../remote/views/remote_view.dart';

class ConnectionController extends GetxController {
  var isSearching = true.obs;
  var serverIp = ''.obs;
  var isConnecting = false.obs;
  var errorMessage = ''.obs;

  final pinController = TextEditingController();
  HubConnection? hubConnection;

  @override
  void onInit() {
    super.onInit();
    startDiscovery();
  }

  Future<void> startDiscovery() async {
    isSearching.value = true;
    errorMessage.value = '';
    
    final ip = await UdpDiscovery.discoverServer();
    
    if (ip != null) {
      serverIp.value = ip;
    } else {
      errorMessage.value = 'AirPad Server not found on this network.';
    }
    
    isSearching.value = false;
  }

  Future<void> connectToServer() async {
    isConnecting.value = true;
    errorMessage.value = '';
    
    try {
      hubConnection = HubConnectionBuilder()
          .withUrl("http://${serverIp.value}:5000/airpadHub",
              options: HttpConnectionOptions(
                  accessTokenFactory: () async => pinController.text))
          .build();
          
      await hubConnection!.start();
      Get.offAll(() => const RemoteView());
    } catch (e) {
      errorMessage.value = 'Connection failed. Check PIN.';
    } finally {
      isConnecting.value = false;
    }
  }
}
