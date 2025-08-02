import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/employee_provider.dart';
import 'screens/home_screen.dart';
import 'services/database_helper.dart';
import 'utils/app_pref.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize shared preferences
  await AppPreference.init();
  
  // Initialize database
  await DatabaseHelper().database;
  runApp(const EmployeeManagementApp());
}

class EmployeeManagementApp extends StatelessWidget {
  const EmployeeManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmployeeProvider()..fetchEmployees()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Employee Management App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
