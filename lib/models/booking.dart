class Booking {
  const Booking({
    required this.id,
    required this.eventId,
    required this.passengerName,
    required this.email,
    required this.seatCount,
    required this.totalPrice,
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String passengerName;
  final String email;
  final int seatCount;
  final double totalPrice;
  final DateTime createdAt;
}
