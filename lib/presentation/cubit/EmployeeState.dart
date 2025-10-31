import '../../data/models/EmployeeModel.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

abstract class EmployeeState {
  const EmployeeState();
}

class EmployeeInitial extends EmployeeState {}

class EmployeeLoading extends EmployeeState {}

class EmployeeLoaded extends EmployeeState {
  final List<EmployeeModel> employees;
  const EmployeeLoaded(this.employees);
}

class EmployeeAdded extends EmployeeState {
  final int employeeId;
  const EmployeeAdded(this.employeeId);
}

class EmployeeError extends EmployeeState {
  final String message;
  const EmployeeError(this.message);
}

class CameraReady extends EmployeeState {}

class FaceValid extends EmployeeState {
  final String imagePath;
  const FaceValid(this.imagePath);
}

class FaceInvalid extends EmployeeState {
  final String message;
  const FaceInvalid(this.message);
}

class FaceValidFromStream extends EmployeeState {
  final InputImage frame;
  const FaceValidFromStream(this.frame);
}
