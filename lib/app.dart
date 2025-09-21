import 'package:flutter/material.dart';
import 'package:mars/splashScreen/splash_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/otp_verify_screen.dart';
import 'features/auth/set_new_password_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/home/dashboard_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/profile_screen.dart';
import 'features/inventory/add_production_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/medicine/add_medicine_screen.dart';
import 'features/medicine/medicine_screen.dart';
import 'features/orders/create_order_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/user/add_new_employee_screen.dart';
import 'features/user/employee_screen.dart';

class Mars extends StatelessWidget {
  const Mars({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/home',
      routes: {
        '/SplashScreen': (context) => const SplashScreen(),
        '/LoginScreen': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/otpVerify': (context) => const OtpVerifyScreen(),
        '/setNewPassword': (context) => const SetNewPasswordScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/medicine': (context) => MedicineScreen(),
        '/addMedicine': (context) => AddMedicineScreen(),
        '/orders': (context) => OrdersScreen(),
        '/createOrder': (context) => CreateOrderScreen(),
        '/inventory': (context) => InventoryScreen(),
        '/addProduction': (context) => AddProductionScreen(),
        '/employee': (context) => EmployeeListScreen(),
        '/addEmployee': (context) => const AddEmployeeScreen(),



      },
      debugShowCheckedModeBanner: false,
      theme: buildThemeData(),

    );
  }

  ThemeData buildThemeData() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.green,
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
        titleMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: Colors.grey,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        labelStyle: TextStyle(
          color: Colors.green,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        errorStyle: TextStyle(
          color: Colors.red,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.green,
          ),
          ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.green,
          ),
          ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.green,
          ),
          ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.red,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          textStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: Size(double.infinity, 50),
        ),
      )
    );
  }
}
