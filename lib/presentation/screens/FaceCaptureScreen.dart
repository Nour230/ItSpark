import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

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
  late FaceDetectionService _faceDetectionService;
  bool _isCameraReady = false;
  bool _isFaceDetected = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _isUpdating = widget.existingEmployee != null;
    _initializeCamera();

    if (_isUpdating) {
      _capturedImages.add(widget.existingEmployee!.profileImagePath);
      _capturedImages.addAll(widget.existingEmployee!.calibrationImages);
    }
  }

  Future<void> _initializeCamera() async {
    _cameraService = CameraService();
    _faceDetectionService = FaceDetectionService();

    await _cameraService.initializeCamera((_) {});

    setState(() {
      _isCameraReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmployeeCubit, EmployeeState>(
      listener: (context, state) {
        if (state is EmployeeLoaded) {
          // ✅ تم تحميل البيانات بنجاح، العودة للشاشة الرئيسية
          Navigator.popUntil(context, (route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isUpdating ?
            'Employee updated successfully' :
            'Employee added successfully')),
          );
        } else if (state is EmployeeError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.message}')),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(_isUpdating ? 'Update Employee' : 'Add Employee'),
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              backgroundColor: Colors.grey[300],
              value: (_currentStep + 1) / _totalImages,
            ),
            const SizedBox(height: 16),
            Text(
              'Image ${_currentStep + 1} of $_totalImages',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Stack(
                children: [
                  _isCameraReady
                      ? CameraPreview(_cameraService.controller!)
                      : const Center(child: CircularProgressIndicator()),
                  _buildFaceDetectionOverlay(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _previousStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                        child: const Text('Previous',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCameraReady ? _captureImage : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isUpdating ? Colors.black : Colors.green,
                      ),
                      child: Text(
                        _currentStep == _totalImages - 1
                            ? 'Finish'
                            : _isUpdating
                            ? 'Update'
                            : 'Capture',
                        style: const TextStyle(color: Colors.white),
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

  Widget _buildFaceDetectionOverlay() {
    return Center(
      child: Container(
        width: 280,
        height: 350,
        decoration: BoxDecoration(
          border: Border.all(
            color: _isFaceDetected ? Colors.green : Colors.blue,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(
            Icons.face,
            size: 60,
            color: _isFaceDetected ? Colors.green : Colors.blue,
          ),
        ),
      ),
    );
  }

  void _captureImage() async {
    try {
      final imageFile = await _cameraService.takePicture();
      final imagePath = imageFile.path;

      final inputImage = InputImage.fromFilePath(imagePath);
      final faceDetectionResult = await _faceDetectionService.isFaceDetected(inputImage);

      setState(() {
        _isFaceDetected = faceDetectionResult['isValidFace'] ?? false;
      });

      if (!_isFaceDetected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${faceDetectionResult['message']}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_isUpdating && _capturedImages.length > _currentStep) {
        _capturedImages[_currentStep] = imagePath;
      } else {
        _capturedImages.add(imagePath);
      }

      if (_currentStep < _totalImages - 1) {
        setState(() {
          _currentStep++;
          _isFaceDetected = false;
        });
      } else {
        _saveEmployeeData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _isFaceDetected = false;
      });
    }
  }

  void _saveEmployeeData() {
    final profileImage = _capturedImages[0];
    final calibrationImages = _capturedImages.sublist(1);

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
      context.read<EmployeeCubit>().addEmployee(newEmployee).then((_) {
        // ✅ إعادة تحميل قائمة الموظفين بعد الإضافة
        context.read<EmployeeCubit>().loadEmployees();
      });
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}
