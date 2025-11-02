import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/EmployeeModel.dart';
import '../models/FaceRecognitionResult.dart';
import '../models/FaceSignature.dart';

class SmartFaceRecognitionService {
  final FaceDetector _faceDetector;
  final double _similarityThreshold = 0.92;

  final Map<String, EmployeeModel> _employeeDatabase = {};

  SmartFaceRecognitionService()
      : _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
      enableContours: true,
      enableClassification: true,
      enableTracking: false,
    ),
  );

  void loadEmployees(List<EmployeeModel> employees) {
    _employeeDatabase.clear();
    for (final employee in employees) {
      _employeeDatabase[employee.id.toString()] = employee;
    }
    print('📦 Loaded ${employees.length} employees from database');
  }

  Future<FaceRecognitionResult> processFace(
      InputImage inputImage, {
        String? registerAs,
      }) async {
    try {
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) return FaceRecognitionResult.noFace();
      if (faces.length > 1) return FaceRecognitionResult.multipleFaces();

      final face = faces.first;
      if (!_isFaceQualityGood(face)) {
        return FaceRecognitionResult.error('Poor face quality or angle');
      }

      final signature = _extractFaceSignature(face);

      if (registerAs != null) {
        print('✅ Employee $registerAs registered in system');
        return FaceRecognitionResult.registered(registerAs);
      } else {
        return await _compareWithAllEmployees(signature);
      }
    } catch (e) {
      return FaceRecognitionResult.error('Error: $e');
    }
  }

  Future<FaceRecognitionResult> _compareWithAllEmployees(FaceSignature targetSignature) async {
    if (_employeeDatabase.isEmpty) {
      return FaceRecognitionResult.notRecognized();
    }

    String? bestMatchEmployeeId;
    double bestSimilarity = 0.0;
    String? secondBestMatchEmployeeId;
    double secondBestSimilarity = 0.0;

    print('🔍 Comparing with ${_employeeDatabase
        .length} employees from database...');

    for (final employee in _employeeDatabase.values) {
      try {
        final employeeId = employee.id.toString();
        double employeeBestSimilarity = 0.0;

        print('👤 Processing: ${employee.name} (ID: $employeeId)');

        try {
          final profileImage = InputImage.fromFilePath(
              employee.profileImagePath);
          final profileSignature = await _extractSignatureFromImage(
              profileImage);

          if (profileSignature != null) {
            final similarity = _calculateSignatureSimilarity(
                targetSignature, profileSignature);
            print('   📸 Profile image: ${(similarity * 100).toStringAsFixed(
                1)}%');

            if (similarity > employeeBestSimilarity) {
              employeeBestSimilarity = similarity;
            }
          }
        } catch (e) {
          print('   ❌ Error processing profile image: $e');
        }

        for (int i = 0; i < employee.calibrationImages.length; i++) {
          try {
            final calibImagePath = employee.calibrationImages[i];
            final calibImage = InputImage.fromFilePath(calibImagePath);
            final calibSignature = await _extractSignatureFromImage(calibImage);

            if (calibSignature != null) {
              final similarity = _calculateSignatureSimilarity(
                  targetSignature, calibSignature);
              print('   📸 Calibration image ${i + 1}: ${(similarity * 100)
                  .toStringAsFixed(1)}%');

              if (similarity > employeeBestSimilarity) {
                employeeBestSimilarity = similarity;
              }
            }
          } catch (e) {
            print('   ❌ Error processing calibration image ${i + 1}: $e');
          }
        }

        print('   🎯 Best similarity for ${employee
            .name}: ${(employeeBestSimilarity * 100).toStringAsFixed(1)}%');

        if (employeeBestSimilarity > _similarityThreshold) {
          if (employeeBestSimilarity > bestSimilarity) {
            secondBestMatchEmployeeId = bestMatchEmployeeId;
            secondBestSimilarity = bestSimilarity;

            bestSimilarity = employeeBestSimilarity;
            bestMatchEmployeeId = employeeId;
          } else if (employeeBestSimilarity > secondBestSimilarity) {
            secondBestMatchEmployeeId = employeeId;
            secondBestSimilarity = employeeBestSimilarity;
          }
        }
      } catch (e) {
        print('❌ Error processing employee ${employee.name}: $e');
      }
    }

    if (bestMatchEmployeeId != null) {
      final difference = bestSimilarity - (secondBestSimilarity);

      if (bestSimilarity > 0.95) {
        final employee = _employeeDatabase[bestMatchEmployeeId];
        print('🎯 HIGH CONFIDENCE: ${employee?.name} - ${(bestSimilarity * 100)
            .toStringAsFixed(1)}%');
        return FaceRecognitionResult.recognized(
            bestMatchEmployeeId, bestSimilarity);
      }

      if (difference > 0.03) {
        final employee = _employeeDatabase[bestMatchEmployeeId];
        print('🎯 CLEAR MATCH: ${employee?.name} - ${(bestSimilarity * 100)
            .toStringAsFixed(1)}%');
        return FaceRecognitionResult.recognized(
            bestMatchEmployeeId, bestSimilarity);
      }

      if (difference > 0.01) {
        return _handleSimilarMatches(
          bestMatchEmployeeId,
          bestSimilarity,
          secondBestMatchEmployeeId,
          secondBestSimilarity,
          targetSignature,
        );
      }

      print('❌ TOO CLOSE: $bestMatchEmployeeId (${(bestSimilarity * 100)
          .toStringAsFixed(1)}%) vs '
          '$secondBestMatchEmployeeId (${(secondBestSimilarity * 100)
          .toStringAsFixed(1)}%)');
      return FaceRecognitionResult.notRecognized();
    } else {
      print('❌ No match found above threshold');
      return FaceRecognitionResult.notRecognized();
    }
  }

  Future<FaceSignature?> _extractSignatureFromImage(InputImage image) async {
    try {
      final faces = await _faceDetector.processImage(image);
      if (faces.isNotEmpty && _isFaceQualityGood(faces.first)) {
        return _extractFaceSignature(faces.first);
      }
    } catch (e) {
      print('❌ Error extracting signature from image: $e');
    }
    return null;
  }

  Future<Map<String, bool>> registerEmployeeWithAllImages(EmployeeModel employee) async {
    final results = <String, bool>{};

    _employeeDatabase[employee.id.toString()] = employee;

    print('✅ Registered employee: ${employee.name} with ${employee.calibrationImages.length + 1} images');

    results['employee'] = true;
    return results;
  }

  Future<Map<String, dynamic>> validateEmployeeImages(EmployeeModel employee) async {
    final results = <String, dynamic>{
      'isValid': true,
      'errors': <String>[],
      'imagesStatus': <String, bool>{}
    };

    try {
      final profileImage = InputImage.fromFilePath(employee.profileImagePath);
      final profileFaces = await _faceDetector.processImage(profileImage);

      if (profileFaces.isEmpty) {
        results['isValid'] = false;
        results['errors'].add('No face detected in profile image');
        results['imagesStatus']['profile'] = false;
      } else if (!_isFaceQualityGood(profileFaces.first)) {
        results['isValid'] = false;
        results['errors'].add('Poor quality in profile image');
        results['imagesStatus']['profile'] = false;
      } else {
        results['imagesStatus']['profile'] = true;
      }
    } catch (e) {
      results['isValid'] = false;
      results['errors'].add('Error processing profile image: $e');
      results['imagesStatus']['profile'] = false;
    }

    for (int i = 0; i < employee.calibrationImages.length; i++) {
      try {
        final calibImage = InputImage.fromFilePath(employee.calibrationImages[i]);
        final calibFaces = await _faceDetector.processImage(calibImage);

        if (calibFaces.isEmpty) {
          results['isValid'] = false;
          results['errors'].add('No face detected in calibration image ${i + 1}');
          results['imagesStatus']['calib_$i'] = false;
        } else if (!_isFaceQualityGood(calibFaces.first)) {
          results['isValid'] = false;
          results['errors'].add('Poor quality in calibration image ${i + 1}');
          results['imagesStatus']['calib_$i'] = false;
        } else {
          results['imagesStatus']['calib_$i'] = true;
        }
      } catch (e) {
        results['isValid'] = false;
        results['errors'].add('Error processing calibration image ${i + 1}: $e');
        results['imagesStatus']['calib_$i'] = false;
      }
    }

    return results;
  }

  void addEmployee(EmployeeModel employee) {
    _employeeDatabase[employee.id.toString()] = employee;
    print('✅ Added employee: ${employee.name} (ID: ${employee.id})');
  }

  void updateEmployee(EmployeeModel employee) {
    if (_employeeDatabase.containsKey(employee.id.toString())) {
      _employeeDatabase[employee.id.toString()] = employee;
      print('✅ Updated employee: ${employee.name}');
    }
  }

  void removeEmployee(String employeeId) {
    if (_employeeDatabase.containsKey(employeeId)) {
      final employee = _employeeDatabase[employeeId];
      _employeeDatabase.remove(employeeId);
      print('🗑️ Removed employee: ${employee?.name} (ID: $employeeId)');
    }
  }

  Map<String, dynamic> getDatabaseStats() {
    final employeeStats = <String, Map<String, dynamic>>{};

    for (final employee in _employeeDatabase.values) {
      final employeeId = employee.id.toString();

      employeeStats[employeeId] = {
        'name': employee.name,
        'profileImage': employee.profileImagePath,
        'calibrationImages': employee.calibrationImages.length,
        'totalImages': employee.calibrationImages.length + 1,
      };
    }

    return {
      'totalEmployees': _employeeDatabase.length,
      'totalImages': _employeeDatabase.values.fold(0, (sum, employee) => sum + employee.calibrationImages.length + 1),
      'employees': employeeStats,
    };
  }

  EmployeeModel? getEmployee(String employeeId) {
    return _employeeDatabase[employeeId];
  }

  List<EmployeeModel> getAllEmployees() {
    return _employeeDatabase.values.toList();
  }

  bool isEmployeeRegistered(String employeeId) {
    return _employeeDatabase.containsKey(employeeId);
  }

  bool _isFaceQualityGood(Face face) {
    final headEulerAngleY = face.headEulerAngleY ?? 0.0;
    if (headEulerAngleY.abs() > 20.0) {
      print('❌ Face angle too extreme: $headEulerAngleY');
      return false;
    }

    final boundingBox = face.boundingBox;
    final faceArea = boundingBox.width * boundingBox.height;
    if (faceArea < 10000) {
      print('❌ Face too small: $faceArea');
      return false;
    }

    if (face.landmarks.length < 5) {
      print('❌ Not enough landmarks: ${face.landmarks.length}');
      return false;
    }

    return true;
  }

  FaceSignature _extractFaceSignature(Face face) {
    final points = <Point>[];

    try {
      _addLandmarkIfExists(face, FaceLandmarkType.leftEye, points);
      _addLandmarkIfExists(face, FaceLandmarkType.rightEye, points);
      _addLandmarkIfExists(face, FaceLandmarkType.noseBase, points);
      _addLandmarkIfExists(face, FaceLandmarkType.leftMouth, points);
      _addLandmarkIfExists(face, FaceLandmarkType.rightMouth, points);
      _addLandmarkIfExists(face, FaceLandmarkType.leftCheek, points);
      _addLandmarkIfExists(face, FaceLandmarkType.rightCheek, points);
    } catch (e) {
      print('⚠️ Error extracting landmarks: $e');
    }

    if (points.length < 7) {
      throw Exception('Not enough landmarks detected: ${points.length}');
    }

    final vectors = _calculateFeatureVectors(points);

    final classifications = {
      'smile': face.smilingProbability ?? 0.0,
      'left_eye_open': face.leftEyeOpenProbability ?? 0.0,
      'right_eye_open': face.rightEyeOpenProbability ?? 0.0,
      'head_euler_y': (face.headEulerAngleY ?? 0.0).abs(),
      'head_euler_z': (face.headEulerAngleZ ?? 0.0).abs(),
    };

    return FaceSignature(
      points: points,
      vectors: vectors,
      classifications: classifications,
      boundingBox: face.boundingBox,
    );
  }

  void _addLandmarkIfExists(Face face, FaceLandmarkType type, List<Point> points) {
    try {
      final landmarks = face.landmarks;
      final landmark = landmarks[type];
      if (landmark != null) {
        points.add(landmark.position);
      }
        } catch (e) {
    }
  }

  List<double> _calculateFeatureVectors(List<Point> points) {
    final vectors = <double>[];

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final distance = _calculateDistance(points[i], points[j]);
        final normalizedDistance = distance / _getFaceSize(points);
        vectors.add(normalizedDistance);
      }
    }

    return vectors;
  }

  double _calculateDistance(Point p1, Point p2) {
    final dx = p1.x - p2.x;
    final dy = p1.y - p2.y;
    return sqrt(dx * dx + dy * dy);
  }

  double _getFaceSize(List<Point> points) {
    if (points.isEmpty) return 1.0;

    double maxDistance = 0.0;
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final distance = _calculateDistance(points[i], points[j]);
        if (distance > maxDistance) {
          maxDistance = distance;
        }
      }
    }

    return maxDistance > 0 ? maxDistance : 1.0;
  }

  double _calculateSignatureSimilarity(FaceSignature sig1, FaceSignature sig2) {
    if (sig1.points.length != sig2.points.length || sig1.points.length < 7) {
      return 0.0;
    }

    double vectorSimilarity = _calculateVectorSimilarity(sig1.vectors, sig2.vectors);
    double classificationSimilarity = _calculateClassificationSimilarity(
        sig1.classifications,
        sig2.classifications
    );

    final double similarity = (vectorSimilarity * 0.85) + (classificationSimilarity * 0.15);

    return similarity;
  }

  double _calculateVectorSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0.0;

    double cosineSimilarity = dotProduct / (sqrt(normA) * sqrt(normB));
    return cosineSimilarity.clamp(0.0, 1.0);
  }

  double _calculateClassificationSimilarity(
      Map<String, double> class1,
      Map<String, double> class2
      ) {
    double similarity = 0.0;
    int count = 0;

    class1.forEach((key, value1) {
      final value2 = class2[key] ?? 0.0;
      final diff = (value1 - value2).abs();

      if (key.contains('head_euler')) {
        if (diff < 5.0) {
          similarity += 1.0 - (diff / 10.0);
        }
      } else {
        if (diff < 0.2) {
          similarity += 1.0 - (diff * 4);
        }
      }
      count++;
    });

    return count > 0 ? similarity / count : 0.0;
  }

  void testRecognition() {
    print('🧪 Testing face recognition system...');
    final stats = getDatabaseStats();
    print('📊 Database Stats:');
    print('   Total Employees: ${stats['totalEmployees']}');
    print('   Total Images: ${stats['totalImages']}');

    if (stats['employees'] is Map) {
      final employees = stats['employees'] as Map;
      print('   Employees Details:');
      employees.forEach((id, details) {
        print('     - $id: ${details['name']} (${details['totalImages']} images)');
      });
    }
  }

  FaceRecognitionResult _handleSimilarMatches(
      String? bestMatchId,
      double bestSimilarity,
      String? secondBestId,
      double secondBestSimilarity,
      FaceSignature targetSignature,
      ) {
    if (bestMatchId == null || secondBestId == null) {
      return FaceRecognitionResult.notRecognized();
    }

    final employee1 = _employeeDatabase[bestMatchId];
    final employee2 = _employeeDatabase[secondBestId];

    if (employee1 == null || employee2 == null) {
      return FaceRecognitionResult.notRecognized();
    }

    print('🔍 Analyzing similar matches: ${employee1.name} vs ${employee2.name}');

    if (bestSimilarity > 0.95 && secondBestSimilarity < 0.90) {
      print('🎯 High confidence match: ${employee1.name} (${(bestSimilarity * 100).toStringAsFixed(1)}%)');
      return FaceRecognitionResult.recognized(bestMatchId, bestSimilarity);
    }

    if (bestSimilarity > 0.92 && (bestSimilarity - secondBestSimilarity).abs() < 0.02) {
      print('🎯 Accepting best match despite small difference: ${employee1.name}');
      return FaceRecognitionResult.recognized(bestMatchId, bestSimilarity);
    }

    if (bestSimilarity > 0.98) {
      print('🎯 Very high similarity: ${employee1.name} (${(bestSimilarity * 100).toStringAsFixed(1)}%)');
      return FaceRecognitionResult.recognized(bestMatchId, bestSimilarity);
    }

    print('❌ Cannot resolve ambiguity: ${employee1.name} (${(bestSimilarity * 100).toStringAsFixed(1)}%) vs '
        '${employee2.name} (${(secondBestSimilarity * 100).toStringAsFixed(1)}%)');

    return FaceRecognitionResult.notRecognized();
  }

  void clearDatabase() {
    _employeeDatabase.clear();
    print('🗑️ Cleared all employees from database');
  }

  int get registeredEmployeesCount => _employeeDatabase.length;

  void dispose() => _faceDetector.close();
}


