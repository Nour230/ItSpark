import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/CameraService.dart';
import '../../data/services/FaceDetectionService.dart';
import '../../data/services/RealFaceRecognitionService.dart'; // ⬅️ غيرت هنا
import '../cubit/EmployeeCubit.dart';
import '../../data/models/EmployeeModel.dart';
import '../cubit/EmployeeState.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  late CameraService _cameraService;
  bool _isCameraReady = false;
  String _statusMessage = 'Initializing camera...';
  late RealFaceRecognitionService _faceRecognitionService; // ⬅️ غيرت هنا
  bool _isModelLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // 1. Initialize Camera
      _cameraService = CameraService();
      await _cameraService.initializeCamera();

      // 2. Initialize Face Recognition Service
      _faceRecognitionService = RealFaceRecognitionService(); // ⬅️ غيرت هنا
      await _faceRecognitionService.loadModel(); // ⬅️ فكيت التعليق

      setState(() {
        _isCameraReady = true;
        _isModelLoaded = true;
        _statusMessage = 'Ready for recognition - Show your face';
      });

    } catch (e) {
      setState(() {
        _statusMessage = 'Initialization error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition'),
      ),
      body: Column(
        children: [
          // Status Message
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Camera Preview
          Expanded(
            child: _isCameraReady
                ? CameraPreview(_cameraService.controller!)
                : Center(child: CircularProgressIndicator()),
          ),

          // Recognize Button
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isCameraReady ? _recognizeFace : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Recognize Face'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_statusMessage.contains('❌')) return Colors.red;
    if (_statusMessage.contains('✅')) return Colors.green;
    return Colors.blue;
  }

  void _recognizeFace() async {
    if (!_isModelLoaded) {
      setState(() {
        _statusMessage = '❌ Face recognition model not loaded';
      });
      return;
    }

    setState(() {
      _statusMessage = 'Capturing image...';
    });

    try {
      // 1. Capture image
      final imageFile = await _cameraService.takePicture();
      final capturedImagePath = imageFile.path;

      setState(() {
        _statusMessage = 'Detecting face...';
      });

      // 2. Face detection
      final faceDetectionService = FaceDetectionService();
      final detectionResult = await faceDetectionService.isFaceDetectedWithDetails(capturedImagePath);

      if (!detectionResult['isValidFace']) {
        setState(() {
          _statusMessage = '❌ ${detectionResult['message']}';
        });
        return;
      }

      setState(() {
        _statusMessage = '✅ Face detected! Searching employees...';
      });

      // 3. Get all employees for comparison
      await context.read<EmployeeCubit>().loadEmployees();
      final state = context.read<EmployeeCubit>().state;
      List<EmployeeModel> employees = [];

      if (state is EmployeeLoaded) {
        employees = state.employees;
      } else {
        setState(() {
          _statusMessage = '❌ Error loading employees';
        });
        return;
      }

      if (employees.isEmpty) {
        setState(() {
          _statusMessage = '❌ No employees in database';
        });
        return;
      }

      setState(() {
        _statusMessage = '🔍 Comparing with ${employees.length} employees...';
      });

      // 4. Compare with each employee using Face Recognition
      EmployeeModel? recognizedEmployee;
      double highestSimilarity = 0.0;

      for (final employee in employees) {
        setState(() {
          _statusMessage = '🔍 Checking: ${employee.name}...';
        });

        try {
          // Compare with employee's profile image first - ⬅️ فكيت التعليق
          final similarity = await _faceRecognitionService.compareFaces(
              capturedImagePath,
              employee.profileImagePath
          );

          print('Similarity with ${employee.name}: $similarity');

          // If high similarity, we found our employee - ⬅️ فكيت التعليق
          if (similarity > highestSimilarity) {
            highestSimilarity = similarity;
            recognizedEmployee = employee;
          }
        } catch (e) {
          print('Error comparing with ${employee.name}: $e');
        }
      }

      // 5. Show result based on similarity threshold
      if (recognizedEmployee != null && highestSimilarity > 0.6) {
        setState(() {
          _statusMessage = '✅ Employee found: ${recognizedEmployee?.name} (${(highestSimilarity * 100).toStringAsFixed(1)}% match)';
        });

        // هنا في الخطوة الجاية هنضيف الانتقال لشاشة التفاصيل

      } else {
        setState(() {
          _statusMessage = '❌ Employee not found. Best match: ${(highestSimilarity * 100).toStringAsFixed(1)}%';
        });
      }

    } catch (e) {
      setState(() {
        _statusMessage = '❌ Recognition error: $e';
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _faceRecognitionService.dispose(); // ⬅️ فكيت التعليق
    super.dispose();
  }
}