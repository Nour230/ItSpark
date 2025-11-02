import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';

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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      const Text(
                        'Employee Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // Profile Picture
                      _buildProfilePictureSection(),
                      const SizedBox(height: 30),

                      // Employee ID
                      _buildReadOnlyField(
                        label: 'Employee ID',
                        value: _currentEmployee.id?.toString() ?? 'N/A',
                      ),
                      const SizedBox(height: 30),

                      // Name
                      _buildNameField(),
                      const SizedBox(height: 30),

                    ],
                  ),
                ),

                // Save & Delete Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save_as_outlined),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showDeleteDialog,
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Employee Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              FutureBuilder<File>(
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

              // Edit Icon
              Positioned(
                bottom: 0,
                right: 4,
                child: InkWell(
                  onTap: _updateImages,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.edit, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }



  Future<File> _getImageFile(String path) async => File(path);

  void _updateImages() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaceCaptureScreen(
          employeeName: _currentEmployee.name,
          existingEmployee: _currentEmployee,
        ),
      ),
    );
    if (result == true) _refreshEmployeeData();
  }

  void _saveChanges() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter employee name')),
      );
      return;
    }
    try {
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

  Future<void> _refreshEmployeeData() async {
    context.read<EmployeeCubit>().loadEmployees();
    await Future.delayed(const Duration(milliseconds: 500));
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
