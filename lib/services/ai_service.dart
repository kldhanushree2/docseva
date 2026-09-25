import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Wraps an AI Assistant reply together with whether it came from the live
/// Gemini API or the offline built-in knowledge base, so the UI can be
/// honest with the user about which one they're looking at.
class AIResponse {
  final String text;
  final bool isLive;
  const AIResponse(this.text, this.isLive);
}

class AIService {
  // Reuses the same Google Cloud API key as Firebase (see firebase_options.dart).
  // This ONLY works if the "Generative Language API" is explicitly enabled for
  // project docseva-67315 in Google Cloud Console, and the key isn't restricted
  // to just the Firebase APIs. If Gemini calls keep failing, check:
  // https://console.cloud.google.com/apis/library/generativelanguage.googleapis.com
  static const String _apiKey = "AIzaSyDtQ0Oy3VGM1hlXDazP9FcvvtfOQihK0dU";

  Future<AIResponse> askQuestion(String prompt) async {
    final query = prompt.toLowerCase();

    // 1. Try Gemini Generative AI API
    // NOTE: gemini-1.5-*, gemini-2.0-flash and gemini-pro are all shut down
    // (Gemini 1.5 deprecated early 2026; 2.0 Flash family shut down 1 Jun 2026).
    // Current GA models as of Sep 2026: gemini-3.6-flash / gemini-3.5-flash-lite
    // / gemini-3.1-flash-lite. gemini-2.5-flash is kept as a last-resort
    // fallback but is scheduled to shut down 16 Oct 2026 — re-check
    // https://ai.google.dev/gemini-api/docs/models before that date.
    final modelsToTry = [
      'gemini-3.6-flash',
      'gemini-3.5-flash-lite',
      'gemini-3.1-flash-lite',
      'gemini-2.5-flash',
    ];

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: _apiKey,
        );
        final content = [
          Content.text('You are DocSeva AI, an expert Indian Government Services Assistant. Answer briefly and clearly: $prompt')
        ];
        final response = await model.generateContent(content);
        if (response.text != null && response.text!.isNotEmpty) {
          return AIResponse(response.text!, true);
        }
        debugPrint('AIService: $modelName returned an empty response, trying next model.');
      } catch (e) {
        // Logged (not swallowed) so a real live-API failure is visible in
        // debug output instead of silently degrading to the offline fallback.
        debugPrint('AIService: $modelName call failed — $e');
      }
    }

    debugPrint('AIService: all live Gemini models failed, using offline fallback.');

    // 2. Built-in offline Government Knowledge Base fallback (used only if
    // every live model call above failed — e.g. no network, API not enabled,
    // or a quota error).
    return AIResponse(_generateGovernmentAssistantFallback(query, prompt), false);
  }

  // NOTE: keyword checks are ordered most-specific-first. A generic word
  // like "certificate" matches several document types (birth, marriage,
  // income...), so every more specific certificate type MUST be checked
  // before the generic 'certificate' branch, or a query like "marriage
  // certificate rule" will incorrectly match the birth-certificate case.
  String _generateGovernmentAssistantFallback(String query, String prompt) {
    if (query.contains('pan')) {
      return "To apply for a PAN Card:\n"
          "1. FREE & instant: Visit the Income Tax e-filing portal (https://www.incometax.gov.in/iec/foportal/) → 'Instant e-PAN' → enter your Aadhaar number and verify via OTP. No signature needed, e-PAN issued in minutes.\n"
          "2. For a physical card, apply via Protean/NSDL (https://onlineservices.proteantech.in) instead — ₹107, takes about 1-2 weeks.\n"
          "3. Documents required: Aadhaar Card & Passport Photo (physical card only).";
    } else if (_containsAny(query, ['marriage', 'marrige', 'wedding'])) {
      return "To register a Marriage Certificate (Tamil Nadu):\n"
          "1. Fill the application on the TNREGINET portal (https://tnreginet.gov.in).\n"
          "2. Both spouses and 3 witnesses must appear in person before the Registrar — this step is NOT online, a physical signature is legally required.\n"
          "3. Documents: Marriage invitation, ceremony photos, age & address proof of both spouses.\n"
          "4. Fee: ₹100 to ₹500 depending on the Act used.";
    } else if (query.contains('aadhaar') || _containsAny(query, ['aadhar', 'uidai'])) {
      return "To enroll or update Aadhaar Card:\n"
          "1. Address/demographic updates & e-Aadhaar download: fully online via OTP at https://myaadhaar.uidai.gov.in.\n"
          "2. New enrollment or a biometric update needs an in-person visit to an Aadhaar Seva Kendra — bring Proof of Identity and Proof of Address.\n"
          "3. New Aadhaar is Free; Demographic update costs ₹ 50.";
    } else if (query.contains('passport')) {
      return "To apply for a Passport:\n"
          "1. Register and fill the form on Passport Seva portal (https://www.passportindia.gov.in).\n"
          "2. Pay the fee (₹1,500 fresh / ₹3,500 Tatkaal) and book a slot.\n"
          "3. You must still visit a Passport Seva Kendra (PSK) in person for biometrics and document verification — this step is NOT online.\n"
          "4. Documents required: Aadhaar Card, Proof of Birth & Educational Certificate.";
    } else if (_containsAny(query, ['license', 'driving', 'rto', 'sarathi'])) {
      return "To apply for a Driving License:\n"
          "1. Apply first for a Learner License on Sarathi portal (https://sarathi.parivahan.gov.in) — this step, including the LL test in several states, is fully online.\n"
          "2. After 30 days, book a practical driving test slot for the permanent DL — the practical test itself requires an in-person RTO visit.\n"
          "3. Fee: Approx. ₹ 200 (Test) + ₹ 200 (Issue).";
    } else if (_containsAny(query, ['voter', 'epic', 'election'])) {
      return "To apply for a Voter ID Card:\n"
          "1. Visit Voter Services Portal (https://voters.eci.gov.in).\n"
          "2. Fill Form 6 for new voter registration and upload Aadhaar, Address Proof, and Photo — submission is fully online, no signature needed.\n"
          "3. A Booth Level Officer does a field verification visit afterward.\n"
          "4. Fee: Free. Processing time: 15-30 days.";
    } else if (_containsAny(query, ['birth', 'certificate'])) {
      return "To obtain a Birth Certificate:\n"
          "1. Apply on the Civil Registration System portal (https://crsorgi.gov.in) or your local Municipal Kendra.\n"
          "2. Submit within 21 days of birth with the Hospital Discharge slip & parents' Aadhaar — typically needs an in-person submission for verification.\n"
          "3. Fee: Free within 21 days.";
    } else if (_containsAny(query, ['income', 'caste', 'community', 'ration'])) {
      return "To apply for Income, Caste/Community, or Ration Cards (Tamil Nadu):\n"
          "1. Visit the TN e-Sevai portal (https://www.tnesevai.tn.gov.in) — application, document upload, and the digitally-signed certificate download are all fully online.\n"
          "2. Upload salary slip / Form 16 / self-declaration and Aadhaar.\n"
          "3. Processing time: 10-30 working days.";
    } else if (_containsAny(query, ['hi', 'hello', 'hey', 'help'])) {
      return "Hello! I am DocSeva AI, your Government Services Assistant. Ask me about Aadhaar, PAN Card, Passport, Driving License, Voter ID, Income Certificate, Marriage Certificate, or Vault storage!";
    }

    return "I am here to help you with Indian Government Services! You can ask me about:\n"
        "• How to apply for PAN, Aadhaar, Passport, or Driving License\n"
        "• Required documents & fees for government services\n"
        "• Official portal links & application tracking guide";
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }
}
