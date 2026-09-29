import 'package:flutter/material.dart';

import 'core/constants/app_routes.dart';
import 'ui/screens/add_medicine_screen.dart';
import 'ui/screens/add_new_employee_screen.dart';
import 'ui/screens/add_payment.dart';
import 'ui/screens/add_production_screen.dart';
import 'ui/screens/create_order_screen.dart';
import 'ui/screens/customer_details.dart';
import 'ui/screens/customers_list.dart';
import 'ui/screens/employee_screen.dart';
import 'ui/screens/event_create_screen.dart';
import 'ui/screens/event_v3_enrollment_details_screen.dart';
import 'ui/screens/event_v3_enrollment_form_screen.dart';
import 'ui/screens/event_v3_hub_screen.dart';
import 'ui/screens/event_v3_list_screen.dart';
import 'ui/screens/forgot_password_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/inventory_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/medicine_screen.dart';
import 'ui/screens/orders_details_screen.dart';
import 'ui/screens/orders_screen.dart';
import 'ui/screens/otp_verify_screen.dart';
import 'ui/screens/payment_received_screen.dart';
import 'ui/screens/production_details_list_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/set_new_password_screen.dart';
import 'ui/screens/signup_screen.dart';
import 'ui/screens/splash_screen.dart';

class MarsApp extends StatelessWidget {
  const MarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mars',
      debugShowCheckedModeBanner: false,
      theme: _buildThemeData(),
      home: const SplashScreen(),
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.loginLegacy: (context) => const LoginScreen(),
        AppRoutes.signup: (context) => const SignupScreen(),
        AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
        AppRoutes.otpVerify: (context) => const OtpVerifyScreen(),
        AppRoutes.setNewPassword: (context) => const SetNewPasswordScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.medicine: (context) => const MedicineScreen(),
        AppRoutes.addMedicine: (context) => const AddMedicineScreen(),
        AppRoutes.orders: (context) => const OrdersScreen(),
        AppRoutes.createOrder: (context) => const CreateOrderScreen(),
        AppRoutes.inventory: (context) => const InventoryScreen(),
        AppRoutes.addProduction: (context) => const AddProductionScreen(),
        AppRoutes.employee: (context) => const EmployeeListScreen(),
        AppRoutes.addEmployee: (context) => const AddEmployeeScreen(),
        AppRoutes.productionDetails: (context) => ProductionDetailsListScreen(),
        AppRoutes.pharmacyList: (context) => const PharmacyList(),
        AppRoutes.pharmacyDetails: (context) => const CustomerDetails(),
        AppRoutes.paymentReceived: (context) => const PaymentReceivedScreen(),
        AppRoutes.addPayment: (context) => const AddPayment(),
        AppRoutes.eventsV3: (context) => const EventV3ListScreen(),
        AppRoutes.eventHubV3: (context) => const EventV3HubScreen(),
        AppRoutes.eventCreate: (context) => const EventCreateScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.ordersDetails) {
          final orderId = settings.arguments is String
              ? settings.arguments as String
              : '';
          return MaterialPageRoute<void>(
            builder: (_) => OrdersDetailsScreen(orderId: orderId),
          );
        }
        if (settings.name == AppRoutes.eventEnrollmentFormV3) {
          return MaterialPageRoute<void>(
            builder: (_) => const EventV3EnrollmentFormScreen(),
            settings: settings,
          );
        }
        if (settings.name == AppRoutes.eventEnrollmentDetailsV3) {
          return MaterialPageRoute<void>(
            builder: (_) => const EventV3EnrollmentDetailsScreen(),
            settings: settings,
          );
        }
        return null;
      },
    );
  }

  ThemeData _buildThemeData() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.green,
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      textTheme: const TextTheme(
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
        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        labelStyle: const TextStyle(
          color: Colors.green,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }
}
