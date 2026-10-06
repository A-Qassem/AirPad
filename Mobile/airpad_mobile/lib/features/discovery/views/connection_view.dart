import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/connection_controller.dart';

class ConnectionView extends StatelessWidget {
  const ConnectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ConnectionController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Connect to AirPad"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Obx(() {
            if (controller.isSearching.value) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Searching for AirPad Server..."),
                ],
              );
            } else if (controller.errorMessage.value.isNotEmpty) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.startDiscovery,
                    child: const Text("Retry"),
                  ),
                ],
              );
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  Text("Found Server: ${controller.serverIp.value}"),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.pinController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "PIN",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.isConnecting.value 
                        ? null 
                        : controller.connectToServer,
                    child: controller.isConnecting.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Connect"),
                  ),
                ],
              );
            }
          }),
        ),
      ),
    );
  }
}
