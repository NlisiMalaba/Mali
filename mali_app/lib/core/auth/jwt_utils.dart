import 'dart:convert';

/// Reads the JWT subject claim without verifying the signature.
String? readJwtSubject(String accessToken) {
  final parts = accessToken.split('.');
  if (parts.length != 3) {
    return null;
  }

  try {
    final normalized = base64Url.normalize(parts[1]);
    final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
    if (payload is! Map<String, dynamic>) {
      return null;
    }
    final subject = payload['sub'];
    if (subject is! String || subject.isEmpty) {
      return null;
    }
    return subject;
  } catch (_) {
    return null;
  }
}
