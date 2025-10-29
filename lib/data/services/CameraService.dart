import 'package:camera/camera.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CameraService {
  CameraController? _controller;
  CameraController? get controller => _controller;

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();

    // البحث عن الكاميرا الأمامية
    final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first, // إذا مفيش كاميرا أمامية نستخدم الأولى
    );

    _controller = CameraController(
      frontCamera, // استخدام الكاميرا الأمامية
      ResolutionPreset.medium,
    );

    await _controller!.initialize();
  }

  Future<File> takePicture() async {
    final XFile file = await _controller!.takePicture();
    return File(file.path);
  }

  void dispose() {
    _controller?.dispose();
  }
}