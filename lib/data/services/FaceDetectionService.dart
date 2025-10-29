import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {

  FaceDetectionService() {
    print('✅ FaceDetectionService created - v0.9.0');
  }

  Future<Map<String, dynamic>> isFaceDetectedWithDetails(String imagePath) async {
    print('🔍 Checking for face in: $imagePath');

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return {
          'isValidFace': false,
          'message': 'Image file not found',
          'facesCount': 0
        };
      }

      final inputImage = InputImage.fromFilePath(imagePath);

      // جرب استخدام 'option' بدلاً من 'options'
      final faceDetector = FaceDetector(options: FaceDetectorOptions());
      final List<Face> faces = await faceDetector.processImage(inputImage);
      faceDetector.close();

      print('📊 Raw detection: ${faces.length} face(s) found');

      return _validateFaceConditions(faces);

    } catch (e) {
      print('❌ Error in face detection: $e');
      return {
        'isValidFace': false,
        'message': 'Face detection error',
        'facesCount': 0
      };
    }
  }

  Map<String, dynamic> _validateFaceConditions(List<Face> faces) {
    if (faces.isEmpty) {
      return {
        'isValidFace': false,
        'message': 'No face detected. Please position your face in the frame.',
        'facesCount': 0
      };
    }

    if (faces.length > 1) {
      return {
        'isValidFace': false,
        'message': 'Multiple faces detected. Please ensure only one person is in the frame.',
        'facesCount': faces.length
      };
    }

    // إذا وجد وجه واحد فقط - نقبله
    return {
      'isValidFace': true,
      'message': 'Face detected! Ready to capture.',
      'facesCount': 1
    };
  }

  Future<bool> isFaceDetected(String imagePath) async {
    final result = await isFaceDetectedWithDetails(imagePath);
    return result['isValidFace'] ?? false;
  }

  void dispose() {
    print('🗑️ Service disposed');
  }
}