import 'package:get_it/get_it.dart';
import 'package:itspark_task/data/local/EmployeeDatabaseService.dart';

import '../../data/repository/EmployeeRepository.dart';
import '../../data/repository/EmployeeRepositoryImpl.dart';
import '../../presentation/cubit/EmployeeCubit.dart';
import '../../data/services/CameraService.dart';
import '../../data/services/FaceDetectionService.dart';

final GetIt getIt = GetIt.instance;

Future<void> init() async {
  // Database
  getIt.registerLazySingleton<EmployeeDatabaseService>(
        () => EmployeeDatabaseService(),
  );

  // Services
  getIt.registerLazySingleton<CameraService>(
        () => CameraService(),
  );

  getIt.registerLazySingleton<FaceDetectionService>(
        () => FaceDetectionService(),
  );

  // Repository
  getIt.registerLazySingleton<EmployeeRepository>(
        () => EmployeeRepositoryImpl(),
  );

  // Cubit
  getIt.registerFactory<EmployeeCubit>(
        () => EmployeeCubit(
      getIt<EmployeeRepository>(),
      getIt<CameraService>(),
      getIt<FaceDetectionService>(),
    ),
  );
}
