import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickets/models/event.dart';
import 'package:tickets/screens/home_screen.dart';
import 'package:tickets/services/booking_service.dart';

void main() {
  late BookingService bookingService;

  final singleSeatEvent = Event(
    id: 'ui-evt',
    title: 'UI Тестовый концерт',
    venue: 'Малый зал',
    date: DateTime(2026, 8, 1, 19, 0),
    price: 500,
    totalSeats: 5,
  );

  setUp(() {
    bookingService = BookingService(initialEvents: [singleSeatEvent]);
  });

  Widget buildApp() {
    return MaterialApp(
      home: HomeScreen(bookingService: bookingService),
    );
  }

  group('UI — позитивные сценарии', () {
    testWidgets('TC-UI-P-001: отображается список мероприятий', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('UI Тестовый концерт'), findsOneWidget);
      expect(find.text('Бронирование билетов'), findsOneWidget);
      expect(find.byKey(const Key('book_event_ui-evt')), findsOneWidget);
    });

    testWidgets('TC-UI-P-002: успешное бронирование через диалог', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.byKey(const Key('book_event_ui-evt')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('passenger_name_field')),
        'Ольга Козлова',
      );
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'olga@example.com',
      );
      await tester.enterText(find.byKey(const Key('seats_field')), '2');
      await tester.tap(find.byKey(const Key('book_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Билет забронирован'), findsOneWidget);
      expect(bookingService.bookings, hasLength(1));
      expect(bookingService.getEventById('ui-evt')!.availableSeats, 3);
    });

    testWidgets('TC-UI-P-003: переход на вкладку «Мои билеты»', (tester) async {
      bookingService.book(
        eventId: 'ui-evt',
        passengerName: 'Алексей Пользователь',
        email: 'test@mail.ru',
        seatCount: 1,
      );

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Мои билеты'));
      await tester.pumpAndSettle();

      expect(find.text('UI Тестовый концерт'), findsOneWidget);
      expect(find.textContaining('Алексей Пользователь'), findsOneWidget);
    });

    testWidgets('TC-UI-P-004: отмена бронирования из списка', (tester) async {
      final booking = bookingService.book(
        eventId: 'ui-evt',
        passengerName: 'Cancel Me',
        email: 'cancel@mail.ru',
        seatCount: 1,
      ).booking!;

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Мои билеты'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('cancel_booking_${booking.id}')));
      await tester.pumpAndSettle();

      expect(find.text('Нет активных бронирований'), findsOneWidget);
      expect(bookingService.getEventById('ui-evt')!.availableSeats, 5);
    });
  });

  group('UI — негативные сценарии', () {
    testWidgets('TC-UI-N-001: пустая форма не отправляется', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.byKey(const Key('book_event_ui-evt')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('book_button')));
      await tester.pumpAndSettle();

      expect(bookingService.bookings, isEmpty);
      expect(find.byType(BookingFormDialog), findsOneWidget);
    });

    testWidgets('TC-UI-N-002: невалидный email показывает ошибку', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.byKey(const Key('book_event_ui-evt')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('passenger_name_field')),
        'Иван',
      );
      await tester.enterText(find.byKey(const Key('email_field')), 'not-an-email');
      await tester.tap(find.byKey(const Key('book_button')));
      await tester.pumpAndSettle();

      expect(bookingService.bookings, isEmpty);
      expect(find.text('Некорректный формат email'), findsOneWidget);
    });

    testWidgets('TC-UI-N-003: превышение мест блокирует бронирование', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.byKey(const Key('book_event_ui-evt')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('passenger_name_field')),
        'Иван',
      );
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'ivan@mail.ru',
      );
      await tester.enterText(find.byKey(const Key('seats_field')), '99');
      await tester.tap(find.byKey(const Key('book_button')));
      await tester.pumpAndSettle();

      expect(bookingService.bookings, isEmpty);
    });

    testWidgets('TC-UI-N-004: кнопка «Отмена» закрывает диалог', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.byKey(const Key('book_event_ui-evt')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pumpAndSettle();

      expect(find.byType(BookingFormDialog), findsNothing);
    });
  });

  group('UI — деструктивные сценарии', () {
    testWidgets('TC-UI-D-001: XSS в имени блокируется формой', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.byKey(const Key('book_event_ui-evt')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('passenger_name_field')),
        '<script>alert("xss")</script>',
      );
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'xss@mail.ru',
      );
      await tester.tap(find.byKey(const Key('book_button')));
      await tester.pumpAndSettle();

      expect(bookingService.bookings, isEmpty);
      expect(find.text('Имя содержит недопустимые символы'), findsOneWidget);
    });

    testWidgets('TC-UI-D-002: SQL-инъекция в email блокируется', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.byKey(const Key('book_event_ui-evt')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('passenger_name_field')),
        'Хакер',
      );
      await tester.enterText(
        find.byKey(const Key('email_field')),
        "a@b.ru'; DROP TABLE bookings;--",
      );
      await tester.tap(find.byKey(const Key('book_button')));
      await tester.pumpAndSettle();

      expect(bookingService.bookings, isEmpty);
    });
  });
}
