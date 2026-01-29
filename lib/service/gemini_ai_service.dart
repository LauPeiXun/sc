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

  Future<String?> processImage(Uint8List imageBytes) async {
    const prompt = """
    You are a professional financial document parser. 
    Analyze the image and return a strict JSON response.
    
    1. QUALITY CHECK & STATUS LOGIC:
       - If more than 1 distinct receipt or transaction slip is detected in the image:
         Set Status = "multiple_detected" IMMEDIATELY and skip extraction
       - MANDATORY FIELDS: 'bank', 'bankAcc', 'totalAmount', 'location' and at least one 'date'.
       - STATUS RULE: 
         * If all Mandatory Fields are found for a SINGLE receipt: status = "clear".
         * If ANY Mandatory Field is null, status MUST be "unclear".
         * If NOT a bank receipt, even got Mandatory Field: status = "invalid".
    
    2. DATA EXTRACTION (Only if status is "clear"):
       - Only perform full extraction if status is "clear".
       - If status is "multiple_detected", "unclear", or "invalid", return null or empty strings for the data fields.
       
       - bank: Full bank name.
       - bankAcc: Recipient/Target account number.
       - totalAmount: Numerical value only (MUST NOT be null if status is clear).
    
       - printedDate: 
         * Look for MACHINE-GENERATED, FIXED-FONT text. 
         * Usually located near the top or bottom of the slip, often next to "DATE" or "TIME".
         * Format: DD/MM/YYYY.
    
       - handwrittenDate: 
         * Look for HANDWRITTEN, PEN-INK text (usually cursive or informal).
         * This is often written by the customer in empty spaces.
         * If NO pen-ink handwriting is seen, return null. 
         * Format: DD/MM/YYYY.
    
       - location: Prioritize System Printed, then Handwritten.
       * Format: 1009 ALAM MELATI
       * Written by the customer 
    
    3. OUTPUT FORMAT (Strict JSON):
    Return ONLY a single JSON object. If multiple receipts are found, return the most prominent one and set status to "multiple_detected".
    {
      "data": {
        "bank": "string",
        "bankAcc": "string",
        "totalAmount": number,
        "printedDate": "string",
        "handwrittenDate": "string",
        "location": "string",
        "status": "clear" | "unclear" | "multiple_detected" | "invalid"
      }
    }    
    """;

    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final result = response.text;

      if (result != null) {
        print("Gemini Response:\n$result");
      }

      return result;
    } catch (e) {
      print("❌ Gemini Error: $e");
      return null;
    }
  }
}