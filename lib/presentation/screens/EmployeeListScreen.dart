import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/navigation/AppRoutes.dart';
import '../../data/models/EmployeeModel.dart';
import '../cubit/EmployeeCubit.dart';
import '../cubit/EmployeeState.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<EmployeeModel> _filteredEmployees = [];

  @override
  void initState() {
    super.initState();
    // تحميل الموظفين عند فتح الشاشة
    context.read<EmployeeCubit>().loadEmployees();
    _searchController.addListener(_filterEmployees);
  }

  void _filterEmployees() {
    final searchText = _searchController.text.toLowerCase();
    final state = context.read<EmployeeCubit>().state;

    if (state is EmployeeLoaded) {
      setState(() {
        _filteredEmployees = state.employees.where((employee) {
          return employee.name.toLowerCase().contains(searchText) ||
              employee.id.toString().contains(searchText);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search employee by name or ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Employee List
          Expanded(
            child: BlocBuilder<EmployeeCubit, EmployeeState>(
              builder: (context, state) {
                if (state is EmployeeLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is EmployeeError) {
                  return Center(child: Text('Error: ${state.message}'));
                }

                if (state is EmployeeLoaded) {
                  final employees = _searchController.text.isEmpty
                      ? state.employees
                      : _filteredEmployees;

                  if (employees.isEmpty) {
                    return const Center(
                      child: Text(
                        'No employees found',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: employees.length,
                    itemBuilder: (context, index) {
                      final employee = employees[index];
                      return _buildEmployeeCard(employee);
                    },
                  );
                }

                return const Center(child: Text('No employees data'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeModel employee) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildEmployeeAvatar(employee),
        title: Text(
          employee.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${employee.id}'),
            Text('Images: ${employee.calibrationImages.length + 1}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.pushNamed(
                context,
                AppRoutes.employeeDetails,
                arguments: employee,
              );
            } else if (value == 'delete') {
              _showDeleteDialog(employee);
            }
          },
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.employeeDetails,
            arguments: employee,
          );
        },
      ),
    );
  }

  void _showDeleteDialog(EmployeeModel employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to delete ${employee.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteEmployee(employee),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteEmployee(EmployeeModel employee) async {
    try {
      if (employee.id != null) {
        // إخفاء الدايلوج أولاً
        Navigator.pop(context);

        await context.read<EmployeeCubit>().deleteEmployee(employee.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${employee.name} deleted successfully')),
        );
      }
    } catch (e) {
      // إذا حصل error، نخفي الدايلوج ونظهر error
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting employee: $e')),
      );
    }
  }

  Widget _buildEmployeeAvatar(EmployeeModel employee) {
    return FutureBuilder<File>(
      future: _getImageFile(employee.profileImagePath),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.existsSync()) {
          // عرض الصورة الحقيقية
          return CircleAvatar(
            backgroundImage: FileImage(snapshot.data!),
            radius: 25,
          );
        } else {
          // إذا الصورة مش موجودة نعرض بديل
          return CircleAvatar(
            backgroundColor: Colors.blue,
            child: Text(
              employee.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
      },
    );
  }

  Future<File> _getImageFile(String path) async {
    return File(path);
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}