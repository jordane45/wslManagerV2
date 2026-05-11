class WslPort {
  final String protocol;
  final String address;
  final int port;

  const WslPort({
    required this.protocol,
    required this.address,
    required this.port,
  });

  String get endpoint => '$address:$port';
}
