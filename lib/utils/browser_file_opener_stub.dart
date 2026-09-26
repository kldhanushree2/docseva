import 'dart:typed_data';

/// Non-web platforms never call this (the call sites are guarded by
/// `kIsWeb`), so this stub only exists so the file compiles on
/// Android/iOS/desktop, where `dart:html` isn't available.
void openBytesInBrowser(String mimeType, Uint8List bytes) {
  throw UnsupportedError('openBytesInBrowser is only supported on web.');
}
