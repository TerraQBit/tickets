class Flight {
  const Flight({
    required this.id,
    required this.origin,
    required this.destination,
    required this.departureDateTime,
    required this.basePrice,
    required this.totalSeats,
    int? availableSeats,
    required this.airline,
  }) : availableSeats = availableSeats ?? totalSeats;

  final String id;
  final String origin;
  final String destination;
  final DateTime departureDateTime;
  final double basePrice;
  final int totalSeats;
  final int availableSeats;
  final String airline;

  Flight copyWith({int? availableSeats}) {
    return Flight(
      id: id,
      origin: origin,
      destination: destination,
      departureDateTime: departureDateTime,
      basePrice: basePrice,
      totalSeats: totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      airline: airline,
    );
  }
}
