
import '../models/EmployeeModel.dart';

abstract class EmployeeRepository {
  Future<int> addEmployee(EmployeeModel employee);
  Future<List<EmployeeModel>> getAllEmployees();
  Future<EmployeeModel?> getEmployeeById(int id);
  Future<int> updateEmployee(EmployeeModel employee);
  Future<int> deleteEmployee(int id);
}