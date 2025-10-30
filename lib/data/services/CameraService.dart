import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraService {
  CameraController? _controller;
  CameraController? get controller => _controller;

  Future<void> initializeCamera(Function(InputImage inputImage) onFrame) async {
    final cameras = await availableCameras();

    final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();

    _controller!.startImageStream((CameraImage image) async {
      try {
        final WriteBuffer allBytes = WriteBuffer();
        for (final plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        final inputImage = _convertCameraImage(image, bytes);
        if (inputImage != null) onFrame(inputImage);

      } catch (e) {
        print("⚠️ Error processing camera frame: $e");
      }
    });
  }

  InputImage? _convertCameraImage(CameraImage image, Uint8List bytes) {
    if (_controller == null) return null;

    final rotation = InputImageRotation.rotation0deg;

    final metadata = InputImageMetadata(
      size: ui.Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: metadata,
    );
  }

  Future<XFile> takePicture() async {
    if (_controller == null) throw Exception('Camera not initialized');
    return await _controller!.takePicture();
  }

  void dispose() {
    _controller?.dispose();
  }
}
