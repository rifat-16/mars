import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/events_repository.dart';
import 'data/repositories/inventory_repository.dart';
import 'data/repositories/orders_repository.dart';
import 'data/repositories/payments_repository.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'state/dashboard_provider.dart';
import 'state/inventory_provider.dart';
import 'state/orders_provider.dart';
import 'state/payments_provider.dart';
import 'state/session_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => FirebaseAuthRepository()),
        Provider<OrdersRepository>(create: (_) => FirebaseOrdersRepository()),
        Provider<InventoryRepository>(
          create: (_) => FirebaseInventoryRepository(),
        ),
        Provider<PaymentsRepository>(
          create: (_) => FirebasePaymentsRepository(),
        ),
        Provider<DashboardRepository>(
          create: (_) => FirebaseDashboardRepository(),
        ),
        Provider<EventsRepository>(create: (_) => FirebaseEventsRepository()),
        ChangeNotifierProvider<SessionProvider>(
          create: (context) =>
              SessionProvider(context.read<AuthRepository>())..restoreSession(),
        ),
        ChangeNotifierProvider<OrdersProvider>(
          create: (context) => OrdersProvider(context.read<OrdersRepository>()),
        ),
        ChangeNotifierProvider<InventoryProvider>(
          create: (context) =>
              InventoryProvider(context.read<InventoryRepository>()),
        ),
        ChangeNotifierProvider<PaymentsProvider>(
          create: (context) =>
              PaymentsProvider(context.read<PaymentsRepository>()),
        ),
        ChangeNotifierProvider<DashboardProvider>(
          create: (context) =>
              DashboardProvider(context.read<DashboardRepository>()),
        ),
      ],
      child: const MarsApp(),
    ),
  );
}
