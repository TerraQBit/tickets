import 'service_class.dart';

class Booking {
  const Booking({
    required this.id,
    required this.flightId,
    required this.passengerName,
    required this.email,
    required this.departureDate,
    required this.returnDate,
    required this.adults,
    required this.children,
    required this.serviceClass,
    required this.totalPrice,
    required this.createdAt,
  });

  final String id;
  final String flightId;
  final String passengerName;
  final String email;
  final DateTime departureDate;
  final DateTime returnDate;
  final int adults;
  final int children;
  final ServiceClass serviceClass;
  final double totalPrice;
  final DateTime createdAt;

  int get totalPassengers => adults + children;
}
