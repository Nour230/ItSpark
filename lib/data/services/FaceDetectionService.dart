import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
    ),
  );

  Future<Map<String, dynamic>> isFaceDetected(InputImage image) async {
    try {
      final faces = await _faceDetector.processImage(image);

      if (faces.isEmpty) {
        return {'isValidFace': false, 'message': 'No face detected'};
      }
      if (faces.length > 1) {
        return {'isValidFace': false, 'message': 'Multiple faces detected'};
      }

      return {'isValidFace': true, 'message': 'Face detected', 'face': faces.first};
    } catch (e) {
      return {'isValidFace': false, 'message': 'Face detection error: $e'};
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}
