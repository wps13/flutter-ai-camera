import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:image_picker/image_picker.dart';

class ImageAnalyzer {
  final GenerativeModel _model;
  ImageAnalyzer()
    : _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash', // Free tier, multimodal, fast
      );

  /// Analyze an image with a custom prompt
  Future<String> analyze({
    required File imageFile,
    required String prompt,
  }) async {
    final imageBytes = await imageFile.readAsBytes();
    final response = await _model.generateContent([
      Content.multi([
        TextPart(prompt),
        InlineDataPart('image/jpeg', imageBytes),
      ]),
    ]);
    return response.text ?? 'Analise Indisponível';
  }

  /// Pick image from camera or gallery
  Future<File?> pickImage({bool fromCamera = true}) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1024, // Compress to reduce upload size and cost
      imageQuality: 85,
    );
    return image != null ? File(image.path) : null;
  }
}
