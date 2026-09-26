# Document Vault — Rebuild Notes

The Document Vault (`lib/screens/documents/vault_tab.dart`) has been rebuilt.
It now supports, end to end:

## Add
- Tap **+** → choose **Photo** (jpg/jpeg/png) or **PDF** explicitly, instead
  of one generic file button.
- Upload goes to Firebase Storage; if Storage is unreachable it automatically
  falls back to storing the file inline (base64) so the document is never
  lost — same safety net as before, kept intact.

## View
- **Images** now open in a dedicated full-screen viewer with pinch-to-zoom
  (`InteractiveViewer`), instead of a small popup dialog.
- **PDFs** open in the existing Syncfusion in-app viewer, with a clear error
  screen + "Open Directly Instead" button if rendering fails (e.g. blocked by
  browser CORS on web).

## Copy
- New: each document's **⋮** menu has a **Copy** action.
  - On **mobile/desktop**, it saves a real file copy into the app's
    documents folder and shows a snackbar with an **Open** button.
  - On **web**, it opens the file in a new browser tab so you can use the
    browser's own Save/Download, since there's no app-writable filesystem to
    copy a file into on web.
  - Byte retrieval never depends on a raw HTTP fetch (which can be blocked by
    CORS) — it decodes the local base64 fallback directly, or reads the file
    back through the Firebase Storage SDK itself.

## Delete
- Fixed: deleting a document now also removes the file from Firebase
  Storage (`FirestoreService.deleteVaultDocument`), not just the Firestore
  record. Previously deleted documents left orphaned files behind in
  Storage.

## Files touched
- `lib/models/vault_model.dart` — added `isPdf` / `isImage` / `isDataUri` /
  `isNetworkUrl` / `fileExtension` helpers.
- `lib/services/firestore_service.dart` — `deleteVaultDocument` now also
  deletes the Storage object.
- `lib/screens/documents/vault_tab.dart` — full rewrite (Add sheet, Copy
  action, full-screen image viewer, error states, popup menu).

## Still outside what I can do from here
No Flutter/Dart SDK or network access is available in this environment, so I
could not run `flutter pub get` / `flutter analyze` / build the app to
compile-check this. Please run those yourself before shipping. No new
packages were added — everything above uses dependencies already in your
`pubspec.yaml` (`file_picker`, `firebase_storage`, `path_provider`,
`open_file`, `url_launcher`, `syncfusion_flutter_pdfviewer`).

Also, per the existing `DEBUG_REPORT.md`, if uploads/downloads still hang on
web specifically, double check:
1. `firestore.rules` / `storage.rules` are deployed
   (`firebase deploy --only firestore:rules,storage`)
2. `storage-cors.json` is applied to your Storage bucket
   (`gsutil cors set storage-cors.json gs://docseva-67315.firebasestorage.app`)
