import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';

import '../../data/models/EmployeeModel.dart';
import '../../data/services/CameraService.dart';
import '../../data/services/FaceDetectionService.dart';
import '../cubit/EmployeeCubit.dart';
import '../cubit/EmployeeState.dart';

class FaceCaptureScreen extends StatefulWidget {
  final String employeeName;
  final EmployeeModel? existingEmployee;

  const FaceCaptureScreen({
    super.key,
    required this.employeeName,
    this.existingEmployee,
  });

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  int _currentStep = 0;
  final List<String> _capturedImages = [];
  late CameraService _cameraService;
  bool _isCameraReady = false;
  bool _isUpdating = false;
  late FaceDetectionService _faceDetectionService;
  bool _isFaceDetected = false;
  String _faceDetectionMessage = 'Position your face in the frame';

  final List<String> _stepTitles = [
    'Profile Picture',
    'Recognition Image 1',
    'Recognition Image 2',
    'Recognition Image 3',
    'Recognition Image 4',
  ];

  @override
  void initState() {
    super.initState();
    _isUpdating = widget.existingEmployee != null;
    _initializeCamera();

    if (_isUpdating) {
      _capturedImages.add(widget.existingEmployee!.profileImagePath);
      _capturedImages.addAll(widget.existingEmployee!.calibrationImages);
      print('\x1B[35m🔄 Update Mode - Starting with ${_capturedImages.length} existing images\x1B[0m');
    } else {
      print('\x1B[35m➕ Add Mode - Starting fresh\x1B[0m');
    }

    print('\x1B[35m📋 Total steps: ${_stepTitles.length}\x1B[0m');
  }

  Future<void> _initializeCamera() async {
    _cameraService = CameraService();
    _faceDetectionService = FaceDetectionService();

    await _cameraService.initializeCamera();
    setState(() {
      _isCameraReady = true;
    });

    print('✅ FREE Google ML Kit Face Detection Ready');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmployeeCubit, EmployeeState>(
      listener: (context, state) {
        if (state is EmployeeAdded) {
          _onEmployeeAdded(state.employeeId);
        } else if (state is EmployeeLoaded) {
          if (_isUpdating) {
            _onEmployeeUpdated();
          }
        } else if (state is EmployeeError) {
          _onEmployeeError(state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              _isUpdating
                  ? 'Update Images - ${widget.employeeName}'
                  : 'Capture Images - ${widget.employeeName}'
          ),
        ),
        body: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / _stepTitles.length,
            ),
            const SizedBox(height: 20),

            // Step Title
            Text(
              _stepTitles[_currentStep],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Face Detection Indicator
            _buildFaceDetectionIndicator(),
            const SizedBox(height: 10),

            // Mode Indicator
            Text(
              _isUpdating ? 'UPDATE MODE' : 'ADD MODE',
              style: TextStyle(
                color: _isUpdating ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Front Camera Indicator
            const Text(
              'Front Camera',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Camera Preview مع Face Detection Overlay
            Expanded(
              child: Stack(
                children: [
                  _isCameraReady
                      ? CameraPreview(_cameraService.controller!)
                      : const Center(child: CircularProgressIndicator()),

                  // Face Detection Overlay
                  if (_isCameraReady)
                    _buildFaceDetectionOverlay(),
                ],
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Previous Button
                  if (_currentStep > 0)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _previousStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 10),

                  // Skip Button (للتحديث فقط)
                  if (_isUpdating && _currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _skipStep,
                        child: const Text('Skip'),
                      ),
                    ),
                  if (_isUpdating && _currentStep > 0) const SizedBox(width: 10),

                  // Capture/Update Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isCameraReady && _capturedImages.length <= _stepTitles.length) ? _captureImage : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isUpdating ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                          _currentStep == _stepTitles.length - 1 ? 'Finish' :
                          _isUpdating ? 'Update' : 'Capture'
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _captureImage() async {
    try {
      // 1. أخذ الصورة من الكاميرا
      final imageFile = await _cameraService.takePicture();
      final imagePath = imageFile.path;

      print('📸 Image captured: $imagePath');

      // 2. الكشف عن الوجوه في الصورة مع الشروط المتقدمة
      setState(() {
        _isFaceDetected = false;
        _faceDetectionMessage = 'Analyzing face...';
      });

      final faceDetectionResult = await _faceDetectionService.isFaceDetectedWithDetails(imagePath);

      setState(() {
        _isFaceDetected = faceDetectionResult['isValidFace'] ?? false;
        _faceDetectionMessage = faceDetectionResult['message'] ?? 'Face analysis failed';
      });

      // 3. إذا الوجه غير صالح، نمنع الحفظ
      if (!_isFaceDetected) {
        print('❌ Face validation failed: ${faceDetectionResult['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${faceDetectionResult['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // 4. إذا الوجه صالح، نخزن الصورة
      print('✅ Face validation passed!');
      setState(() {
        if (_isUpdating && _capturedImages.length > _currentStep) {
          _capturedImages[_currentStep] = imagePath;
        } else {
          _capturedImages.add(imagePath);
        }

        print('\x1B[32m📸 ${_isUpdating ? 'Updated' : 'Captured'} Image ${_currentStep + 1}: $imagePath\x1B[0m');

        // التقدم للخطوة التالية
        if (_currentStep < _stepTitles.length - 1) {
          _currentStep++;
          _resetFaceDetection();
          print('\x1B[36m➡️ Moving to step ${_currentStep + 1}\x1B[0m');
        } else {
          // إذا وصلنا للخطوة الخامسة، نحفظ البيانات
          print('\x1B[33m🎯 Reached final step - Saving data...\x1B[0m');
          _saveEmployeeData();
        }
      });

    } catch (e) {
      print('❌ Error in capture process: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetFaceDetection() {
    setState(() {
      _isFaceDetected = false;
      _faceDetectionMessage = 'Position your face in the frame';
    });
  }

  void _skipStep() {
    if (_currentStep < _stepTitles.length - 1) {
      setState(() {
        _currentStep++;
        _resetFaceDetection();
      });
    } else {
      _saveEmployeeData();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _resetFaceDetection();
      });
    }
  }

  void _saveEmployeeData() {
    final profileImage = _capturedImages[0];
    final calibrationImages = _capturedImages.sublist(1);

    print('\x1B[36m🔢 Total Images: ${_capturedImages.length}\x1B[0m');
    print('\x1B[36m🖼️ Profile: $profileImage\x1B[0m');
    print('\x1B[36m📸 Calibration: $calibrationImages\x1B[0m');

    if (_isUpdating) {
      // تحديث الموظف الموجود
      final updatedEmployee = widget.existingEmployee!.copyWith(
        name: widget.employeeName,
        profileImagePath: profileImage,
        calibrationImages: calibrationImages,
      );
      context.read<EmployeeCubit>().updateEmployee(updatedEmployee);
    } else {
      // إضافة موظف جديد
      final newEmployee = EmployeeModel(
        name: widget.employeeName,
        profileImagePath: profileImage,
        calibrationImages: calibrationImages,
      );
      context.read<EmployeeCubit>().addEmployee(newEmployee);
    }
  }

  void _onEmployeeAdded(int employeeId) {
    print('\x1B[32m✅ Employee Added Successfully! ID: $employeeId\x1B[0m');
    print('\x1B[32m👤 Name: ${widget.employeeName}\x1B[0m');
    print('\x1B[32m📊 Total Images: ${_capturedImages.length}\x1B[0m');

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _onEmployeeUpdated() {
    print('\x1B[33m✅ Employee Updated Successfully!\x1B[0m');
    print('\x1B[33m👤 Name: ${widget.employeeName}\x1B[0m');
    print('\x1B[33m📊 Total Images: ${_capturedImages.length}\x1B[0m');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Employee images updated successfully')),
    );

    Navigator.pop(context, true);
  }

  void _onEmployeeError(String message) {
    print('\x1B[31m❌ Error: $message\x1B[0m');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $message')),
    );
  }

  Widget _buildFaceDetectionIndicator() {
    Color statusColor;
    IconData statusIcon;

    if (_isFaceDetected) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (_faceDetectionMessage.contains('Analyzing')) {
      statusColor = Colors.blue;
      statusIcon = Icons.autorenew;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _faceDetectionMessage,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceDetectionOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // إطار مرن أكبر
          Container(
            width: 280, // إطار أكبر
            height: 350,
            decoration: BoxDecoration(
              border: Border.all(
                color: _isFaceDetected ? Colors.green : Colors.blue,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _isFaceDetected
                ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.face, size: 60, color: Colors.green),
                SizedBox(height: 8),
                Text('FACE DETECTED',
                    style: TextStyle(color: Colors.green,
                        fontWeight: FontWeight.bold)),
              ],
            )
                : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.face, size: 60, color: Colors.blue),
                SizedBox(height: 8),
                Text('SHOW YOUR FACE',
                    style: TextStyle(color: Colors.blue,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // تعليمات مرنة
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Position your face anywhere in frame\nMake sure eyes are open and visible',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}