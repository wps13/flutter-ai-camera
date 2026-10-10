import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';

import 'ai_image_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    // debug config, needs to be updated to prod
    providerAndroid: AndroidDebugProvider(),
    providerApple: AppleDebugProvider(),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ImageAnalyzerScreen(),
    );
  }
}

class ImageAnalyzerScreen extends StatefulWidget {
  const ImageAnalyzerScreen({super.key});
  @override
  State<ImageAnalyzerScreen> createState() => _ImageAnalyzerScreenState();
}

class _ImageAnalyzerScreenState extends State<ImageAnalyzerScreen> {
  final _analyzer = ImageAnalyzer();
  File? _image;
  String? _result;
  bool _isAnalyzing = false;
  // Change this prompt for different use cases
  final String _prompt = '''
Analise esta imagem e identifique quais alimentos estão presentes; o objetivo é sugerir uma receita que os utilize, para ser preparada em no máximo 30 minutos.
''';
  Future<void> _analyzeFromCamera() async {
    final image = await _analyzer.pickImage(fromCamera: true);
    if (image == null) return;
    setState(() {
      _image = image;
      _isAnalyzing = true;
      _result = null;
    });
    try {
      final result = await _analyzer.analyze(imageFile: image, prompt: _prompt);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _result = 'Error: $e');
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Image Analyzer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image preview
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 300, fit: BoxFit.cover),
              )
            else
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('Take a photo to analyze')),
              ),
            const SizedBox(height: 16),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () async {
                            final image = await _analyzer.pickImage(
                              fromCamera: false,
                            );
                            if (image == null) return;
                            setState(() {
                              _image = image;
                              _isAnalyzing = true;
                            });
                            final result = await _analyzer.analyze(
                              imageFile: image,
                              prompt: _prompt,
                            );
                            setState(() {
                              _result = result;
                              _isAnalyzing = false;
                            });
                          },
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Results
            if (_isAnalyzing)
              const Center(child: CircularProgressIndicator())
            else if (_result != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(_result!),
              ),
          ],
        ),
      ),
    );
  }
}
