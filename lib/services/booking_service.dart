import '../models/booking.dart';
import '../models/booking_result.dart';
import '../models/flight.dart';
import '../models/service_class.dart';

/// Сервис поиска и бронирования авиабилетов.
class BookingService {
  BookingService({List<Flight>? initialFlights})
      : _flights = List<Flight>.from(initialFlights ?? defaultFlights);

  static const int maxPassengerNameLength = 100;
  static const int maxEmailLength = 254;
  static const int maxAdults = 9;
  static const int maxChildren = 9;
  static const double childPriceRatio = 0.5;

  static final List<Flight> defaultFlights = [
    Flight(
      id: 'flt-1',
      origin: 'Москва',
      destination: 'Санкт-Петербург',
      departureDateTime: DateTime(2026, 6, 15, 8, 30),
      basePrice: 4500,
      totalSeats: 120,
      airline: 'Аэрофлот',
    ),
    Flight(
      id: 'flt-2',
      origin: 'Москва',
      destination: 'Санкт-Петербург',
      departureDateTime: DateTime(2026, 6, 15, 18, 45),
      basePrice: 5200,
      totalSeats: 100,
      airline: 'S7 Airlines',
    ),
    Flight(
      id: 'flt-3',
      origin: 'Санкт-Петербург',
      destination: 'Москва',
      departureDateTime: DateTime(2026, 6, 20, 10, 0),
      basePrice: 4800,
      totalSeats: 110,
      airline: 'Аэрофлот',
    ),
    Flight(
      id: 'flt-4',
      origin: 'Москва',
      destination: 'Казань',
      departureDateTime: DateTime(2026, 6, 15, 14, 15),
      basePrice: 3800,
      totalSeats: 80,
      airline: 'Победа',
    ),
    Flight(
      id: 'flt-5',
      origin: 'Казань',
      destination: 'Москва',
      departureDateTime: DateTime(2026, 6, 22, 16, 30),
      basePrice: 3900,
      totalSeats: 80,
      airline: 'Победа',
    ),
    Flight(
      id: 'flt-6',
      origin: 'Москва',
      destination: 'Сочи',
      departureDateTime: DateTime(2026, 7, 1, 6, 0),
      basePrice: 6500,
      totalSeats: 150,
      airline: 'Аэрофлот',
    ),
  ];

  final List<Flight> _flights;
  final List<Booking> _bookings = [];
  int _bookingCounter = 0;

  List<Flight> get flights => List.unmodifiable(_flights);
  List<Booking> get bookings => List.unmodifiable(_bookings);

  List<String> get cities {
    final set = <String>{};
    for (final flight in _flights) {
      set.add(flight.origin);
      set.add(flight.destination);
    }
    return set.toList()..sort();
  }

  Flight? getFlightById(String flightId) {
    try {
      return _flights.firstWhere((f) => f.id == flightId);
    } catch (_) {
      return null;
    }
  }

  List<Flight> searchFlights({
    required String origin,
    required String destination,
    required DateTime departureDate,
    required DateTime returnDate,
    required int adults,
    required int children,
    required ServiceClass serviceClass,
  }) {
    final passengers = adults + children;
    final departureDay = _dateOnly(departureDate);

    return _flights.where((flight) {
      return flight.origin == origin &&
          flight.destination == destination &&
          _dateOnly(flight.departureDateTime) == departureDay &&
          flight.availableSeats >= passengers;
    }).toList();
  }

  double calculatePrice({
    required Flight flight,
    required int adults,
    required int children,
    required ServiceClass serviceClass,
  }) {
    final multiplier = serviceClass.priceMultiplier;
    final adultTotal = flight.basePrice * adults * multiplier;
    final childTotal =
        flight.basePrice * childPriceRatio * children * multiplier;
    return adultTotal + childTotal;
  }

  String? validatePassengerName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Введите имя пассажира';
    }
    if (trimmed.length < 2) {
      return 'Имя должно содержать минимум 2 символа';
    }
    if (trimmed.length > maxPassengerNameLength) {
      return 'Имя слишком длинное (максимум $maxPassengerNameLength символов)';
    }
    if (_containsSuspiciousPatterns(trimmed)) {
      return 'Имя содержит недопустимые символы';
    }
    return null;
  }

  String? validateEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return 'Введите email';
    }
    if (trimmed.length > maxEmailLength) {
      return 'Email слишком длинный';
    }
    final emailRegex = RegExp(r'^[\w.\-+]+@[\w.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Некорректный формат email';
    }
    if (_containsSuspiciousPatterns(trimmed)) {
      return 'Email содержит недопустимые символы';
    }
    return null;
  }

  String? validateAdults(int adults) {
    if (adults <= 0) {
      return 'Укажите хотя бы одного взрослого';
    }
    if (adults > maxAdults) {
      return 'Максимум $maxAdults взрослых';
    }
    return null;
  }

  String? validateChildren(int children) {
    if (children < 0) {
      return 'Количество детей не может быть отрицательным';
    }
    if (children > maxChildren) {
      return 'Максимум $maxChildren детей';
    }
    return null;
  }

  String? validatePassengerCount(int adults, int children, int availableSeats) {
    final adultsError = validateAdults(adults);
    if (adultsError != null) return adultsError;

    final childrenError = validateChildren(children);
    if (childrenError != null) return childrenError;

    final total = adults + children;
    if (total > availableSeats) {
      return 'Недостаточно мест (доступно: $availableSeats)';
    }
  }

  String? validateReturnDate(DateTime departureDate, DateTime returnDate) {
    final dep = _dateOnly(departureDate);
    final ret = _dateOnly(returnDate);
    if (ret.isBefore(dep)) {
      return 'Дата возвращения не может быть раньше даты вылета';
    }
    return null;
  }

  BookingResult book({
    required String flightId,
    required String passengerName,
    required String email,
    required DateTime departureDate,
    required DateTime returnDate,
    required int adults,
    required int children,
    required ServiceClass serviceClass,
  }) {
    final flight = getFlightById(flightId);
    if (flight == null) {
      return const BookingResult.failure('Рейс не найден');
    }

    final nameError = validatePassengerName(passengerName);
    if (nameError != null) {
      return BookingResult.failure(nameError);
    }

    final emailError = validateEmail(email);
    if (emailError != null) {
      return BookingResult.failure(emailError);
    }

    final returnError = validateReturnDate(departureDate, returnDate);
    if (returnError != null) {
      return BookingResult.failure(returnError);
    }

    final countError =
        validatePassengerCount(adults, children, flight.availableSeats);
    if (countError != null) {
      return BookingResult.failure(countError);
    }

    final totalPrice = calculatePrice(
      flight: flight,
      adults: adults,
      children: children,
      serviceClass: serviceClass,
    );

    _bookingCounter++;
    final booking = Booking(
      id: 'bkg-$_bookingCounter',
      flightId: flightId,
      passengerName: passengerName.trim(),
      email: email.trim(),
      departureDate: _dateOnly(departureDate),
      returnDate: _dateOnly(returnDate),
      adults: adults,
      children: children,
      serviceClass: serviceClass,
      totalPrice: totalPrice,
      createdAt: DateTime.now(),
    );

    _bookings.add(booking);
    _updateAvailableSeats(flightId, flight.availableSeats - adults - children);

    return BookingResult.success(booking);
  }

  BookingResult cancelBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) {
      return const BookingResult.failure('Бронирование не найдено');
    }

    final booking = _bookings[index];
    final flight = getFlightById(booking.flightId);
    if (flight != null) {
      _updateAvailableSeats(
        booking.flightId,
        flight.availableSeats + booking.totalPassengers,
      );
    }

    _bookings.removeAt(index);
    return BookingResult.success(booking);
  }

  bool _containsSuspiciousPatterns(String value) {
    const patterns = [
      '<script',
      'DROP TABLE',
      'DELETE FROM',
      '--',
      ';',
      '\x00',
    ];
    final lower = value.toLowerCase();
    for (final pattern in patterns) {
      if (lower.contains(pattern.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  void _updateAvailableSeats(String flightId, int newCount) {
    final index = _flights.indexWhere((f) => f.id == flightId);
    if (index != -1) {
      _flights[index] = _flights[index].copyWith(availableSeats: newCount);
    }
  }
}
