import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/EmployeeModel.dart';
import '../../data/repository/EmployeeRepository.dart';
import 'EmployeeState.dart';


class EmployeeCubit extends Cubit<EmployeeState> {
  final EmployeeRepository _repository;

  EmployeeCubit(this._repository) : super(EmployeeInitial());

  // إضافة موظف جديد
  Future<void> addEmployee(EmployeeModel employee) async {
    emit(EmployeeLoading());
    try {
      final employeeId = await _repository.addEmployee(employee);
      emit(EmployeeAdded(employeeId));
    } catch (e) {
      emit(EmployeeError('Failed to add employee: $e'));
    }
  }

  // جلب كل الموظفين
  Future<void> loadEmployees() async {
    emit(EmployeeLoading());
    try {
      final employees = await _repository.getAllEmployees();
      emit(EmployeeLoaded(employees));
    } catch (e) {
      emit(EmployeeError('Failed to load employees: $e'));
    }
  }

  // حذف موظف
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

  // تحديث بيانات الموظف
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

  // جلب موظف بالـ ID
  Future<EmployeeModel?> getEmployeeById(int id) async {
    try {
      return await _repository.getEmployeeById(id);
    } catch (e) {
      print('Error getting employee by ID: $e');
      return null;
    }
  }
}