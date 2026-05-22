import 'dart:io';

class NetworkUtils {
  static Future<List<String>> getLocalIPv4Addresses() async {
    final List<String> addresses = <String>[];
    final List<NetworkInterface> interfaces = await NetworkInterface.list(
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );

    for (final NetworkInterface interface in interfaces) {
      for (final InternetAddress address in interface.addresses) {
        if (!address.isLoopback) {
          addresses.add(address.address);
        }
      }
    }

    return addresses;
  }
}
