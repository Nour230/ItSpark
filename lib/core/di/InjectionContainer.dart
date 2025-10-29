import 'package:get_it/get_it.dart';
import 'package:itspark_task/data/local/EmployeeDatabaseService.dart';

import '../../data/repository/EmployeeRepository.dart';
import '../../data/repository/EmployeeRepositoryImpl.dart';
import '../../presentation/cubit/EmployeeCubit.dart';

final GetIt getIt = GetIt.instance;

Future<void> init() async{
  //database
  getIt.registerLazySingleton<EmployeeDatabaseService>(
      ()=>EmployeeDatabaseService()
  );

  //repo
  getIt.registerLazySingleton<EmployeeRepository>(
      ()=>EmployeeRepositoryImpl()
  );

  // Cubits
  getIt.registerFactory<EmployeeCubit>(
        () => EmployeeCubit(getIt<EmployeeRepository>()),
  );

  //viewmodel

}