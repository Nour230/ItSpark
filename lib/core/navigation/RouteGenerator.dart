import 'package:flutter/material.dart';
import 'package:itspark_task/presentation/screens/EmployeeDetailsScreen.dart';
import '../../data/models/EmployeeModel.dart';
import '../../presentation/screens/AddEmployeeScreen.dart';
import '../../presentation/screens/FaceCaptureScreen.dart';
import '../../presentation/screens/FaceRecognitionScreen.dart';
import '../../presentation/screens/HomeScreen.dart';
import 'AppRoutes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case AppRoutes.addEmployee:
        return MaterialPageRoute(builder: (_) => const AddEmployeeScreen());

      case AppRoutes.faceCapture:
        final faceArgs = settings.arguments;
        if (faceArgs is String) {
          return MaterialPageRoute(
            builder: (_) => FaceCaptureScreen(employeeName: faceArgs),
          );
        } else if (faceArgs is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => FaceCaptureScreen(
              employeeName: faceArgs['name'],
              existingEmployee: faceArgs['employee'],
            ),
          );
        }
        return _errorRoute();
        
      case AppRoutes.employeeDetails:
        final employeeArgs = settings.arguments;
        if (employeeArgs is EmployeeModel) {
          return MaterialPageRoute(
            builder: (_) => EmployeeDetailsScreen(employee: employeeArgs),
          );
        }
        return _errorRoute();

      case AppRoutes.faceRecognition:
        return MaterialPageRoute(builder: (_) => const FaceRecognitionScreen());

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Page not found!')),
      );
    });
  }
}