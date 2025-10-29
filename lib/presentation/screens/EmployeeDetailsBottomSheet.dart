import 'package:flutter/material.dart';
import 'dart:io';

import '../../data/models/EmployeeModel.dart';
import '../cubit/EmployeeCubit.dart';
import '../cubit/EmployeeState.dart';
import 'FaceCaptureScreen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EmployeeDetailsBottomSheet extends StatefulWidget {
  final EmployeeModel employee;

  const EmployeeDetailsBottomSheet({super.key, required this.employee});

  @override
  State<EmployeeDetailsBottomSheet> createState() => _EmployeeDetailsBottomSheetState();
}

class _EmployeeDetailsBottomSheetState extends State<EmployeeDetailsBottomSheet> {
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const Text(
                'Employee Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              _buildProfilePictureSection(),
              const SizedBox(height: 20),

              _buildReadOnlyField(
                label: 'Employee ID',
                value: _currentEmployee.id?.toString() ?? 'N/A',
              ),
              const SizedBox(height: 20),

              _buildNameField(),
              const SizedBox(height: 25),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showDeleteDialog,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
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
        const Text('Profile Picture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              FutureBuilder<File>(
                future: Future.value(File(_currentEmployee.profileImagePath)),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.existsSync()) {
                    return CircleAvatar(
                      backgroundImage: FileImage(snapshot.data!),
                      radius: 50,
                    );
                  }
                  return CircleAvatar(
                    backgroundColor: Colors.black,
                    radius: 50,
                    child: Text(
                      _currentEmployee.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 28, color: Colors.white),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 0,
                right: 4,
                child: InkWell(
                  onTap: _updateImages,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.edit, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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

  void _saveChanges() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter employee name')),
      );
      return;
    }
    context.read<EmployeeCubit>().updateEmployee(_currentEmployee);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes saved successfully')),
    );
    Navigator.pop(context);
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

  void _deleteEmployee() {
    if (_currentEmployee.id != null) {
      context.read<EmployeeCubit>().deleteEmployee(_currentEmployee.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_currentEmployee.name} deleted successfully')),
      );
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  Future<void> _refreshEmployeeData() async {
    context.read<EmployeeCubit>().loadEmployees();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
