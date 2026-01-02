import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'screens/auth_gate.dart';
import 'screens/flight_details_screen.dart';
import 'screens/select_seats_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/flight_search_screen.dart';
import 'screens/boarding_pass_screen.dart';
import 'screens/staff_dashboard_screen.dart';
import 'models/flight.dart';
import 'providers/flight_provider.dart';
import 'screens/user_notifications_screen.dart';
import 'screens/staff_create_flight_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => FlightProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AITS Airline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blue.shade800,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade800),
        useMaterial3: true,
      ),
      home: const AuthGate(),
      routes: {
        '/home': (context) => const AuthGate(),
        '/profile': (context) => const ProfileScreen(),
        '/search': (context) => const FlightSearchScreen(),
        '/staff': (context) => const StaffDashboardScreen(),
        '/flight-details': (context) {
          final flight = ModalRoute.of(context)!.settings.arguments as Flight;
          return FlightDetailsScreen(flight: flight);
        },
        '/select-seats': (context) {
          final flightId = ModalRoute.of(context)!.settings.arguments as String;
          return SelectSeatsScreen(flightId: flightId);
        },
        '/booking': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return BookingScreen(
            flightId: args['flightId'],
            selectedSeats: List<String>.from(args['selectedSeats']),
          );
        },
        '/boarding-pass': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return BoardingPassScreen(bookingData: args);
        },
        '/notifications': (context) => const UserNotificationsScreen(),
        '/staff/create-flight': (context) => const StaffCreateFlightScreen(),
      },
    );
  }
}
