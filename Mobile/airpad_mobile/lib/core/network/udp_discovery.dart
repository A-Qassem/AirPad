import 'dart:convert';
import 'dart:developer';
import 'package:udp/udp.dart';

class UdpDiscovery {
  static const int port = 5000;
  static const String discoverMessage = "AirPad_Discover";

  static Future<String?> discoverServer() async {
    UDP? sender;
    try {
      sender = await UDP.bind(Endpoint.any());
      
      await sender.send(
        utf8.encode(discoverMessage),
        Endpoint.broadcast(port: Port(port)),
      );

      String? serverIp;
      
      await for (final datagram in sender.asStream(timeout: const Duration(seconds: 2))) {
        if (datagram != null) {
          final message = utf8.decode(datagram.data);
          if (message.startsWith("AirPad_Server:")) {
            serverIp = message.substring("AirPad_Server:".length).trim();
            break;
          }
        }
      }
      
      return serverIp;
    } catch (e) {
      log('Error discovering server: $e');
      return null;
    } finally {
      sender?.close();
    }
  }
}
