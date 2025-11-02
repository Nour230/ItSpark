import '../../utils/enums/FaceRecognitionType.dart';

class FaceRecognitionResult {
  final bool isSuccess;
  final String? userId;
  final double? confidence;
  final String message;
  final FaceRecognitionType type;

  FaceRecognitionResult({
    required this.isSuccess,
    this.userId,
    this.confidence,
    required this.message,
    required this.type,
  });

  factory FaceRecognitionResult.registered(String userId) {
    return FaceRecognitionResult(
      isSuccess: true,
      userId: userId,
      message: '✅ Employee registered successfully',
      type: FaceRecognitionType.registered,
    );
  }

  factory FaceRecognitionResult.recognized(String userId, double confidence) {
    return FaceRecognitionResult(
      isSuccess: true,
      userId: userId,
      confidence: confidence,
      message: '✅ Recognized: $userId (${(confidence * 100).toStringAsFixed(1)}%)',
      type: FaceRecognitionType.recognized,
    );
  }

  factory FaceRecognitionResult.noFace() {
    return FaceRecognitionResult(
      isSuccess: false,
      message: '❌ No face detected',
      type: FaceRecognitionType.noFace,
    );
  }

  factory FaceRecognitionResult.multipleFaces() {
    return FaceRecognitionResult(
      isSuccess: false,
      message: '❌ Multiple faces detected',
      type: FaceRecognitionType.multipleFaces,
    );
  }

  factory FaceRecognitionResult.notRecognized() {
    return FaceRecognitionResult(
      isSuccess: false,
      message: '❌ Face not recognized',
      type: FaceRecognitionType.notRecognized,
    );
  }

  factory FaceRecognitionResult.error(String error) {
    return FaceRecognitionResult(
      isSuccess: false,
      message: '❌ Error: $error',
      type: FaceRecognitionType.error,
    );
  }

  bool get isRecognized => type == FaceRecognitionType.recognized;
  bool get isRegistered => type == FaceRecognitionType.registered;
  bool get hasError => type == FaceRecognitionType.error;

  @override
  String toString() {
    return 'FaceRecognitionResult{isSuccess: $isSuccess, userId: $userId, confidence: $confidence, message: $message, type: $type}';
  }
}
