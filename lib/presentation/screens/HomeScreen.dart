import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/EmployeeCubit.dart';
import '../cubit/EmployeeState.dart';
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmployeeCubit>().loadEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmployeeCubit, EmployeeState>(
      listener: (context, state) {
        if (state is EmployeeAdded) {
          context.read<EmployeeCubit>().loadEmployees();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: _screens[_currentIndex],
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
        floatingActionButton: _currentIndex == 0
            ? FloatingActionButton(
          foregroundColor: Colors.white,
          backgroundColor: Colors.black,
          onPressed: _addEmployee,
          child: const Icon(Icons.person_add),
        )
            : null,
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
    ).then((result) {
      if (result == true) {
        context.read<EmployeeCubit>().loadEmployees();
      }
    });
  }
  @override
  void dispose() {
    super.dispose();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<EmployeeCubit>().loadEmployees();
  }
}
