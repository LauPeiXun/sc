import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiAiService {
  late final GenerativeModel _model;

  GeminiAiService() {
    final apiKey = dotenv.maybeGet('GEMINI_API_KEY') ?? '';

    if (apiKey.isEmpty) {
      print("WARNING: GEMINI_API_KEY is missing from .env!");
    }

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<String?> processImages(List<Uint8List> imageBytes) async {
    const prompt = """
    You are a document scanning assistant.
    Please analyze the provided image (which may be a split image of one or more long receipts):
    1. Evaluate the image quality (clarity, lighting).
    2. Check if there are MULTIPLE different receipts / documents in a single view
    3. If the image quality is too poor (key information is illegible), set 'status' to 'unclear'.
    4. If the receipts is not bank receipts, set 'status' to 'invalid'.
    5. If the image detected have multiple receipts / document, set as 'multiple_detected' and set 'reason' to 'Please scan only one receipt at a time for better accuracy.'
    6. If the image quality is acceptable, set 'status' to 'clear' and extract the following information:
    - Bank name (bankName)
    - Bank account (bankAcc)
    - Total amount (totalAmount)
    - Transfer date (transferDate)
    The output must be in strict JSON format:
    {
      "data": {
        "bankName": "string",
        "bankAcc": "string",
        "totalAmount": number,
        "transferDate": "string",
        "status": "clear" | "unclear" | "multiple_detected | "invalid"
      }
    }
    """;

    try {
      final List<Part> parts = [TextPart(prompt)];

      for (var bytes in imageBytes) {
        parts.add(DataPart('image/jpeg', bytes));
      }

      final response = await _model.generateContent([Content.multi(parts)]);
      final result = response.text;
      
      if (result != null) {
        print("Gemini Response:\n$result");
      }
      
      return result;
    } catch (e) {
      print("Gemini Error: $e");
      return null;
    }
  }
}