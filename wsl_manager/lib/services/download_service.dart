import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class DownloadException implements Exception {
  final String message;
  const DownloadException(this.message);
  @override
  String toString() => 'DownloadException: $message';
}

class DownloadService {
  static DownloadService? _instance;
  static DownloadService get instance => _instance ??= DownloadService._();
  DownloadService._();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5),
  ));

  Future<bool> validateUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.scheme.startsWith('http')) return false;
      final response = await http.head(uri).timeout(const Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (_) {
      return false;
    }
  }

  Future<String> downloadToTemp(
    String url,
    void Function(double progress) onProgress,
  ) async {
    final uri = Uri.parse(url);
    final filename = uri.pathSegments.last.isNotEmpty
        ? uri.pathSegments.last
        : 'wsl_download.tar.gz';
    final tmpPath = '${Directory.systemTemp.path}\\$filename';

    try {
      await _dio.download(
        url,
        tmpPath,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress(received / total);
        },
      );
    } on DioException catch (e) {
      throw DownloadException('Téléchargement échoué: ${e.message}');
    }

    return tmpPath;
  }
}
