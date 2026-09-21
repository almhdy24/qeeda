import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static OcrService? _instance;
  OcrService._();
  static OcrService get instance {
    _instance ??= OcrService._();
    return _instance!;
  }

  // Performs Latin-script OCR on the given image file path.
  // Arabic text may not be recognized accurately with this recognizer.
  // Returns null if recognition fails or produces no text.
  Future<String?> recognizeText(String imagePath) async {
    TextRecognizer? recognizer;
    try {
      recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);
      final text = result.text.trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    } finally {
      await recognizer?.close();
    }
  }
}
