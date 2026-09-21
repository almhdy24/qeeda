import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static OcrService? _instance;
  OcrService._();
  static OcrService get instance {
    _instance ??= OcrService._();
    return _instance!;
  }

  // Performs on-device OCR on the given image file path.
  // Recognizes Latin and Arabic scripts. Returns null on failure or empty result.
  Future<String?> recognizeText(String imagePath) async {
    TextRecognizer? recognizer;
    try {
      recognizer = TextRecognizer();
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
