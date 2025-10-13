import 'package:Mars/models/user_model.dart';
import 'package:Mars/ui/screens/add_payment.dart';
import 'package:Mars/ui/screens/customers_list.dart';
import 'package:Mars/ui/screens/dashboard_screen.dart';
import 'package:Mars/ui/screens/orders_details_screen.dart';
import 'package:Mars/ui/screens/payment_received_screen.dart';
import 'package:Mars/ui/screens/customer_details.dart';
import 'package:Mars/ui/screens/production_details_list_screen.dart';
import 'package:Mars/ui/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'ui/screens/forgot_password_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/otp_verify_screen.dart';
import 'ui/screens/set_new_password_screen.dart';
import 'ui/screens/signup_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/add_production_screen.dart';
import 'ui/screens/inventory_screen.dart';
import 'ui/screens/add_medicine_screen.dart';
import 'ui/screens/medicine_screen.dart';
import 'ui/screens/create_order_screen.dart';
import 'ui/screens/orders_screen.dart';
import 'ui/screens/add_new_employee_screen.dart';
import 'ui/screens/employee_screen.dart';



class Mars extends StatelessWidget {
  const Mars({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mars',
      home: const SplashScreen(),
      routes: {
        '/LoginScreen': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
        '/otpVerify': (context) => const OtpVerifyScreen(),
        '/setNewPassword': (context) => const SetNewPasswordScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/medicine': (context) => MedicineScreen(),
        '/addMedicine': (context) => AddMedicineScreen(),
        '/orders': (context) => OrdersScreen(),
        '/ordersDetails': (context) => OrdersDetailsScreen(orderId: '',),
        '/createOrder': (context) => CreateOrderScreen(),
        '/inventory': (context) => InventoryScreen(),
        '/addProduction': (context) => AddProductionScreen(),
        '/employee': (context) => EmployeeListScreen(),
        '/addEmployee': (context) => const AddEmployeeScreen(),
        '/productionDetails': (context) => ProductionDetailsListScreen(),
        '/pharmacyList': (context) => PharmacyList(),
        '/pharmacyDetails': (context) => CustomerDetails(),
        '/paymentReceived': (context) => PaymentReceivedScreen(),
        '/addPayment': (context) => AddPayment(),
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