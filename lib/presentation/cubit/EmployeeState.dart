import '../../data/models/EmployeeModel.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Base abstract state
abstract class EmployeeState {
  const EmployeeState();
}

/// Initial state (default)
class EmployeeInitial extends EmployeeState {}

/// Loading state (for long operations)
class EmployeeLoading extends EmployeeState {}

/// Loaded list of employees
class EmployeeLoaded extends EmployeeState {
  final List<EmployeeModel> employees;
  const EmployeeLoaded(this.employees);
}

/// Employee successfully added
class EmployeeAdded extends EmployeeState {
  final int employeeId;
  const EmployeeAdded(this.employeeId);
}

/// Generic error state
class EmployeeError extends EmployeeState {
  final String message;
  const EmployeeError(this.message);
}

/// ✅ Camera initialized successfully
class CameraReady extends EmployeeState {}

/// ✅ Face successfully detected and valid
class FaceValid extends EmployeeState {
  final String imagePath;
  const FaceValid(this.imagePath);
}

/// ❌ Face detection failed or invalid
class FaceInvalid extends EmployeeState {
  final String message;
  const FaceInvalid(this.message);
}

/// 🔹 حالة جديدة: Face detected from streaming frame
class FaceValidFromStream extends EmployeeState {
  final InputImage frame;
  const FaceValidFromStream(this.frame);
}
