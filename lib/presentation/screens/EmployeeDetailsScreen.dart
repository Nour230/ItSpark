import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';

import '../../core/navigation/AppRoutes.dart';
import '../../data/models/EmployeeModel.dart';
import '../cubit/EmployeeCubit.dart';
import '../cubit/EmployeeState.dart';
import 'FaceCaptureScreen.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  final EmployeeModel employee;

  const EmployeeDetailsScreen({
    super.key,
    required this.employee,
  });

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  late TextEditingController _nameController;
  late EmployeeModel _currentEmployee;

  @override
  void initState() {
    super.initState();
    _currentEmployee = widget.employee;
    _nameController = TextEditingController(text: _currentEmployee.name);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmployeeCubit, EmployeeState>(
      listener: (context, state) {
        if (state is EmployeeError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Employee Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _showDeleteDialog,
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Employee ID (Read Only)
              _buildReadOnlyField(
                label: 'Employee ID',
                value: _currentEmployee.id?.toString() ?? 'N/A',
              ),
              const SizedBox(height: 20),

              // Employee Name (Editable)
              _buildNameField(),
              const SizedBox(height: 20),

              // Profile Picture
              _buildProfilePictureSection(),
              const SizedBox(height: 20),

              // Calibration Images
              _buildCalibrationImagesSection(),
              const SizedBox(height: 20),

              // Update Images Button
              _buildUpdateImagesButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Employee Name',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter employee name',
          ),
          onChanged: (value) {
            setState(() {
              _currentEmployee = _currentEmployee.copyWith(name: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildProfilePictureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Picture',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Center(
          child: FutureBuilder<File>(
            future: _getImageFile(_currentEmployee.profileImagePath),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.existsSync()) {
                return CircleAvatar(
                  backgroundImage: FileImage(snapshot.data!),
                  radius: 60,
                );
              }
              return CircleAvatar(
                backgroundColor: Colors.blue,
                radius: 60,
                child: Text(
                  _currentEmployee.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 30, color: Colors.white),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCalibrationImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Calibration Images',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Total: ${_currentEmployee.calibrationImages.length} images',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _currentEmployee.calibrationImages.length,
            itemBuilder: (context, index) {
              return FutureBuilder<File>(
                future: _getImageFile(_currentEmployee.calibrationImages[index]),
                builder: (context, snapshot) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: CircleAvatar(
                      backgroundImage: snapshot.hasData && snapshot.data!.existsSync()
                          ? FileImage(snapshot.data!)
                          : null,
                      radius: 40,
                      backgroundColor: Colors.grey[300],
                      child: snapshot.hasData && snapshot.data!.existsSync()
                          ? null
                          : const Icon(Icons.image, size: 30, color: Colors.grey),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateImagesButton() {
    return ElevatedButton(
      onPressed: _updateImages,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text('Update Images'),
    );
  }

  void _updateImages() async {
    // الانتقال لشاشة تحديث الصور وانتظار النتيجة
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceCaptureScreen(
          employeeName: _currentEmployee.name,
          existingEmployee: _currentEmployee,
        ),
      ),
    );

    // إذا رجعنا من شاشة التحديث، نعمل refresh للبيانات
    if (result == true) {
      _refreshEmployeeData();
    }
  }

  Future<File> _getImageFile(String path) async {
    return File(path);
  }

  void _saveChanges() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter employee name')),
      );
      return;
    }

    try {
      // TODO: تحديث البيانات في الـ Database
      context.read<EmployeeCubit>().updateEmployee(_currentEmployee);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes saved successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // الاستماع للتحديثات عندما نرجع من شاشة تحديث الصور
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      _refreshEmployeeData();
    }
  }

  Future<void> _refreshEmployeeData() async {
    // إعادة تحميل قائمة الموظفين عشان نجيب البيانات المحدثة
    context.read<EmployeeCubit>().loadEmployees();

    // تحديث الـ UI بعد فترة بسيطة
    await Future.delayed(const Duration(milliseconds: 500));

    // البحث عن الموظف المحدث في الـ state
    final state = context.read<EmployeeCubit>().state;
    if (state is EmployeeLoaded) {
      final updatedEmployee = state.employees.firstWhere(
            (emp) => emp.id == _currentEmployee.id,
        orElse: () => _currentEmployee,
      );

      setState(() {
        _currentEmployee = updatedEmployee;
        _nameController.text = updatedEmployee.name;
      });
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${_currentEmployee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _deleteEmployee,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteEmployee() async {
    try {
      if (_currentEmployee.id != null) {
        await context.read<EmployeeCubit>().deleteEmployee(_currentEmployee.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_currentEmployee.name} deleted successfully')),
        );

        // الرجوع للقائمة الرئيسية
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting employee: $e')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}