import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../data/services/CameraService.dart';
import '../../data/services/FaceDetectionService.dart';
import '../../data/services/SmartFaceRecognitionService.dart';
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
  late SmartFaceRecognitionService _faceRecognitionService;

  bool _isCameraReady = false;
  bool _isRecognizing = false;
  String _statusMessage = 'Initializing camera...';
  bool _isDatabaseLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _cameraService = CameraService();
      _faceDetectionService = FaceDetectionService();
      _faceRecognitionService = SmartFaceRecognitionService();

      await _cameraService.initializeCamera((frame) {
      });

      await _loadAndRegisterEmployees();

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

  Future<void> _loadAndRegisterEmployees() async {
    try {
      setState(() {
        _statusMessage = '📦 Loading employees database...';
      });

      await context.read<EmployeeCubit>().loadEmployees();
      final state = context.read<EmployeeCubit>().state;

      if (state is! EmployeeLoaded || state.employees.isEmpty) {
        setState(() {
          _statusMessage = '❌ No employees in database';
        });
        return;
      }

      final employees = state.employees;

      _faceRecognitionService.loadEmployees(employees);

      int validEmployees = 0;
      for (final employee in employees) {
        final validationResult = await _faceRecognitionService.validateEmployeeImages(employee);
        if (validationResult['isValid']) {
          validEmployees++;
          print('✅ Valid employee: ${employee.name}');
        } else {
          print('❌ Invalid employee: ${employee.name} - ${validationResult['errors']}');
        }
      }

      setState(() {
        _isDatabaseLoaded = validEmployees > 0;
        _statusMessage = '✅ Loaded $validEmployees/${employees.length} valid employees';
      });

      final stats = _faceRecognitionService.getDatabaseStats();
      print('🎯 Database Stats: $stats');

    } catch (e) {
      setState(() {
        _statusMessage = '❌ Database loading error: $e';
      });
    }
  }

  Future<void> _recognizeFace() async {
    if (!_isCameraReady || _isRecognizing || !_isDatabaseLoaded) return;

    setState(() {
      _isRecognizing = true;
      _statusMessage = 'Capturing image...';
    });

    try {
      final imageFile = await _cameraService.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);

      setState(() {
        _statusMessage = '🔍 Recognizing face...';
      });

      final recognitionResult = await _faceRecognitionService.processFace(inputImage);

      if (recognitionResult.isRecognized) {
        final employeeId = recognitionResult.userId;
        final confidence = recognitionResult.confidence ?? 0.0;

        await context.read<EmployeeCubit>().loadEmployees();
        final state = context.read<EmployeeCubit>().state;

        if (state is EmployeeLoaded) {
          final employee = state.employees.firstWhere(
                (emp) => emp.id.toString() == employeeId,
            orElse: () => EmployeeModel(id: -1, name: 'Unknown', profileImagePath: '', calibrationImages: []),
          );

          if (employee.id != -1) {
            setState(() {
              _statusMessage = '✅ Recognized: ${employee.name} (${(confidence * 100).toStringAsFixed(1)}%)';
            });

            _showEmployeePopup(employee, confidence);
          } else {
            setState(() {
              _statusMessage = '❌ Employee data not found';
            });
          }
        }
      } else {
        setState(() {
          _statusMessage = '❌ ${recognitionResult.message}';
        });

        await Future.delayed(const Duration(seconds: 3));
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

  void _showEmployeePopup(EmployeeModel employee, double confidence) {
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(confidence),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.red;
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
    if (_statusMessage.contains('🔍')) return Colors.orange;
    if (_statusMessage.contains('📦')) return Colors.purple;
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
            child: Column(
              children: [
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_isDatabaseLoaded)
                  Text(
                    '${_faceRecognitionService.registeredEmployeesCount} employees in database',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
              ],
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
              onPressed: _isDatabaseLoaded ? _recognizeFace : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isDatabaseLoaded ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isRecognizing
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Recognizing...'),
                ],
              )
                  : const Text('Recognize Face'),
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
    _faceRecognitionService.dispose();
    super.dispose();
  }
}