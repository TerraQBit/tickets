import 'package:flutter_test/flutter_test.dart';
import 'package:tickets/models/event.dart';
import 'package:tickets/services/booking_service.dart';

void main() {
  late BookingService service;

  final testEvent = Event(
    id: 'test-evt',
    title: 'Тестовое мероприятие',
    venue: 'Зал',
    date: DateTime(2026, 6, 1),
    price: 1000,
    totalSeats: 10,
  );

  setUp(() {
    service = BookingService(initialEvents: [testEvent]);
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

  group('Позитивные тесты — валидация мест', () {
    test('TC-P-007: одно место при наличии свободных принимается', () {
      expect(service.validateSeatCount(1, 10), isNull);
    });

    test('TC-P-008: максимальное количество мест принимается', () {
      expect(service.validateSeatCount(BookingService.maxSeatCount, 10), isNull);
    });

    test('TC-P-009: бронирование всех свободных мест принимается', () {
      expect(service.validateSeatCount(10, 10), isNull);
    });
  });

  group('Позитивные тесты — бронирование', () {
    test('TC-P-010: успешное бронирование одного места', () {
      final result = service.book(
        eventId: 'test-evt',
        passengerName: 'Иван Иванов',
        email: 'ivan@mail.ru',
        seatCount: 1,
      );

      expect(result.isSuccess, isTrue);
      expect(result.booking!.seatCount, 1);
      expect(result.booking!.totalPrice, 1000);
      expect(service.bookings, hasLength(1));
    });

    test('TC-P-011: количество свободных мест уменьшается после бронирования', () {
      service.book(
        eventId: 'test-evt',
        passengerName: 'Мария',
        email: 'maria@mail.ru',
        seatCount: 3,
      );

      expect(service.getEventById('test-evt')!.availableSeats, 7);
    });

    test('TC-P-012: бронирование нескольких мест рассчитывает цену верно', () {
      final result = service.book(
        eventId: 'test-evt',
        passengerName: 'Пётр',
        email: 'petr@mail.ru',
        seatCount: 4,
      );

      expect(result.booking!.totalPrice, 4000);
    });

    test('TC-P-013: отмена бронирования возвращает места', () {
      final booking = service.book(
        eventId: 'test-evt',
        passengerName: 'Анна',
        email: 'anna@mail.ru',
        seatCount: 2,
      ).booking!;

      final cancelResult = service.cancelBooking(booking.id);

      expect(cancelResult.isSuccess, isTrue);
      expect(service.getEventById('test-evt')!.availableSeats, 10);
      expect(service.bookings, isEmpty);
    });

    test('TC-P-014: несколько бронирований на одно мероприятие', () {
      service.book(
        eventId: 'test-evt',
        passengerName: 'User1',
        email: 'u1@mail.ru',
        seatCount: 2,
      );
      service.book(
        eventId: 'test-evt',
        passengerName: 'User2',
        email: 'u2@mail.ru',
        seatCount: 3,
      );

      expect(service.bookings, hasLength(2));
      expect(service.getEventById('test-evt')!.availableSeats, 5);
    });
  });

  group('Негативные тесты — валидация имени', () {
    test('TC-N-001: пустое имя отклоняется', () {
      expect(service.validatePassengerName(''), isNotNull);
    });

    test('TC-N-002: имя из одного символа отклоняется', () {
      expect(service.validatePassengerName('А'), isNotNull);
    });

    test('TC-N-003: имя из пробелов отклоняется', () {
      expect(service.validatePassengerName('   '), isNotNull);
    });
  });

  group('Негативные тесты — валидация email', () {
    test('TC-N-004: email без @ отклоняется', () {
      expect(service.validateEmail('usermail.ru'), isNotNull);
    });

    test('TC-N-005: email без домена отклоняется', () {
      expect(service.validateEmail('user@'), isNotNull);
    });

    test('TC-N-006: email без локальной части отклоняется', () {
      expect(service.validateEmail('@mail.ru'), isNotNull);
    });

    test('TC-N-007: пустой email отклоняется', () {
      expect(service.validateEmail(''), isNotNull);
    });
  });

  group('Негативные тесты — валидация мест', () {
    test('TC-N-008: ноль мест отклоняется', () {
      expect(service.validateSeatCount(0, 10), isNotNull);
    });

    test('TC-N-009: отрицательное количество мест отклоняется', () {
      expect(service.validateSeatCount(-1, 10), isNotNull);
    });

    test('TC-N-010: превышение лимита за одно бронирование отклоняется', () {
      expect(
        service.validateSeatCount(BookingService.maxSeatCount + 1, 20),
        isNotNull,
      );
    });

    test('TC-N-011: бронирование больше доступных мест отклоняется', () {
      expect(service.validateSeatCount(5, 3), isNotNull);
    });
  });

  group('Негативные тесты — бронирование', () {
    test('TC-N-012: бронирование несуществующего мероприятия', () {
      final result = service.book(
        eventId: 'unknown',
        passengerName: 'Иван',
        email: 'ivan@mail.ru',
        seatCount: 1,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'Мероприятие не найдено');
    });

    test('TC-N-013: бронирование с невалидным email не создаёт запись', () {
      final result = service.book(
        eventId: 'test-evt',
        passengerName: 'Иван',
        email: 'bad-email',
        seatCount: 1,
      );

      expect(result.isSuccess, isFalse);
      expect(service.bookings, isEmpty);
    });

    test('TC-N-014: бронирование при нехватке мест не изменяет доступность', () {
      service.book(
        eventId: 'test-evt',
        passengerName: 'First',
        email: 'first@mail.ru',
        seatCount: 8,
      );

      final result = service.book(
        eventId: 'test-evt',
        passengerName: 'Second',
        email: 'second@mail.ru',
        seatCount: 5,
      );

      expect(result.isSuccess, isFalse);
      expect(service.getEventById('test-evt')!.availableSeats, 2);
    });

    test('TC-N-015: отмена несуществующего бронирования', () {
      final result = service.cancelBooking('bkg-999');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'Бронирование не найдено');
    });
  });

  group('Деструктивные тесты — защита от вредоносного ввода', () {
    test('TC-D-001: SQL-инъекция в имени отклоняется', () {
      expect(
        service.validatePassengerName("Robert'; DROP TABLE users;--"),
        isNotNull,
      );
    });

    test('TC-D-002: SQL DELETE в email отклоняется', () {
      expect(
        service.validateEmail('hack@mail.ru; DELETE FROM bookings'),
        isNotNull,
      );
    });

    test('TC-D-003: XSS script в имени отклоняется', () {
      expect(
        service.validatePassengerName('<script>alert(1)</script>'),
        isNotNull,
      );
    });

    test('TC-D-004: слишком длинное имя отклоняется', () {
      final longName = 'А' * (BookingService.maxPassengerNameLength + 1);
      expect(service.validatePassengerName(longName), isNotNull);
    });

    test('TC-D-005: слишком длинный email отклоняется', () {
      final longEmail = '${'a' * 250}@mail.ru';
      expect(service.validateEmail(longEmail), isNotNull);
    });

    test('TC-D-006: SQL-инъекция через book() не создаёт бронирование', () {
      final result = service.book(
        eventId: 'test-evt',
        passengerName: "Admin'--",
        email: 'test@mail.ru',
        seatCount: 1,
      );

      expect(result.isSuccess, isFalse);
      expect(service.bookings, isEmpty);
    });

    test('TC-D-007: многократные деструктивные попытки не ломают сервис', () {
      for (var i = 0; i < 50; i++) {
        service.book(
          eventId: 'test-evt',
          passengerName: '<script>DROP TABLE</script>',
          email: 'x@y.z',
          seatCount: 999,
        );
      }

      expect(service.getEventById('test-evt')!.availableSeats, 10);
      expect(service.bookings, isEmpty);

      final validResult = service.book(
        eventId: 'test-evt',
        passengerName: 'Нормальный пользователь',
        email: 'ok@mail.ru',
        seatCount: 1,
      );
      expect(validResult.isSuccess, isTrue);
    });

    test('TC-D-008: бронирование всех мест и попытка сверх лимита', () {
      service.book(
        eventId: 'test-evt',
        passengerName: 'Bulk',
        email: 'bulk@mail.ru',
        seatCount: 10,
      );

      final result = service.book(
        eventId: 'test-evt',
        passengerName: 'Late',
        email: 'late@mail.ru',
        seatCount: 1,
      );

      expect(result.isSuccess, isFalse);
      expect(service.getEventById('test-evt')!.availableSeats, 0);
    });
  });
}
