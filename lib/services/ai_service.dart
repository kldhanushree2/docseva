import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Wraps an AI Assistant reply together with whether it came from the live
/// Gemini API or the offline built-in knowledge base, so the UI can be
/// honest with the user about which one they're looking at.
class AIResponse {
  final String text;
  final bool isLive;
  const AIResponse(this.text, this.isLive);
}

class AIService {
  // TODO: paste your key between the quotes. Never share this file with the
  // key in it, and never upload it to GitHub.
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  // Tried in order. Re-check https://ai.google.dev/gemini-api/docs/models
  // from time to time because model names change.
  static const List<String> _modelsToTry = [
    'gemini-3.6-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
  ];

  // Tells Gemini what DocSeva is and how it works, so the assistant can
  // explain the app. Keep this list accurate: if a feature is not listed
  // here, the assistant says it is not sure instead of making it up.
  static const String _systemPrompt = '''
You are DocSeva AI, the built-in assistant of the DocSeva app, a government document assistant for Indian users. The app's tagline is "Apply smart. Track easy. Store safe."

ABOUT THE APP (use this to answer any question about DocSeva or how to use it):
- The app has four tabs at the bottom: Home, Services, Documents and Profile.
- Services: step-by-step guides for PAN, Aadhaar, Passport, Driving License, Voter ID, Income, Caste/Community and Ration cards, and Marriage and Birth certificates.
- Documents (the Vault): a private place to store photos (JPG, PNG) and PDFs of your documents. Tap the + button, choose Photo or PDF, pick the file, give it a name, choose a category (Identity, Tax / Finance, Education, Vehicle / License, Other) and tap Upload Document. Tap a document to view it. The three-dot menu on each document has View, Share / Save and Delete.
- AI Assistant: this chat. Users can ask about any government service, required documents, fees, official portals and how to track an application.
- Reminders: the app can send notification reminders (for example for deadlines or renewals).
- Profile: the user's account details and logout.
- Users must register and log in with their email and password to use the app.

RULES:
- For questions about the app, answer only from the list above. If something is not listed, say you are not sure the app has that feature. Never invent screens, buttons or features.
- For government service questions, give short numbered steps, name the official portal, and say clearly if a step needs an in-person visit. If unsure, say so instead of guessing.
- Never ask for Aadhaar numbers, OTPs, passwords or other personal data.
- Keep answers under about 150 words. Use plain text only: no markdown, no asterisks, no # headings. Use simple numbered lines like "1. ...".
''';

  Future<AIResponse> askQuestion(String prompt) async {
    final query = prompt.toLowerCase();

    // 1. Try the live Gemini API (skipped if no real key has been set).
    if (_apiKey.isNotEmpty && !_apiKey.startsWith('PASTE_')) {
      for (final modelName in _modelsToTry) {
        try {
          final text = await _callGemini(modelName, prompt);
          if (text != null && text.trim().isNotEmpty) {
            return AIResponse(text.trim(), true);
          }
          debugPrint('AIService: $modelName returned an empty response, trying next model.');
        } catch (e) {
          debugPrint('AIService: $modelName call failed — $e');
        }
      }
      debugPrint('AIService: all live Gemini models failed, using offline fallback.');
    } else {
      debugPrint('AIService: no API key set, using offline fallback.');
    }

    // 2. Built-in offline knowledge base (used only if the live call failed).
    return AIResponse(_generateGovernmentAssistantFallback(query), false);
  }

  /// Calls the Gemini REST API directly (no SDK), sending the key in the
  /// x-goog-api-key header. Returns the reply text, or throws with a
  /// readable message.
  Future<String?> _callGemini(String modelName, String prompt) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent',
    );

    final response = await http
        .post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _apiKey,
      },
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': _systemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) {
      var body = response.body;
      try {
        final decoded = jsonDecode(body);
        final message = decoded['error']?['message'];
        if (message != null) body = message.toString();
      } catch (_) {}
      if (body.length > 220) body = '${body.substring(0, 220)}...';
      throw Exception('HTTP ${response.statusCode}: $body');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return null;

    final parts = candidates.first['content']?['parts'] as List?;
    if (parts == null) return null;

    // Join the text parts and skip any internal "thought" parts.
    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] != null && part['thought'] != true) {
        buffer.write(part['text']);
      }
    }
    return buffer.toString();
  }

  // Offline fallback. Order matters: the most specific checks come first.
  // All keyword checks use WHOLE-WORD matching (see _containsAny), so "this"
  // does not match "hi" and "registration" does not match "ration".
  String _generateGovernmentAssistantFallback(String query) {
    if (_containsAny(query, ['how to use', 'use this app', 'about this app', 'about app', 'features'])) {
      return "DocSeva helps you with government documents:\n"
          "1. Services tab: step-by-step guides for PAN, Aadhaar, Passport, Driving License, Voter ID and more.\n"
          "2. Documents tab: store photos and PDFs of your documents safely in your Vault.\n"
          "3. AI Assistant: ask any question about a government service.\n"
          "4. Profile tab: manage your account.";
    }

    if (_containsAny(query, ['track', 'status'])) {
      return "To track an application:\n"
          "1. Keep the acknowledgement or reference number you received when you applied.\n"
          "2. Open the official portal you applied on (for example Protean/NSDL or UTIITSL for PAN, Passport Seva for passports, Sarathi for driving licenses, Voters Service Portal for voter ID).\n"
          "3. Use the 'Track Application Status' option there and enter your number.";
    }

    if (_containsAny(query, ['pan'])) {
      return "To apply for a PAN Card:\n"
          "1. FREE & instant: Visit the Income Tax e-filing portal (https://www.incometax.gov.in/iec/foportal/) → 'Instant e-PAN' → enter your Aadhaar number and verify via OTP. No signature needed, e-PAN issued in minutes.\n"
          "2. For a physical card, apply via Protean/NSDL (https://onlineservices.proteantech.in) instead — ₹107, takes about 1-2 weeks.\n"
          "3. Documents required: Aadhaar Card & Passport Photo (physical card only).";
    }

    if (_containsAny(query, ['marriage', 'marrige', 'wedding'])) {
      return "To register a Marriage Certificate (Tamil Nadu):\n"
          "1. Fill the application on the TNREGINET portal (https://tnreginet.gov.in).\n"
          "2. Both spouses and 3 witnesses must appear in person before the Registrar — this step is NOT online, a physical signature is legally required.\n"
          "3. Documents: Marriage invitation, ceremony photos, age & address proof of both spouses.\n"
          "4. Fee: ₹100 to ₹500 depending on the Act used.";
    }

    if (_containsAny(query, ['aadhaar', 'aadhar', 'uidai'])) {
      return "To enroll or update Aadhaar Card:\n"
          "1. Address/demographic updates & e-Aadhaar download: fully online via OTP at https://myaadhaar.uidai.gov.in.\n"
          "2. New enrollment or a biometric update needs an in-person visit to an Aadhaar Seva Kendra — bring Proof of Identity and Proof of Address.\n"
          "3. New Aadhaar is Free; Demographic update costs ₹ 50.";
    }

    if (_containsAny(query, ['passport'])) {
      return "To apply for a Passport:\n"
          "1. Register and fill the form on Passport Seva portal (https://www.passportindia.gov.in).\n"
          "2. Pay the fee (₹1,500 fresh / ₹3,500 Tatkaal) and book a slot.\n"
          "3. You must still visit a Passport Seva Kendra (PSK) in person for biometrics and document verification — this step is NOT online.\n"
          "4. Documents required: Aadhaar Card, Proof of Birth & Educational Certificate.";
    }

    if (_containsAny(query, ['license', 'licence', 'driving', 'rto', 'sarathi'])) {
      return "To apply for a Driving License:\n"
          "1. Apply first for a Learner License on Sarathi portal (https://sarathi.parivahan.gov.in) — this step, including the LL test in several states, is fully online.\n"
          "2. After 30 days, book a practical driving test slot for the permanent DL — the practical test itself requires an in-person RTO visit.\n"
          "3. Fee: Approx. ₹ 200 (Test) + ₹ 200 (Issue).";
    }

    if (_containsAny(query, ['voter', 'epic', 'election'])) {
      return "To apply for a Voter ID Card:\n"
          "1. Visit Voter Services Portal (https://voters.eci.gov.in).\n"
          "2. Fill Form 6 for new voter registration and upload Aadhaar, Address Proof, and Photo — submission is fully online, no signature needed.\n"
          "3. A Booth Level Officer does a field verification visit afterward.\n"
          "4. Fee: Free. Processing time: 15-30 days.";
    }

    if (_containsAny(query, ['birth', 'certificate'])) {
      return "To obtain a Birth Certificate:\n"
          "1. Apply on the Civil Registration System portal (https://crsorgi.gov.in) or your local Municipal Kendra.\n"
          "2. Submit within 21 days of birth with the Hospital Discharge slip & parents' Aadhaar — typically needs an in-person submission for verification.\n"
          "3. Fee: Free within 21 days.";
    }

    if (_containsAny(query, ['income', 'caste', 'community', 'ration'])) {
      return "To apply for Income, Caste/Community, or Ration Cards (Tamil Nadu):\n"
          "1. Visit the TN e-Sevai portal (https://www.tnesevai.tn.gov.in) — application, document upload, and the digitally-signed certificate download are all fully online.\n"
          "2. Upload salary slip / Form 16 / self-declaration and Aadhaar.\n"
          "3. Processing time: 10-30 working days.";
    }

    if (_containsAny(query, ['hi', 'hello', 'hey', 'help'])) {
      return "Hello! I am DocSeva AI, your Government Services Assistant. Ask me about Aadhaar, PAN Card, Passport, Driving License, Voter ID, Income Certificate, Marriage Certificate, or Vault storage!";
    }

    return "I am here to help you with Indian Government Services! You can ask me about:\n"
        "• How to apply for PAN, Aadhaar, Passport, or Driving License\n"
        "• Required documents & fees for government services\n"
        "• Official portal links & application tracking guide";
  }

  /// Whole-word match: "pan" matches "pan card" but not "company" or "japan".
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any(
          (k) => RegExp('\\b${RegExp.escape(k)}\\b').hasMatch(text),
    );
  }
}