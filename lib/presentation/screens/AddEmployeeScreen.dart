import 'package:flutter/material.dart';
import '../../core/navigation/AppRoutes.dart';
class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({super.key});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Employee'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Employee Name Input
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Employee Name',
                hintText: 'Enter employee name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Next Button
            ElevatedButton(
              onPressed:  _goToFaceCapture,
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }

  void _goToFaceCapture() {
    Navigator.pushNamed(
      context,
      AppRoutes.faceCapture,
      arguments: _nameController.text,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}