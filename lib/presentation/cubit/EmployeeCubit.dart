import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/EmployeeModel.dart';
import '../../data/repository/EmployeeRepository.dart';
import '../../data/services/CameraService.dart';
import '../../data/services/FaceDetectionService.dart';
import 'EmployeeState.dart';

class EmployeeCubit extends Cubit<EmployeeState> {
  final EmployeeRepository _repository;
  final CameraService _cameraService;
  final FaceDetectionService _faceDetectionService;

  EmployeeCubit(
      this._repository,
      this._cameraService,
      this._faceDetectionService,
      ) : super(EmployeeInitial());

  Future<void> initializeCamera() async {
    emit(EmployeeLoading());
    try {
      await _cameraService.initializeCamera();
      emit(CameraReady());
    } catch (e) {
      emit(EmployeeError('Camera initialization failed: $e'));
    }
  }


  // ✅ التقاط صورة + كشف الوجه
  Future<void> captureFaceImage({required bool isUpdate}) async {
    emit(EmployeeLoading());
    try {
      final imageFile = await _cameraService.takePicture();
      final imagePath = imageFile.path;

      final result = await _faceDetectionService.isFaceDetectedWithDetails(imagePath);
      final isValidFace = result['isValidFace'] ?? false;
      final message = result['message'] ?? 'No face detected';

      if (isValidFace) {
        emit(FaceValid(imagePath));
      } else {
        emit(FaceInvalid(message));
      }
    } catch (e) {
      emit(EmployeeError('Face capture failed: $e'));
    }
  }

  void disposeCamera() {
    try {
      _cameraService.dispose();
    } catch (_) {}
  }

  // ✅ Getter لاستخدام الكاميرا في الواجهة
  CameraService get cameraService => _cameraService;

  // ✅ إضافة موظف جديد
  Future<void> addEmployee(EmployeeModel employee) async {
    emit(EmployeeLoading());
    try {
      final employeeId = await _repository.addEmployee(employee);
      emit(EmployeeAdded(employeeId));
    } catch (e) {
      emit(EmployeeError('Failed to add employee: $e'));
    }
  }

  // ✅ تحميل كل الموظفين
  Future<void> loadEmployees() async {
    emit(EmployeeLoading());
    try {
      final employees = await _repository.getAllEmployees();
      emit(EmployeeLoaded(employees));
    } catch (e) {
      emit(EmployeeError('Failed to load employees: $e'));
    }
  }

  // ✅ حذف موظف
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

  // ✅ تحديث بيانات موظف
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

  // ✅ جلب موظف حسب الـ ID
  Future<EmployeeModel?> getEmployeeById(int id) async {
    try {
      return await _repository.getEmployeeById(id);
    } catch (e) {
      print('Error getting employee by ID: $e');
      return null;
    }
  }
}
