import 'package:flutter_test/flutter_test.dart';
import 'package:tickets/models/flight.dart';
import 'package:tickets/models/service_class.dart';
import 'package:tickets/services/booking_service.dart';

void main() {
  late BookingService service;

  final testFlight = Flight(
    id: 'test-flt',
    origin: 'Москва',
    destination: 'Казань',
    departureDateTime: DateTime(2026, 6, 15, 10, 0),
    basePrice: 4000,
    totalSeats: 10,
    airline: 'Тест Авиа',
  );

  setUp(() {
    service = BookingService(initialFlights: [testFlight]);
  });

  group('Позитивные тесты — валидация имени', () {
    test('TC-P-001: корректное имя из двух символов принимается', () {
      expect(service.validatePassengerName('Ив'), isNull);
    });

    test('TC-P-002: имя с пробелами обрезается и принимается', () {
      expect(service.validatePassengerName('  Иван Петров  '), isNull);
    });

    test('TC-P-003: имя кириллицей принимается', () {
      expect(service.validatePassengerName('Алексей Смирнов'), isNull);
    });
  });

  group('Позитивные тесты — валидация email', () {
    test('TC-P-004: корректный email принимается', () {
      expect(service.validateEmail('user@example.com'), isNull);
    });

    test('TC-P-005: email с точкой в локальной части принимается', () {
      expect(service.validateEmail('first.last@mail.ru'), isNull);
    });

    test('TC-P-006: email с дефисом в домене принимается', () {
      expect(service.validateEmail('test@my-domain.org'), isNull);
    });
  });

  group('Позитивные тесты — валидация пассажиров', () {
    test('TC-P-007: один взрослый принимается', () {
      expect(service.validateAdults(1), isNull);
    });

    test('TC-P-008: максимальное количество взрослых принимается', () {
      expect(service.validateAdults(BookingService.maxAdults), isNull);
    });

    test('TC-P-009: ноль детей принимается', () {
      expect(service.validateChildren(0), isNull);
    });

    test('TC-P-010: бронирование всех свободных мест принимается', () {
      expect(service.validatePassengerCount(5, 5, 10), isNull);
    });
  });

  group('Позитивные тесты — поиск и бронирование', () {
    test('TC-P-011: поиск находит рейс по параметрам', () {
      final results = service.searchFlights(
        origin: 'Москва',
        destination: 'Казань',
        departureDate: DateTime(2026, 6, 15),
        returnDate: DateTime(2026, 6, 20),
        adults: 1,
        children: 0,
        serviceClass: ServiceClass.economy,
      );

      expect(results, hasLength(1));
      expect(results.first.id, 'test-flt');
    });

    test('TC-P-012: успешное бронирование одного взрослого', () {
      final result = service.book(
        flightId: 'test-flt',
        passengerName: 'Иван Иванов',
        email: 'ivan@mail.ru',
        departureDate: DateTime(2026, 6, 15),
        returnDate: DateTime(2026, 6, 20),
        adults: 1,
        children: 0,
        serviceClass: ServiceClass.economy,
      );

      expect(result.isSuccess, isTrue);
      expect(result.booking!.adults, 1);
      expect(result.booking!.totalPrice, 4000);
      expect(service.bookings, hasLength(1));
    });

    test('TC-P-013: количество свободных мест уменьшается', () {
      service.book(
        flightId: 'test-flt',
        passengerName: 'Мария',
        email: 'maria@mail.ru',
        departureDate: DateTime(2026, 6, 15),
        returnDate: DateTime(2026, 6, 20),
        adults: 2,
        children: 1,
        serviceClass: ServiceClass.economy,
      );

      expect(service.getFlightById('test-flt')!.availableSeats, 7);
    });

    test('TC-P-014: расчёт цены с детьми и бизнес-классом', () {
      final price = service.calculatePrice(
        flight: testFlight,
        adults: 2,
        children: 1,
        serviceClass: ServiceClass.business,
      );

      // (4000*2 + 4000*0.5*1) * 2.5 = 25000
      expect(price, 25000);
    });

    test('TC-P-015: отмена бронирования возвращает места', () {
      final booking = service.book(
        flightId: 'test-flt',
        passengerName: 'Анна',
        email: 'anna@mail.ru',
        departureDate: DateTime(2026, 6, 15),
        returnDate: DateTime(2026, 6, 20),
        adults: 2,
        children: 0,
        serviceClass: ServiceClass.economy,
      ).booking!;

      final cancelResult = service.cancelBooking(booking.id);

      expect(cancelResult.isSuccess, isTrue);
      expect(service.getFlightById('test-flt')!.availableSeats, 10);
      expect(service.bookings, isEmpty);
    });
  });

  group('Негативные тесты — валидация', () {
    test('TC-N-001: пустое имя отклоняется', () {
      expect(service.validatePassengerName(''), isNotNull);
    });

    test('TC-N-002: ноль взрослых отклоняется', () {
      expect(service.validateAdults(0), isNotNull);
    });

    test('TC-N-003: отрицательное количество детей отклоняется', () {
      expect(service.validateChildren(-1), isNotNull);
    });

    test('TC-N-004: дата возвращения раньше вылета отклоняется', () {
      expect(
        service.validateReturnDate(
          DateTime(2026, 6, 20),
          DateTime(2026, 6, 15),
        ),
        isNotNull,
      );
    });

    test('TC-N-005: бронирование несуществующего рейса', () {
      final result = service.book(
        flightId: 'unknown',
        passengerName: 'Иван',
        email: 'ivan@mail.ru',
        departureDate: DateTime(2026, 6, 15),
        returnDate: DateTime(2026, 6, 20),
        adults: 1,
        children: 0,
        serviceClass: ServiceClass.economy,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'Рейс не найден');
    });

    test('TC-N-006: бронирование при нехватке мест', () {
      service.book(
        flightId: 'test-flt',
        passengerName: 'First',
        email: 'first@mail.ru',
        departureDate: DateTime(2026, 6, 15),
        returnDate: DateTime(2026, 6, 20),
        adults: 8,
        children: 0,
        serviceClass: ServiceClass.economy,
      );

      final result = service.book(
        flightId: 'test-flt',
        passengerName: 'Second',
        email: 'second@mail.ru',
        departureDate: DateTime(2026, 6, 15),
        returnDate: DateTime(2026, 6, 20),
        adults: 5,
        children: 0,
        serviceClass: ServiceClass.economy,
      );

      expect(result.isSuccess, isFalse);
      expect(service.getFlightById('test-flt')!.availableSeats, 2);
    });
  });

  group('Деструктивные тесты', () {
    test('TC-D-001: XSS в имени отклоняется', () {
      expect(
        service.validatePassengerName('<script>alert(1)</script>'),
        isNotNull,
      );
    });

    test('TC-D-002: SQL-инъекция через book() не создаёт бронирование', () {
      final result = service.book(
        flightId: 'test-flt',
        passengerName: "Admin'--",
        email: 'test@mail.ru',
        departureDate: DateTime(2026, 6, 15),
        returnDate: DateTime(2026, 6, 20),
        adults: 1,
        children: 0,
        serviceClass: ServiceClass.economy,
      );

      expect(result.isSuccess, isFalse);
      expect(service.bookings, isEmpty);
    });
  });
}
