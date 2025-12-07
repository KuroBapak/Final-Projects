import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';


final ocrServiceProvider = Provider<OCRService>((ref) {
  return OCRService();
});

class OCRService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  DateTime? parseDate(String text) {
    // Regex patterns for common date formats
    // DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
    // YYYY/MM/DD, YYYY-MM-DD, YYYY.MM.DD
    // DD MMM YYYY (e.g., 29 Nov 2023)
    
    final List<RegExp> patterns = [
      RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b'), // DD/MM/YYYY or DD-MM-YYYY
      RegExp(r'\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})\b'), // YYYY/MM/DD or YYYY-MM-DD
      RegExp(r'\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{4})\b', caseSensitive: false), // DD MMM YYYY
    ];

    for (final regex in patterns) {
      final match = regex.firstMatch(text);
      if (match != null) {
        try {
          if (regex.pattern.contains('Jan')) {
            // Handle DD MMM YYYY
            final day = int.parse(match.group(1)!);
            final monthStr = match.group(2)!;
            final year = int.parse(match.group(3)!);
            final month = _monthStringToInt(monthStr);
            return DateTime(year, month, day);
          } else if (match.groupCount == 3) {
            // Handle numeric formats
            // We need to guess if it's DD/MM/YYYY or YYYY/MM/DD based on the pattern index
            // Pattern 0: DD/MM/YYYY (groups: 1=D, 2=M, 3=Y)
            // Pattern 1: YYYY/MM/DD (groups: 1=Y, 2=M, 3=D)
            
            if (patterns.indexOf(regex) == 0) {
               final day = int.parse(match.group(1)!);
               final month = int.parse(match.group(2)!);
               final year = int.parse(match.group(3)!);
               return DateTime(year, month, day);
            } else {
               final year = int.parse(match.group(1)!);
               final month = int.parse(match.group(2)!);
               final day = int.parse(match.group(3)!);
               return DateTime(year, month, day);
            }
          }
        } catch (e) {
          debugPrint('Date parse error: $e');
          continue;
        }
      }
    }
    return null;
  }

  int _monthStringToInt(String month) {
    switch (month.toLowerCase().substring(0, 3)) {
      case 'jan': return 1;
      case 'feb': return 2;
      case 'mar': return 3;
      case 'apr': return 4;
      case 'may': return 5;
      case 'jun': return 6;
      case 'jul': return 7;
      case 'aug': return 8;
      case 'sep': return 9;
      case 'oct': return 10;
      case 'nov': return 11;
      case 'dec': return 12;
      default: return 1;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
