import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:itspark_task/presentation/cubit/EmployeeCubit.dart';
import 'core/di/InjectionContainer.dart' as di;
import 'core/navigation/AppRoutes.dart';
import 'core/navigation/RouteGenerator.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EmployeeCubit>(
          create: (context) => di.getIt<EmployeeCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'Employee Management',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.home,
        onGenerateRoute: RouteGenerator.generateRoute,
      ),
    );
  }
}