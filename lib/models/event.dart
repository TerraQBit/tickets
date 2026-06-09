class Event {
  const Event({
    required this.id,
    required this.title,
    required this.venue,
    required this.date,
    required this.price,
    required this.totalSeats,
    int? availableSeats,
  }) : availableSeats = availableSeats ?? totalSeats;

  final String id;
  final String title;
  final String venue;
  final DateTime date;
  final double price;
  final int totalSeats;
  final int availableSeats;

  Event copyWith({int? availableSeats}) {
    return Event(
      id: id,
      title: title,
      venue: venue,
      date: date,
      price: price,
      totalSeats: totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
    );
  }
}
