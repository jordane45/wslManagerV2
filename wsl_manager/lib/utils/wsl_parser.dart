import 'dart:convert';
import '../models/wsl_instance.dart';

class WslParser {
  static List<WslInstance> parseVerboseList(String rawOutput) {
    final lines = rawOutput
        .split('\n')
        .map((l) => l.replaceAll('\r', ''))
        .where((l) => l.trim().isNotEmpty)
        .toList();

    final instances = <WslInstance>[];
    for (final line in lines) {
      // Skip header line
      if (line.trimLeft().startsWith('NAME')) continue;

      final isDefault = line.startsWith('*');
      final clean = line.replaceFirst('*', ' ');
      final parts = clean.trim().split(RegExp(r'\s{2,}'));
      if (parts.length < 3) continue;

      final name = parts[0].trim();
      final stateStr = parts[1].trim().toLowerCase();
      final versionStr = parts[2].trim();

      if (name.isEmpty) continue;

      final state = switch (stateStr) {
        'running' => WslInstanceState.running,
        'installing' => WslInstanceState.installing,
        _ => WslInstanceState.stopped,
      };

      final version = versionStr == '1' ? WslVersion.wsl1 : WslVersion.wsl2;

      instances.add(WslInstance(
        name: name,
        state: state,
        version: version,
        isDefault: isDefault,
      ));
    }
    return instances;
  }

  // Decode UTF-16 LE bytes (WSL output on Windows), stripping null bytes
  static String decodeWslOutput(List<int> bytes) {
    // Try UTF-16 LE with BOM detection
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return const Utf16Codec(littleEndian: true)
          .decode(bytes.sublist(2).where((b) => b != 0).toList());
    }
    // Fallback: strip null bytes and decode as UTF-8
    final cleaned = bytes.where((b) => b != 0).toList();
    return utf8.decode(cleaned, allowMalformed: true);
  }
}

class Utf16Codec extends Codec<String, List<int>> {
  final bool littleEndian;
  const Utf16Codec({this.littleEndian = true});

  @override
  Converter<List<int>, String> get decoder => _Utf16Decoder(littleEndian);

  @override
  Converter<String, List<int>> get encoder => throw UnimplementedError();
}

class _Utf16Decoder extends Converter<List<int>, String> {
  final bool littleEndian;
  const _Utf16Decoder(this.littleEndian);

  @override
  String convert(List<int> input) {
    final codeUnits = <int>[];
    for (int i = 0; i + 1 < input.length; i += 2) {
      final lo = input[i];
      final hi = input[i + 1];
      codeUnits.add(littleEndian ? lo | (hi << 8) : (lo << 8) | hi);
    }
    return String.fromCharCodes(codeUnits);
  }
}
