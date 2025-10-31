import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../data/models/EmployeeModel.dart';

class RealFaceRecognitionService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableContours: true,
    ),
  );

  Future<bool> isFaceDetected(InputImage frame) async {
    final faces = await _faceDetector.processImage(frame);
    return faces.isNotEmpty;
  }

  Future<double> compareFaceWithEmployee(InputImage frame, EmployeeModel employee) async {
    final faces = await _faceDetector.processImage(frame);
    if (faces.isEmpty) return 0.0;

    final inputFace = faces.first;

    final employeeImage = InputImage.fromFilePath(employee.profileImagePath);
    final employeeFaces = await _faceDetector.processImage(employeeImage);
    if (employeeFaces.isEmpty) return 0.0;

    final employeeFace = employeeFaces.first;

    return compareFaces(inputFace, employeeFace);
  }

  Future<double> compareFaces(Face face1, Face face2) async {
    double total = 0.0;
    int count = 0;

    if (face1.leftEyeOpenProbability != null && face2.leftEyeOpenProbability != null) {
      total += 1.0 - (face1.leftEyeOpenProbability! - face2.leftEyeOpenProbability!).abs();
      count++;
    }
    if (face1.rightEyeOpenProbability != null && face2.rightEyeOpenProbability != null) {
      total += 1.0 - (face1.rightEyeOpenProbability! - face2.rightEyeOpenProbability!).abs();
      count++;
    }
    if (face1.smilingProbability != null && face2.smilingProbability != null) {
      total += 1.0 - (face1.smilingProbability! - face2.smilingProbability!).abs();
      count++;
    }

    if (count == 0) return 0.0;
    return total / count;
  }

  void dispose() {
    _faceDetector.close();
  }
}
