import '../models/booking.dart';
import '../models/booking_result.dart';
import '../models/event.dart';

/// Сервис бронирования билетов с валидацией входных данных.
class BookingService {
  BookingService({List<Event>? initialEvents})
      : _events = List<Event>.from(initialEvents ?? defaultEvents);

  static const int maxPassengerNameLength = 100;
  static const int maxEmailLength = 254;
  static const int maxSeatCount = 10;

  static final List<Event> defaultEvents = [
    Event(
      id: 'evt-1',
      title: 'Концерт симфонического оркестра',
      venue: 'Большой зал',
      date: DateTime(2026, 6, 15, 19, 0),
      price: 1500,
      totalSeats: 50,
    ),
    Event(
      id: 'evt-2',
      title: 'Спектакль «Евгений Онегин»',
      venue: 'Театр драмы',
      date: DateTime(2026, 6, 20, 18, 30),
      price: 2200,
      totalSeats: 30,
    ),
    Event(
      id: 'evt-3',
      title: 'Джазовый вечер',
      venue: 'Клуб «Blue Note»',
      date: DateTime(2026, 7, 1, 20, 0),
      price: 900,
      totalSeats: 20,
    ),
  ];

  final List<Event> _events;
  final List<Booking> _bookings = [];
  int _bookingCounter = 0;

  List<Event> get events => List.unmodifiable(_events);
  List<Booking> get bookings => List.unmodifiable(_bookings);

  Event? getEventById(String eventId) {
    try {
      return _events.firstWhere((e) => e.id == eventId);
    } catch (_) {
      return null;
    }
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

  String? validateSeatCount(int seatCount, int availableSeats) {
    if (seatCount <= 0) {
      return 'Количество мест должно быть больше 0';
    }
    if (seatCount > maxSeatCount) {
      return 'Максимум $maxSeatCount мест за одно бронирование';
    }
    if (seatCount > availableSeats) {
      return 'Недостаточно свободных мест (доступно: $availableSeats)';
    }
    return null;
  }

  BookingResult book({
    required String eventId,
    required String passengerName,
    required String email,
    required int seatCount,
  }) {
    final event = getEventById(eventId);
    if (event == null) {
      return const BookingResult.failure('Мероприятие не найдено');
    }

    final nameError = validatePassengerName(passengerName);
    if (nameError != null) {
      return BookingResult.failure(nameError);
    }

    final emailError = validateEmail(email);
    if (emailError != null) {
      return BookingResult.failure(emailError);
    }

    final seatError = validateSeatCount(seatCount, event.availableSeats);
    if (seatError != null) {
      return BookingResult.failure(seatError);
    }

    _bookingCounter++;
    final booking = Booking(
      id: 'bkg-$_bookingCounter',
      eventId: eventId,
      passengerName: passengerName.trim(),
      email: email.trim(),
      seatCount: seatCount,
      totalPrice: event.price * seatCount,
      createdAt: DateTime.now(),
    );

    _bookings.add(booking);
    _updateAvailableSeats(eventId, event.availableSeats - seatCount);

    return BookingResult.success(booking);
  }

  BookingResult cancelBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) {
      return const BookingResult.failure('Бронирование не найдено');
    }

    final booking = _bookings[index];
    final event = getEventById(booking.eventId);
    if (event != null) {
      _updateAvailableSeats(
        booking.eventId,
        event.availableSeats + booking.seatCount,
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

  void _updateAvailableSeats(String eventId, int newCount) {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _events[index] = _events[index].copyWith(availableSeats: newCount);
    }
  }
}
