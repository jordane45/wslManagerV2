import 'dart:io';

class WindowsNotificationService {
  static WindowsNotificationService? _instance;
  static WindowsNotificationService get instance =>
      _instance ??= WindowsNotificationService._();
  WindowsNotificationService._();

  Future<void> showToast({
    required String title,
    required String message,
  }) async {
    if (!Platform.isWindows) return;

    final script = '''
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
\$template = [Windows.UI.Notifications.ToastTemplateType]::ToastText02
\$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(\$template)
\$textNodes = \$xml.GetElementsByTagName("text")
\$textNodes.Item(0).AppendChild(\$xml.CreateTextNode(@'
${_escapeHereString(title)}
'@)) | Out-Null
\$textNodes.Item(1).AppendChild(\$xml.CreateTextNode(@'
${_escapeHereString(message)}
'@)) | Out-Null
\$toast = [Windows.UI.Notifications.ToastNotification]::new(\$xml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("WSL Manager").Show(\$toast)
''';

    final result = await Process.run(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
      runInShell: true,
    );
    if (result.exitCode != 0) {
      final stderr = result.stderr;
      final stdout = result.stdout;
      throw WindowsNotificationException(
        (stderr is String && stderr.trim().isNotEmpty
                ? stderr
                : stdout is String
                    ? stdout
                    : '')
            .trim(),
      );
    }
  }

  String _escapeHereString(String value) {
    return value.replaceAll("'@", "'`@");
  }
}

class WindowsNotificationException implements Exception {
  final String message;

  const WindowsNotificationException(this.message);

  @override
  String toString() {
    return message.isEmpty
        ? 'La notification Windows a échoué'
        : 'La notification Windows a échoué : $message';
  }
}
