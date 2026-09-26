// ignore_for_file: deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

/// Opens raw [bytes] in a new browser tab via a `blob:` object URL.
///
/// This is used instead of `url_launcher` on a `data:` URI because Chrome
/// (and other Chromium browsers) silently blocks *script-initiated*
/// top-level navigation to `data:` URLs as an anti-phishing measure — the
/// tab opens but stays blank ("Untitled"). `blob:` URLs created from an
/// in-page `Blob` are not subject to that restriction, so the browser's
/// native PDF/image viewer opens the content normally, and the user can use
/// the browser's own Save/Download or right-click options on it.
void openBytesInBrowser(String mimeType, Uint8List bytes) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // Give the new tab time to load the blob before revoking the URL, so we
  // don't leak the object URL forever but also don't yank it out from
  // under the tab that just opened it.
  Future.delayed(const Duration(minutes: 5), () => html.Url.revokeObjectUrl(url));
}
