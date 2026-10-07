import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/udp_discovery.dart';
import '../../../core/network/signalr_service.dart';
import '../../remote/views/remote_view.dart';

class ConnectionController extends GetxController {
  var isSearching = true.obs;
  var serverIp = ''.obs;
  var serverName = ''.obs;
  var isConnecting = false.obs;
  var errorMessage = ''.obs;

  final pinController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _checkSavedConnection();
  }

  Future<void> _checkSavedConnection() async {
    isSearching.value = true;
    errorMessage.value = '';
    
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('saved_ip');
    final savedPin = prefs.getString('saved_pin');
    
    if (savedIp != null && savedPin != null) {
      serverIp.value = savedIp;
      pinController.text = savedPin;
      
      try {
        final signalRService = Get.put(SignalRService());
        await signalRService.connect(savedIp, savedPin);
        Get.offAll(() => const RemoteView());
        return;
      } catch (e) {
        // If auto-connect fails, clear saved credentials and fallback to discovery
        await prefs.remove('saved_ip');
        await prefs.remove('saved_pin');
      }
    }
    
    startDiscovery();
  }

  Future<void> startDiscovery() async {
    isSearching.value = true;
    errorMessage.value = '';
    serverIp.value = '';
    serverName.value = '';
    pinController.clear();
    
    final info = await UdpDiscovery.discoverServer();
    
    // Add a slight artificial delay so the UI doesn't flash too fast
    await Future.delayed(const Duration(seconds: 2));
    
    if (info != null) {
      serverIp.value = info.ip;
      serverName.value = info.name;
    } else {
      errorMessage.value = 'AirPad Server not found on this network.';
    }
    
    isSearching.value = false;
  }

  Future<void> connectToServer() async {
    isConnecting.value = true;
    errorMessage.value = '';
    
    try {
      final signalRService = Get.put(SignalRService());
      await signalRService.connect(serverIp.value, pinController.text);
      Get.offAll(() => const RemoteView());
    } catch (e) {
      errorMessage.value = 'Connection failed. Check PIN.';
    } finally {
      isConnecting.value = false;
    }
  }
}
