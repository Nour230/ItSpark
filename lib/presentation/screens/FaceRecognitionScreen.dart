import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../data/services/CameraService.dart';
import '../../data/services/FaceDetectionService.dart';
import '../../data/services/RealFaceRecognitionService.dart';
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
  late FaceDetectionService _faceDetectionService;
  late RealFaceRecognitionService _faceRecognitionService;

  bool _isCameraReady = false;
  bool _isRecognizing = false;
  String _statusMessage = 'Initializing camera...';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _cameraService = CameraService();
      _faceDetectionService = FaceDetectionService();
      _faceRecognitionService = RealFaceRecognitionService();

      await _cameraService.initializeCamera((frame) {
      });

      setState(() {
        _isCameraReady = true;
        _statusMessage = 'Ready - Show your face';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Initialization error: $e';
      });
    }
  }

  Future<void> _recognizeFace() async {
    if (!_isCameraReady || _isRecognizing) return;

    setState(() {
      _isRecognizing = true;
      _statusMessage = 'Capturing image...';
    });

    try {
      final imageFile = await _cameraService.takePicture();
      final capturedImagePath = imageFile.path;

      final inputImage = InputImage.fromFilePath(capturedImagePath);

      final detectionResult = await _faceDetectionService.isFaceDetected(inputImage);
      if (!detectionResult['isValidFace']) {
        setState(() {
          _statusMessage = '❌ ${detectionResult['message']}';
          _isRecognizing = false;
        });
        return;
      }

      final Face capturedFace = detectionResult['face'];

      await context.read<EmployeeCubit>().loadEmployees();
      final state = context.read<EmployeeCubit>().state;

      if (state is! EmployeeLoaded || state.employees.isEmpty) {
        setState(() {
          _statusMessage = '❌ No employees in database';
          _isRecognizing = false;
        });
        return;
      }

      final employees = state.employees;
      setState(() {
        _statusMessage = '🔍 Comparing with ${employees.length} employees...';
      });

      EmployeeModel? recognizedEmployee;
      double highestSimilarity = 0.0;

      for (final employee in employees) {
        try {
          final employeeInputImage = InputImage.fromFilePath(employee.profileImagePath);
          final employeeDetection = await _faceDetectionService.isFaceDetected(employeeInputImage);

          if (!employeeDetection['isValidFace']) continue;

          final Face employeeFace = employeeDetection['face'];

          final similarity = await _faceRecognitionService.compareFaces(capturedFace, employeeFace);
          if (similarity > highestSimilarity) {
            highestSimilarity = similarity;
            recognizedEmployee = employee;
          }
        } catch (e) {
          print('Error comparing with ${employee.name}: $e');
        }
      }

      if (recognizedEmployee != null && highestSimilarity > 0.6) {
        setState(() {
          _statusMessage = '✅ Employee recognized: ${recognizedEmployee?.name}';
        });

        _showEmployeePopup(recognizedEmployee);

      } else {
        setState(() {
          _statusMessage = '❌ Employee not found';
        });

        await Future.delayed(const Duration(seconds: 4));
        if (mounted) {
          setState(() {
            _statusMessage = 'Ready - Show your face';
          });
        }
      }

    } catch (e) {
      setState(() {
        _statusMessage = '❌ Recognition error: $e';
      });
    } finally {
      setState(() {
        _isRecognizing = false;
      });
    }
  }

  void _showEmployeePopup(EmployeeModel employee) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.verified, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text('Employee Recognized'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 3),
                  image: DecorationImage(
                    image: FileImage(File(employee.profileImagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('ID', employee.id.toString()),
                    _buildInfoRow('Name', employee.name),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'This popup will close automatically',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _statusMessage = 'Ready - Show your face';
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatusColor(),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _statusMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: _isCameraReady
                ? CameraPreview(_cameraService.controller!)
                : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _recognizeFace,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Recognize Face'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _faceDetectionService.dispose();
    super.dispose();
  }
}