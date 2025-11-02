import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
      minFaceSize: 0.3,
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

      final face = faces.first;

      final qualityCheck = _checkFaceQuality(face);
      if (!qualityCheck['isValid']) {
        return {
          'isValidFace': false,
          'message': qualityCheck['message'],
          'face': face
        };
      }

      return {
        'isValidFace': true,
        'message': 'Valid face detected',
        'face': face,
        'qualityScore': qualityCheck['qualityScore']
      };
    } catch (e) {
      return {'isValidFace': false, 'message': 'Face detection error: $e'};
    }
  }

  Map<String, dynamic> _checkFaceQuality(Face face) {
    final boundingBox = face.boundingBox;
    final faceWidth = boundingBox.width;
    final faceHeight = boundingBox.height;
    final faceSize = faceWidth * faceHeight;

    if (faceSize < 0.1) {
      return {
        'isValid': false,
        'message': 'Face is too small in the image',
        'qualityScore': 0.3
      };
    }

    final aspectRatio = faceWidth / faceHeight;
    if (aspectRatio < 0.6 || aspectRatio > 1.4) {
      return {
        'isValid': false,
        'message': 'Face appears distorted or at extreme angle',
        'qualityScore': 0.4
      };
    }

    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0;

    if (headEulerAngleY.abs() > 20) {
      return {
        'isValid': false,
        'message': 'Face is rotated too much to the side',
        'qualityScore': 0.4
      };
    }

    if (headEulerAngleZ.abs() > 15) {
      return {
        'isValid': false,
        'message': 'Head is tilted too much',
        'qualityScore': 0.5
      };
    }

    if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
      if (face.leftEyeOpenProbability! < 0.3 || face.rightEyeOpenProbability! < 0.3) {
        return {
          'isValid': false,
          'message': 'Eyes are not clearly visible or closed',
          'qualityScore': 0.6
        };
      }
    }

    if (!_areLandmarksVisible(face)) {
      return {
        'isValid': false,
        'message': 'Facial features are not clear enough',
        'qualityScore': 0.7
      };
    }

    final qualityScore = _calculateQualityScore(face);

    if (qualityScore < 0.6) {
      return {
        'isValid': false,
        'message': 'Face quality is too low for recognition',
        'qualityScore': qualityScore
      };
    }

    return {
      'isValid': true,
      'message': 'Face meets quality standards',
      'qualityScore': qualityScore
    };
  }

  bool _areLandmarksVisible(Face face) {
    try {
      final landmarks = face.landmarks;

      final nonNullLandmarks = landmarks.values.where((landmark) => landmark != null).length;

      if (nonNullLandmarks < 5) {
        return false;
      }

      return _checkLandmarksDistribution(landmarks);
    } catch (e) {
      return false;
    }
  }

  bool _checkLandmarksDistribution(Map<FaceLandmarkType, FaceLandmark?> landmarks) {
    try {
      const requiredLandmarks = [
        FaceLandmarkType.leftEye,
        FaceLandmarkType.rightEye,
        FaceLandmarkType.noseBase,
      ];

      int foundRequired = 0;
      for (final type in requiredLandmarks) {
        if (landmarks[type] != null) {
          foundRequired++;
        }
      }

      if (foundRequired < 2) {
        return false;
      }

      final regions = <String>{};

      landmarks.forEach((type, landmark) {
        if (landmark != null) {
          if (type.toString().contains('Eye')) {
            regions.add('eyes');
          } else if (type.toString().contains('Nose')) {
            regions.add('nose');
          } else if (type.toString().contains('Mouth')) {
            regions.add('mouth');
          } else if (type.toString().contains('Cheek')) {
            regions.add('cheeks');
          } else if (type.toString().contains('Ear')) {
            regions.add('ears');
          } else if (type.toString().contains('Brow')) {
            regions.add('brows');
          }
        }
      });

      return regions.length >= 3;
    } catch (e) {
      return false;
    }
  }

  double _calculateQualityScore(Face face) {
    double score = 0.0;
    int factors = 0;

    final boundingBox = face.boundingBox;
    final faceSize = boundingBox.width * boundingBox.height;
    if (faceSize > 0.25) {
      score += 0.4;
    } else if (faceSize > 0.15) {
      score += 0.3;
    } else if (faceSize > 0.1) {
      score += 0.2;
    } else {
      score += 0.1;
    }
    factors++;

    final headEulerAngleY = face.headEulerAngleY?.abs() ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ?.abs() ?? 0;

    double rotationScore = 1.0;
    rotationScore -= (headEulerAngleY / 30).clamp(0.0, 0.5);
    rotationScore -= (headEulerAngleZ / 20).clamp(0.0, 0.5);
    score += rotationScore * 0.3;
    factors++;

    if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
      final eyeScore = (face.leftEyeOpenProbability! + face.rightEyeOpenProbability!) / 2;
      score += eyeScore * 0.2;
      factors++;
    }

    if (_areLandmarksVisible(face)) {
      score += 0.1;
      factors++;
    }

    return score;
  }

  Map<String, dynamic> getFaceQualityDetails(Face face) {
    return {
      'faceSize': face.boundingBox.width * face.boundingBox.height,
      'faceWidth': face.boundingBox.width,
      'faceHeight': face.boundingBox.height,
      'aspectRatio': face.boundingBox.width / face.boundingBox.height,
      'headRotationY': face.headEulerAngleY ?? 0,
      'headRotationZ': face.headEulerAngleZ ?? 0,
      'leftEyeOpen': face.leftEyeOpenProbability ?? 0,
      'rightEyeOpen': face.rightEyeOpenProbability ?? 0,
      'smilingProbability': face.smilingProbability ?? 0,
      'landmarksCount': face.landmarks.length,
      'landmarksVisible': _areLandmarksVisible(face),
      'qualityScore': _calculateQualityScore(face),
    };
  }

  String getQualityTips(Face face) {
    final details = getFaceQualityDetails(face);
    final tips = <String>[];

    if (details['faceSize'] < 0.15) {
      tips.add('• Move closer to the camera');
    }

    if (details['headRotationY'].abs() > 10) {
      tips.add('• Face the camera directly');
    }

    if (details['headRotationZ'].abs() > 8) {
      tips.add('• Keep your head straight');
    }

    if ((details['leftEyeOpen'] + details['rightEyeOpen']) / 2 < 0.5) {
      tips.add('• Make sure your eyes are open and visible');
    }

    if (details['landmarksCount'] < 5) {
      tips.add('• Ensure good lighting on your face');
    }

    return tips.isEmpty ? 'Good quality face image' : tips.join('\n');
  }

  void dispose() {
    _faceDetector.close();
  }
}