import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();

  Future<String> getTextFromImage(XFile imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  // This is a very simplified parser and would need to be much more robust.
  List<Map<String, dynamic>> parseBillText(String text) {
    final List<Map<String, dynamic>> items = [];
    final lines = text.split('\n');

    for (final line in lines) {
      // A simple regex looking for a price at the end of the line
      final RegExp priceRegex = RegExp(r'(\d+[.,]\d{2})$');
      final match = priceRegex.firstMatch(line);

      if (match != null) {
        final priceString = match.group(1)?.replaceAll(',', '.');
        final price = double.tryParse(priceString ?? '');
        if (price != null) {
          final description = line.substring(0, match.start).trim();
          if (description.isNotEmpty) {
            items.add({'description': description, 'price': price});
          }
        }
      }
    }
    return items;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
