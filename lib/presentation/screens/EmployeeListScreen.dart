import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/EmployeeModel.dart';
import '../cubit/EmployeeCubit.dart';
import '../cubit/EmployeeState.dart';
import 'EmployeeDetailsBottomSheet.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<EmployeeModel> _filteredEmployees = [];
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterEmployees);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeCubit>().loadEmployees();
      _isInitialLoad = false;
    });
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
          Expanded(
            child: BlocConsumer<EmployeeCubit, EmployeeState>(
              listener: (context, state) {
                if (state is EmployeeError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${state.message}')),
                  );
                }
              },
              builder: (context, state) {
                if (_isInitialLoad || state is EmployeeLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is EmployeeError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${state.message}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<EmployeeCubit>().loadEmployees();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is EmployeeLoaded) {
                  final employees = _searchController.text.isEmpty
                      ? state.employees
                      : _filteredEmployees;

                  if (employees.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No employees found',
                            style: TextStyle(fontSize: 18),
                          ),
                          if (_searchController.text.isNotEmpty)
                            ElevatedButton(
                              onPressed: () {
                                _searchController.clear();
                              },
                              child: const Text('Clear Search'),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: employees.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final employee = employees[index];
                      return _buildEmployeeCard(employee);
                    },
                  );
                }

                return const Center(
                  child: Text(
                    'No employees found',
                    style: TextStyle(fontSize: 18),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeModel employee) {
    return Card(
      color: Colors.black87,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
        child: ListTile(
          leading: _buildEmployeeAvatar(employee),
          title: Text(
            employee.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${employee.id}',
                style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                    color: Colors.white),
              ),
            ],
          ),
          trailing: PopupMenuButton(
            iconColor: Colors.white,
            color: Colors.white70,
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
                _showEmployeeDetailsBottomSheet(employee);
              } else if (value == 'delete') {
                _showDeleteDialog(employee);
              }
            },
          ),
          onTap: () {
            _showEmployeeDetailsBottomSheet(employee);
          },
        ),
      ),
    );
  }

  void _showEmployeeDetailsBottomSheet(EmployeeModel employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.7,
        child: EmployeeDetailsBottomSheet(employee: employee),
      ),
    ).then((result) {
      if (result == true) {
        context.read<EmployeeCubit>().loadEmployees();
      }
    });
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
        Navigator.pop(context);
        await context.read<EmployeeCubit>().deleteEmployee(employee.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${employee.name} deleted successfully')),
        );
      }
    } catch (e) {
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
          return CircleAvatar(
            backgroundImage: FileImage(snapshot.data!),
            radius: 35,
          );
        } else {
          return CircleAvatar(
            backgroundColor: Colors.white60,
            radius: 35,
            child: Text(
              employee.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
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