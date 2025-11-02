import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/EmployeeModel.dart';
import '../../data/repository/EmployeeRepository.dart';
import '../../data/services/CameraService.dart';
import '../../data/services/FaceDetectionService.dart';
import 'EmployeeState.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class EmployeeCubit extends Cubit<EmployeeState> {
  final EmployeeRepository _repository;
  final CameraService _cameraService;
  final FaceDetectionService _faceDetectionService;

  Timer? _timer;
  InputImage? _lastFrame;

  EmployeeCubit(
      this._repository,
      this._cameraService,
      this._faceDetectionService,
      ) : super(EmployeeInitial());

  Future<void> initializeCamera() async {
    emit(EmployeeLoading());
    try {
      await _cameraService.initializeCamera((frame) {
        _lastFrame = frame;
      });
      emit(CameraReady());
    } catch (e) {
      emit(EmployeeError('Camera initialization failed: $e'));
    }
  }

  void startFaceRecognition() {
    _timer = Timer.periodic(Duration(seconds: 5), (_) async {
      if (_lastFrame != null) {
        await _processFrame(_lastFrame!);
      }
    });
  }

  Future<void> _processFrame(InputImage frame) async {
    try {
      final result = await _faceDetectionService.isFaceDetected(frame);
      final isValidFace = result['isValidFace'] ?? false;

      if (isValidFace) {
        emit(FaceValidFromStream(frame));
      }
    } catch (e) {
      print('Face recognition error: $e');
    }
  }

  void stopFaceRecognition() {
    _timer?.cancel();
    _timer = null;
  }

  void disposeCamera() {
    stopFaceRecognition();
    try {
      _cameraService.dispose();
    } catch (_) {}
  }

  CameraService get cameraService => _cameraService;

  Future<void> addEmployee(EmployeeModel employee) async {
    emit(EmployeeLoading());
    try {
      final employees = await _repository.getAllEmployees();
      emit(EmployeeLoaded(employees));
    } catch (e) {
      emit(EmployeeError('Failed to add employee: $e'));
    }
  }

  Future<void> loadEmployees() async {
    emit(EmployeeLoading());
    try {
      final employees = await _repository.getAllEmployees();
      emit(EmployeeLoaded(employees));
    } catch (e) {
      emit(EmployeeError('Failed to load employees: $e'));
    }
  }

  Future<void> deleteEmployee(int id) async {
    emit(EmployeeLoading());
    try {
      await _repository.deleteEmployee(id);
      final employees = await _repository.getAllEmployees();
      emit(EmployeeLoaded(employees));
    } catch (e) {
      emit(EmployeeError('Failed to delete employee: $e'));
    }
  }

  Future<void> updateEmployee(EmployeeModel employee) async {
    emit(EmployeeLoading());
    try {
      await _repository.updateEmployee(employee);
      final employees = await _repository.getAllEmployees();
      emit(EmployeeLoaded(employees));
    } catch (e) {
      emit(EmployeeError('Failed to update employee: $e'));
    }
  }

  Future<EmployeeModel?> getEmployeeById(int id) async {
    try {
      return await _repository.getEmployeeById(id);
    } catch (e) {
      print('Error getting employee by ID: $e');
      return null;
    }
  }
}
