
import '../local/EmployeeDatabaseService.dart';
import '../models/EmployeeModel.dart';
import 'EmployeeRepository.dart';

class EmployeeRepositoryImpl implements EmployeeRepository {
   final EmployeeDatabaseService _databaseService;

  EmployeeRepositoryImpl({EmployeeDatabaseService? databaseService})
      : _databaseService = databaseService ?? EmployeeDatabaseService();
  @override
  Future<int> addEmployee(EmployeeModel employee) async {
    return await _databaseService.insertEmployee(employee);
  }

  @override
  Future<List<EmployeeModel>> getAllEmployees() async {
    return await _databaseService.getAllEmployees();
  }

  @override
  Future<EmployeeModel?> getEmployeeById(int id) async {
    return await _databaseService.getEmployeeById(id);
  }

  @override
  Future<int> updateEmployee(EmployeeModel employee) async {
    return await _databaseService.updateEmployee(employee);
  }

  @override
  Future<int> deleteEmployee(int id) async {
    return await _databaseService.deleteEmployee(id);
  }
}