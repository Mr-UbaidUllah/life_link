import 'package:url_launcher/url_launcher.dart';

/// Strips everything except digits and a leading '+' from a user-entered phone
/// number. Numbers in this app are often typed with spaces/dashes (the request
/// form even hints "+92 300 1234567"); without this the spaces get
/// percent-encoded into the tel: URI and many dialers show/dial a garbled
/// number while canLaunchUrl still reports success.
String sanitizePhone(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
  // Keep only a single leading '+'.
  if (cleaned.startsWith('+')) {
    return '+${cleaned.substring(1).replaceAll('+', '')}';
  }
  return cleaned.replaceAll('+', '');
}

/// Opens the phone dialer for [rawPhone]. Returns false if the number is empty
/// after sanitizing or the dialer can't be launched, so callers can show
/// feedback instead of silently doing nothing.
Future<bool> launchDialer(String rawPhone) async {
  final number = sanitizePhone(rawPhone);
  if (number.isEmpty) return false;

  final uri = Uri(scheme: 'tel', path: number);
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri);
  }
  return false;
}
