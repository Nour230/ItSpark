import '../../data/models/EmployeeModel.dart';

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