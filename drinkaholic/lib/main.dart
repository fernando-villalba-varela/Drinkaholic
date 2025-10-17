import 'package:drinkaholic/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'viewmodels/league_list_viewmodel.dart';

void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Crear el ViewModel y cargar las ligas guardadas
  final leagueListVM = LeagueListViewModel();
  await leagueListVM.loadLeagues();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: leagueListVM)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Diseño base (puedes usar el tamaño de tu dispositivo de prueba)
      designSize: const Size(360, 800), // Tamaño estándar de referencia
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Drinkaholic',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
