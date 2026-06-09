import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/booking_service.dart';

void main() {
  runApp(const TicketsApp());
}

class TicketsApp extends StatelessWidget {
  const TicketsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Авиабилеты',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeScreen(bookingService: BookingService()),
    );
  }
}
