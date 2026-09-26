# Document Vault — Rebuild Notes

## Update: full Blue + Green + Teal redesign, per DocSeva design spec (no red anywhere)

This implements the detailed design brief (blue/green/teal palette, exact
hex values, "no red anywhere," dashboard restructuring) — using the LEXORA
screenshot only as a layout/spacing reference, not for its content, name,
or colors.

**Theme (`lib/core/theme/app_theme.dart`)** — rewritten with the exact
palette from the spec: Primary Blue `#1565C0`, Dark Blue `#0D47A1`,
Secondary Blue `#1976D2`, Light Blue `#E3F2FD`, Primary Green `#2E7D32`,
Secondary Green `#43A047`, Light Green `#E8F5E9`, Teal `#00897B`, Light Teal
`#E0F2F1`, Background `#F4F8FC`, Primary Text `#12304A`, Secondary Text
`#607D8B`, Border `#D9E3EC`. Card corners are 18px with a subtle border +
soft shadow (spec: "soft shadows, clean borders, 16–20px radius"). Old
names (`primaryColor`, `secondaryColor`, etc.) are kept as aliases pointing
at the new palette, so every screen repaints from this one file without
being individually rewritten.

**No red, anywhere** — added `AppTheme.destructiveColor` (a neutral dark
gray, `#546575`) and moved every Delete/Logout button, icon, and
confirmation dialog in the app onto it: Doc Vault, Application Tracker,
Profile logout, and the debug log/reminders priority indicators. Searched
the whole `lib/` tree for `Colors.red` afterward — none left. Where the
spec says "use blue or green for alerts instead," generic error/problem
icons (e.g. "vault could not load," "PDF could not render") now use
`AppTheme.errorColor`, repointed to Dark Blue.

**Home dashboard** — subtitle updated to "Manage your government documents
easily" (from the spec). The two highlight cards are now **Applications**
(green — matches the spec's Track→Green) and **Doc Vault** (teal — spec's
Documents→Teal). Quick Actions is now a 2×2 grid of four real destinations,
colored per the spec's exact scheme: **Services** (blue) → government
service guides, **Track Application** (green) → tracker, **My Documents**
(teal) → vault, **Reminders** (dark blue). AI Assistant stays reachable
from the header icon. (The spec's 4th quick action was labeled "Guides" —
this app doesn't have a separate guides screen, since Services already *is*
the step-by-step guide with required documents + official website links,
so Reminders fills that 4th slot instead, keeping the same color.)

**Doc Vault** — file-type icons are now Teal for PDFs / Green for
Photos, and each entry's row now shows the upload date alongside category
and file type (the spec calls for name, type, and date on every entry).
View/Copy/Delete are unchanged functionally from the last round.

**Services tab** — added a blue highlight header card ("N Services
Available"). "Fully Online" / "Needs In-Person Visit" badges are unchanged
(green / amber — amber isn't red, so it was left as-is; nothing there was
red to begin with).

**Profile tab** — navy→blue header card carries over from the last round,
recolored automatically by the theme change; logout button is now the
neutral gray destructive color instead of red.

**Bottom navigation** — relabeled "Vault" → "Documents" to match the
spec's naming (Home / Services / Documents / Profile); active tab now
shows in blue.

### What this round did NOT touch
Login/Registration, AI Assistant chat, Reminders list, Application Tracker
detail layout, and Service Detail screen keep their existing layouts — they
already inherit the new blue/green/teal colors automatically through the
shared theme (including their delete buttons, now gray instead of red), but
their structure wasn't rebuilt into the highlight-card dashboard style.
Say which one to target next if you want that treatment there too.

All existing functionality — auth, service guides, official website links,
application tracking, document vault (upload/view/copy/delete for both
images and PDFs), reminders — was left as-is; only colors, card
chrome, and the Home/Services/Profile layouts changed.



- **Color swap**: `secondaryColor` changed from gold (`0xFFD9A441`) to a
  forest green (`0xFF2E7D4F`), with matching tonal ramps. Navy stayed the
  same. Since it's all driven from `AppTheme.*`, this alone re-colors every
  screen — Services badges, Vault icons, Profile accents, the bottom nav's
  active-tab pill — back to green/navy.
- **Services tab**: added a navy highlight header card ("N Services
  Available"), matching the dashboard's highlight-card style; bumped list
  card corners to 16px to match.
- **Doc Vault tab**: bumped list card corners to 16px for the same
  consistent rounded look.
- **Profile tab**: rebuilt the top of the screen as a navy header card
  (avatar, name, email, Edit Profile button) plus the info fields grouped
  into a single white rounded card below — the same card-first, colored-
  header language as the Home dashboard.

Screens not touched this round (Reminders, Tracker, Service Detail, AI
Assistant, Splash/Login): they already inherit the new navy/green palette
automatically through the shared theme, but their layouts weren't
restructured into the highlight-card style. Say the word if you want any of
those reworked the same way.

## Update: navy + gold theme, dashboard restyle (superseded by green, above)


Applied the visual style from the reference dashboard screenshot (deep navy
+ warm gold, rounded cards, highlight-card row, "Quick Actions" grid):

- **`lib/core/theme/app_theme.dart`** — `primaryColor` is now a deep navy
  (`0xFF1E2A4A`, was blue) and `secondaryColor` is now a warm gold
  (`0xFFD9A441`, was green), with matching tonal ramps
  (`primaryLightest/Light/Dark`, `secondaryLightest/Light/Dark`). Because
  every screen in this app already pulls its colors from `AppTheme.*`
  instead of hardcoding blue/green, this one change reskins the whole app —
  app bars, buttons, icons, badges, the bottom nav's selected-tab pill
  (now gold, matching the reference's active tab) — not just the Home tab.
- **`lib/screens/home/home_tab.dart`** — rebuilt to match the reference's
  layout: a "My Dashboard" header with a profile-avatar shortcut, a two-card
  highlight row (gold **Applications in Progress** / navy **Doc Vault**
  files, both live-counted from Firestore), a **Quick Actions** row of three
  icon cards (Track Status, Reminders, AI Assistant), and the existing
  Recent Applications list underneath.

I kept your app's real tabs and features (Home/Services/Vault/Profile) and
its actual data (application counts, vault file counts) rather than copying
the reference screenshot's specific content (it's from an unrelated
lawyer-facing app with "Online/Offline" status and "Messages from
Citizens," which don't apply to DocSeva) — only the visual language (colors,
card shapes, layout rhythm) was carried over.

**Not done, since it'd mean rewriting dozens of files blind with no way to
compile-check here:** hand-tuning every individual screen's bespoke layout
choices to visually match every last detail of the reference (e.g. the
exact status-card treatment, spacing, or typography weight). If there's a
specific screen where the current look feels off, tell me which one and
I'll target it directly.


Testing surfaced two real bugs, both specific to the **base64 fallback path**
(i.e. when Firebase Storage upload fails/CORS isn't set up, so the file is
stored as a `data:...;base64,...` URI instead of a real Storage URL):

1. **View → "Open Directly Instead" button was missing** for these
   documents. It only appeared when a real Storage URL existed, so a failed
   in-app PDF render was a dead end with no way out except "Back / Close".
2. **Copy opened a blank tab.** Chrome silently blocks *script-initiated*
   top-level navigation to `data:` URLs (an anti-phishing protection) — the
   tab opens but never actually navigates, which is exactly the blank
   "Untitled" tab in your screenshot.

Both are fixed the same way: instead of navigating to the raw `data:` URI,
the file's bytes are now wrapped in a `blob:` object URL
(`lib/utils/browser_file_opener_web.dart`, loaded only on web via a
conditional import) before being opened in a new tab. Blob URLs aren't
subject to that Chrome restriction, so the browser's native PDF/image viewer
opens normally and you can use its own Save/Download or right-click options.
On mobile/desktop, "Open Directly Instead" now writes the bytes to a temp
file and opens it with the device's default PDF app via `open_file`.

New file: `lib/utils/browser_file_opener.dart` (+ `_stub.dart` / `_web.dart`)
— no new pubspec dependency, just `dart:html` behind a conditional import so
non-web builds still compile.

This doesn't change *why* the upload fell back to base64 in the first place
— that still points at Storage/CORS not being deployed for this environment
(see the checklist at the bottom of this file).


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
