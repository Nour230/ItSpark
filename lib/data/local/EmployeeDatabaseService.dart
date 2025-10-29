import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/EmployeeModel.dart';

class EmployeeDatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'employees.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        profileImagePath TEXT NOT NULL,
        calibrationImages TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // إضافة موظف جديد
  Future<int> insertEmployee(EmployeeModel employee) async {
    final db = await database;
    employee.createdAt = DateTime.now();
    return await db.insert('employees', employee.toMap());
  }

  // جلب كل الموظفين
  Future<List<EmployeeModel>> getAllEmployees() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('employees');
    return List.generate(maps.length, (i) {
      return EmployeeModel.fromMap(maps[i]);
    });

  }

  // جلب موظف بالـ ID
  Future<EmployeeModel?> getEmployeeById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return EmployeeModel.fromMap(maps.first);
    }
    return null;
  }

  // تحديث بيانات الموظف (ما عدا الـ ID)
  Future<int> updateEmployee(EmployeeModel employee) async {
    final db = await database;
    return await db.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  // حذف موظف
  Future<int> deleteEmployee(int id) async {
    final db = await database;
    return await db.delete(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}