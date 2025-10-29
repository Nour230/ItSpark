import 'package:flutter/material.dart';

import '../../core/navigation/AppRoutes.dart';
import 'AddEmployeeScreen.dart';
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
    const EmployeeListScreen(),
    const FaceRecognitionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:SafeArea(
          child:
      _screens[_currentIndex],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
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
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        onPressed: _addEmployee,
        child: const Icon(Icons.person_add),
      ),
    );
  }


  void _addEmployee() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.6,
        child: const AddEmployeeScreen(),
      ),
    );

  }
}


