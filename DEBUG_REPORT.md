# DocSeva — Debug & Live-Data Verification Report

Reviewed every file under `lib/`, `android/app/`, and `pubspec.yaml` by hand
(23 Dart files, ~3,100 lines). No Flutter/Dart SDK was available in this
environment to run `flutter analyze` or build an APK, so everything below was
verified by static reading and, for the AI model names, by checking Google's
current Gemini API documentation live. Run `flutter analyze` and
`flutter pub get` yourself before your final submission — see "What you still
need to do" below.

## What was already correct (no mock/dummy data found)

This app does **not** use fake data anywhere. Confirmed real, live integrations:
- **Auth**: `firebase_auth` — real sign-up/sign-in against project `docseva-67315`.
- **Database**: `cloud_firestore` — real reads/writes to `Users`, `applications`,
  `vault`, `reminders`, `chat_history`.
- **File storage**: `firebase_storage` — real file uploads in `vault_tab.dart`
  (falls back to a Base64 data URI only if Storage itself is unreachable,
  which is a legitimate offline/error fallback, not mock data).
- **AI**: `google_generative_ai` — real calls to the Gemini API (see the one
  real bug below).
- **Government service reference data** (fees, eligibility, official portal
  URLs in `services_tab.dart`/`tracker_screen.dart`) is hardcoded, but that's
  the correct choice, not "dummy data" — see the design note below.

## Bugs found and fixed

1. **AI Assistant was silently dead** (`lib/services/ai_service.dart`).
   Every model name it tried — `gemini-1.5-flash-latest`, `gemini-2.0-flash`,
   `gemini-pro`, `gemini-1.5-flash` — has been shut down by Google (Gemini 1.5
   deprecated in early 2026; the 2.0 Flash family was shut down 1 Jun 2026).
   Every real request was failing and falling through to the canned offline
   text, which is indistinguishable from mock data to a user. **Fixed**: now
   tries `gemini-3.6-flash` → `gemini-3.5-flash-lite` → `gemini-3.1-flash-lite`
   → `gemini-2.5-flash`, all currently-GA models as of today. Also replaced
   the silent `catch (_) {}` with `debugPrint` logging per attempt, so a real
   failure (bad key, API not enabled, quota) shows up instead of looking
   identical to "model deprecated."
   ⚠️ **Gemini 2.5 is scheduled to shut down 16 Oct 2026** — re-check
   https://ai.google.dev/gemini-api/docs/models after that date.

2. **`DropdownButtonFormField` API inconsistency** (`reminders_screen.dart`
   used `value:`, while `vault_tab.dart` and `tracker_screen.dart` used
   `initialValue:`). `initialValue` is the current, non-deprecated parameter.
   Standardized all three to `initialValue` so behavior and lint results are
   consistent across the app.

3. **Unused dependency**: `image_picker` was declared in `pubspec.yaml` but
   never imported anywhere — the app only uses `file_picker` for the vault.
   Removed it to cut build time and one more native-permission surface. Run
   `flutter pub get` afterward to refresh `pubspec.lock`.

4. **No Firestore/Storage security rules shipped with the project.** This is
   the most likely reason "live data" might look broken when you actually
   run it: with no rules deployed, Firestore/Storage reject every read and
   write, and `firestore_service.dart`'s Streams then just emit empty lists —
   which looks exactly like "nothing is live" even though the Dart code and
   network calls are both correct. Added `firestore.rules`, `storage.rules`,
   and `firebase.json`, scoped to the collections/paths this app actually
   uses (`Users`, `applications`, `vault`, `reminders`, `chat_history`,
   `vault/{userId}/...` in Storage), owner-only. Deploy with:
   ```
   firebase use docseva-67315
   firebase deploy --only firestore:rules,storage
   ```

## What I deliberately did *not* build, and why

Your instructions ask for the app to pull real-time data "from the original
target website" for every operation, with no fallback. For the government
services this app covers (Aadhaar/UIDAI, PAN/NSDL, Passport Seva, Parivahan,
Voter ID/ECI, TN e-Sevai, EPFO, etc.), the only way to get a citizen's actual
live application status is to log in as that citizen on the official
government portal — which requires their real credentials and usually an
OTP/CAPTCHA. None of these departments publish a public API for this.
Automating that login on a user's behalf (scripted CAPTCHA-solving, storing
citizens' government credentials, scraping session-protected pages) isn't
something I can build — it would violate those portals' terms of service and
mishandle sensitive government PII, independent of good intent.

The version already in this project handles it the right way, and I kept
that design as-is rather than "fixing" it into a scraper: `tracker_screen.dart`
lets the user save their own application number locally (real Firestore
write), then deep-links them to the correct official portal
(`kOfficialGovServices`, real, current, verified URLs) to check status
themselves, with an explicit on-screen note that verification requires
CAPTCHA/OTP on the government site. That's already "real data" done
correctly — the fix above (rules) is what makes it actually persist live.

Likewise, `services_tab.dart`'s hardcoded list of 14 services (fees,
eligibility, docs required, official links) is real reference content
sourced from the actual departments, not placeholder text — hand-maintained
reference data like this is standard practice for a guide app and isn't
something that needs to be "live-fetched" to be genuine.

## Round 2 fixes (from live testing feedback)

5. **AI Assistant gave identical answers to different questions.** The
   offline fallback's keyword matcher checked the generic word "certificate"
   before more specific terms, so *any* certificate question (marriage,
   income, caste...) that didn't also contain "birth" fell through to the
   Birth Certificate answer. Reordered to check specific terms first. Also
   added an `isLive` flag threaded through `AIService` → `ChatMessage` → the
   chat UI, so every AI bubble now honestly shows "Live AI answer" vs.
   "Offline guide answer" — the two identical PAN answers you saw were both
   the offline fallback, which is now visible instead of silent.

6. **Several official links 404'd.** Verified live and fixed:
   - PAN now points to the Income Tax Dept.'s Instant e-PAN portal
     (`incometax.gov.in`) instead of a retired `tin-nsdl.com` URL — this is
     also fully online with no signature required, which is why it's now
     marked "Fully Online."
   - Patta/Chitta now points to `eservices.tn.gov.in/eservicesnew/index.html`
     (the site was restructured from the old `/eservicesweb/land/` path).
   - TN e-Sevai corrected to `https://www.tnesevai.tn.gov.in/Citizen/`.
   - Passport status tracking now links to the portal root
     (`passportindia.gov.in`) instead of a deep path — Passport Seva serves
     its tracker from rotating load-balanced subdomains
     (portal2/5/6.passportindia.gov.in), so any fixed deep link is
     inherently unreliable; click "Track Application Status" from the
     homepage instead.
   - Added an `onlineApplicable` + `onlineNote` field to every service,
     shown as a "Fully Online" / "Needs In-Person Visit" badge plus an
     explanation, per your request — e.g. Aadhaar new enrollment needs a
     Seva Kendra visit, but demographic updates are fully online.

7. **Vault upload dialog hangs indefinitely.** Added a 25s timeout around
   the Storage upload/download-URL calls so it can never spin forever.
   **The likely real root cause**: on Flutter Web, Firestore talks over
   websockets and doesn't need CORS, but Firebase Storage uploads are plain
   HTTP PUT/POST and *do* need a CORS policy on the bucket for your web
   origin — which is why Firestore-backed screens (Reminders, gov data)
   worked in your test but the Storage-backed Vault upload didn't. Added
   `storage-cors.json`; apply it with:
   ```
   gsutil cors set storage-cors.json gs://docseva-67315.firebasestorage.app
   ```
   Update the `origin` list in that file to match wherever you're actually
   serving the web build from (added `localhost:*` plus the default Firebase
   Hosting domains).

8. **PDF viewer showed a blank/garbled page.** `onDocumentLoadFailed` only
   did a `debugPrint` before — a failed load (e.g. the browser silently
   blocking a cross-origin fetch) left you staring at a blank viewer with no
   explanation. Converted `PDFViewerScreen` to a `StatefulWidget` that now
   shows a real error message and an "Open Directly Instead" button when
   rendering fails. Also wrapped the viewer in `SizedBox.expand` with a
   per-document `ValueKey`, since `SfPdfViewer` on Flutter Web can end up
   with near-zero layout constraints inside a `Column`/`Expanded` chain
   otherwise, which matches the "mostly blank with a text sliver at the
   edge" symptom.

9. **Reminders only showed the title.** The dialog already collected
   category/priority/notes but the list never displayed them, and nothing
   ever scheduled an actual notification despite `flutter_local_notifications`
   sitting unused in `pubspec.yaml` (and the Android manifest already
   requesting exact-alarm permissions for it). Built out
   `lib/services/notification_service.dart` and wired it into
   `main.dart`/`reminders_screen.dart`: adding a reminder now schedules a
   real on-device notification for 9:00 AM the day before the due date
   (Android/iOS only — `flutter_local_notifications` has no web
   implementation, so on web it shows an explicit "not supported on web"
   note instead of silently doing nothing). The list now shows category,
   priority, due date, exact notification time, and notes.

10. **Profile didn't collect/show much.** Registration only asked for
    name/email/phone/password. Added Date of Birth, Gender, and Address to
    `RegisterScreen`, `UserModel`, `AuthService.register()`, and the Profile
    edit dialog, and the Profile screen now displays all of them (falling
    back to "Not provided" only for fields genuinely never filled in,
    instead of for everything).

## What you still need to do (can't be done from inside this container)

- Run `flutter pub get`, then `flutter analyze` and `flutter run` — I could
  not install/run the Flutter SDK here to compile-check the project.
- Deploy `firestore.rules` / `storage.rules` (command above) — without this,
  every Firestore/Storage read and write will fail even though the code is
  correct.
- Apply `storage-cors.json` to the Storage bucket (command in "Round 2" above)
  — this is the most likely fix for the Vault upload hang specifically.
- In Google Cloud Console for project `docseva-67315`, confirm the
  **Generative Language API** is enabled and that the API key isn't
  restricted away from it — the AI Assistant reuses the Firebase web API key,
  which only works for Gemini if that API is explicitly turned on for the
  key.
- `android/local.properties` has your local machine's Windows SDK paths
  hardcoded (`C:\Users\kldha\...`) — this file is already gitignored and gets
  regenerated automatically the first time you open the project in Android
  Studio/VS Code on any machine, so no action needed unless the build tool
  complains, in which case just delete it and re-open the project.
