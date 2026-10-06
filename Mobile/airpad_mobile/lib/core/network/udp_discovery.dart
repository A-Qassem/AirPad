import 'dart:convert';
import 'dart:developer';
import 'package:udp/udp.dart';

class ServerInfo {
  final String ip;
  final String name;
  ServerInfo(this.ip, this.name);
}

class UdpDiscovery {
  static const int port = 5000;
  static const String discoverMessage = "AirPad_Discover";

  static Future<ServerInfo?> discoverServer() async {
    UDP? sender;
    try {
      sender = await UDP.bind(Endpoint.any());
      
      await sender.send(
        utf8.encode(discoverMessage),
        Endpoint.broadcast(port: Port(port)),
      );

      ServerInfo? serverInfo;
      
      await for (final datagram in sender.asStream(timeout: const Duration(seconds: 2))) {
        if (datagram != null) {
          final message = utf8.decode(datagram.data);
          if (message.startsWith("AirPad_Server:")) {
            final data = message.substring("AirPad_Server:".length).trim();
            final parts = data.split('|');
            if (parts.isNotEmpty) {
              final ip = parts[0];
              final name = parts.length > 1 ? parts[1] : 'Unknown PC';
              serverInfo = ServerInfo(ip, name);
              break;
            }
          }
        }
      }
      
      return serverInfo;
    } catch (e) {
      log('Error discovering server: $e');
      return null;
    } finally {
      sender?.close();
    }
  }
}
