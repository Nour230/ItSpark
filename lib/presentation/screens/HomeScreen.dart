import 'package:flutter/material.dart';

import '../../core/navigation/AppRoutes.dart';
import 'EmployeeListScreen.dart';
import 'FaceRecognitionScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const EmployeeListScreen(), // سننشئها لاحقاً
    const FaceRecognitionScreen(), // سننشئها لاحقاً
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.face),
            label: 'Recognize',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEmployee,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSearch() {
    // Search functionality سيتم إضافتها لاحقاً
  }

  void _addEmployee() {
    Navigator.pushNamed(context, AppRoutes.addEmployee);
  }
}


