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
  final int _totalImages = 5;
  late CameraService _cameraService;
  bool _isCameraReady = false;
  bool _isUpdating = false;
  late FaceDetectionService _faceDetectionService;
  bool _isFaceDetected = false;

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

    print('\x1B[35m📋 Total images to capture: $_totalImages\x1B[0m');
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
          centerTitle: true,
          title: Text(
            _isUpdating
                ? 'Update Employee'
                : 'Add Employee',
          ),
        ),
        body: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              backgroundColor: Colors.grey,
              value: (_currentStep + 1) / _totalImages,
            ),
            const SizedBox(height: 20),

            // Step Title (Image Number)
            Text(
              'Image ${_currentStep + 1} from 5',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Camera Preview + Face Detection Overlay
            Expanded(
              child: Stack(
                children: [
                  _isCameraReady
                      ? CameraPreview(_cameraService.controller!)
                      : const Center(child: CircularProgressIndicator()),

                  if (_isCameraReady) _buildFaceDetectionOverlay(),
                ],
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
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

                  if (_isUpdating && _currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _skipStep,
                        child: const Text('Skip'),
                      ),
                    ),
                  if (_isUpdating && _currentStep > 0) const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCameraReady ? _captureImage : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _isUpdating ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _currentStep == _totalImages - 1
                            ? 'Finish'
                            : _isUpdating
                            ? 'Update'
                            : 'Capture',
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
      final imageFile = await _cameraService.takePicture();
      final imagePath = imageFile.path;

      print('📸 Image captured: $imagePath');

      setState(() {
        _isFaceDetected = false;
      });

      final faceDetectionResult =
      await _faceDetectionService.isFaceDetectedWithDetails(imagePath);

      setState(() {
        _isFaceDetected = faceDetectionResult['isValidFace'] ?? false;

      });

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

      print('✅ Face validation passed!');
      setState(() {
        if (_isUpdating && _capturedImages.length > _currentStep+1) {
          _capturedImages[_currentStep] = imagePath;
        } else {
          _capturedImages.add(imagePath);
        }

        print(
            '\x1B[32m📸 ${_isUpdating ? 'Updated' : 'Captured'} Image ${_currentStep + 1}: $imagePath\x1B[0m');

        if (_currentStep < _totalImages - 1) {
          _currentStep++;
          _resetFaceDetection();
          print('\x1B[36m➡️ Moving to step ${_currentStep + 1}\x1B[0m');
        } else {
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
    });
  }

  void _skipStep() {
    if (_currentStep < _totalImages - 1) {
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
      final updatedEmployee = widget.existingEmployee!.copyWith(
        name: widget.employeeName,
        profileImagePath: profileImage,
        calibrationImages: calibrationImages,
      );
      context.read<EmployeeCubit>().updateEmployee(updatedEmployee);
    } else {
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
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _onEmployeeUpdated() {
    print('\x1B[33m✅ Employee Updated Successfully!\x1B[0m');
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


  Widget _buildFaceDetectionOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 280,
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
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold)),
              ],
            )
                : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.face, size: 60, color: Colors.blue),
                SizedBox(height: 8),
                Text('SHOW YOUR FACE',
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold)),
              ],
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
