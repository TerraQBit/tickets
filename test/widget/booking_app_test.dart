import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickets/models/flight.dart';
import 'package:tickets/models/service_class.dart';
import 'package:tickets/screens/home_screen.dart';
import 'package:tickets/services/booking_service.dart';

void main() {
  late BookingService bookingService;

  final testFlight = Flight(
    id: 'ui-flt',
    origin: 'Москва',
    destination: 'Санкт-Петербург',
    departureDateTime: DateTime(2026, 6, 15, 8, 30),
    basePrice: 5000,
    totalSeats: 50,
    airline: 'UI Авиа',
  );

  setUp(() {
    bookingService = BookingService(initialFlights: [testFlight]);
  });

  Widget buildApp() {
    return MaterialApp(
      home: HomeScreen(bookingService: bookingService),
    );
  }

  Future<void> fillSearchForm(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('origin_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Москва').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('destination_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Санкт-Петербург').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('departure_date_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('return_date_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  group('UI — позитивные сценарии', () {
    testWidgets('TC-UI-P-001: отображается форма поиска авиабилетов', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Авиабилеты'), findsOneWidget);
      expect(find.text('Поиск авиабилетов'), findsOneWidget);
      expect(find.byKey(const Key('departure_date_field')), findsOneWidget);
      expect(find.byKey(const Key('return_date_field')), findsOneWidget);
      expect(find.byKey(const Key('adults_field')), findsOneWidget);
      expect(find.byKey(const Key('children_field')), findsOneWidget);
      expect(find.byKey(const Key('service_class_field')), findsOneWidget);
    });

    testWidgets('TC-UI-P-002: поиск и бронирование через диалог', (tester) async {
      await tester.pumpWidget(buildApp());
      await fillSearchForm(tester);

      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('book_flight_ui-flt')), findsOneWidget);

      await tester.tap(find.byKey(const Key('book_flight_ui-flt')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('passenger_name_field')),
        'Ольга Козлова',
      );
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'olga@example.com',
      );
      await tester.tap(find.byKey(const Key('book_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Билет забронирован'), findsOneWidget);
      expect(bookingService.bookings, hasLength(1));
      expect(bookingService.getFlightById('ui-flt')!.availableSeats, 49);
    });

    testWidgets('TC-UI-P-003: переход на вкладку «Мои билеты»', (tester) async {
      bookingService.book(
        flightId: 'ui-flt',
        passengerName: 'Алексей Пользователь',
        email: 'test@mail.ru',
        departureDate: DateTime(2026, 6, 15),
        returnDate: DateTime(2026, 6, 20),
        adults: 1,
        children: 0,
        serviceClass: ServiceClass.economy,
      );

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Мои билеты'));
      await tester.pumpAndSettle();

      expect(find.text('Москва → Санкт-Петербург'), findsOneWidget);
      expect(find.textContaining('Алексей Пользователь'), findsOneWidget);
    });

    testWidgets('TC-UI-P-004: отмена бронирования из списка', (tester) async {
      final booking = bookingService.book(
        flightId: 'ui-flt',
        passengerName: 'Cancel Me',
        email: 'cancel@mail.ru',
        departureDate: DateTime(2026, 6, 15),
        returnDate: DateTime(2026, 6, 20),
        adults: 1,
        children: 0,
        serviceClass: ServiceClass.economy,
      ).booking!;

      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Мои билеты'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('cancel_booking_${booking.id}')));
      await tester.pumpAndSettle();

      expect(find.text('Нет активных бронирований'), findsOneWidget);
      expect(bookingService.getFlightById('ui-flt')!.availableSeats, 50);
    });
  });

  group('UI — негативные сценарии', () {
    testWidgets('TC-UI-N-001: поиск без городов не выполняется', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      expect(find.text('Введите параметры и нажмите «Найти билеты»'), findsOneWidget);
    });

    testWidgets('TC-UI-N-002: невалидный email показывает ошибку', (tester) async {
      await tester.pumpWidget(buildApp());
      await fillSearchForm(tester);

      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('book_flight_ui-flt')));
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

    testWidgets('TC-UI-N-003: кнопка «Отмена» закрывает диалог', (tester) async {
      await tester.pumpWidget(buildApp());
      await fillSearchForm(tester);

      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('book_flight_ui-flt')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pumpAndSettle();

      expect(find.byType(BookingFormDialog), findsNothing);
    });
  });

  group('UI — деструктивные сценарии', () {
    testWidgets('TC-UI-D-001: XSS в имени блокируется формой', (tester) async {
      await tester.pumpWidget(buildApp());
      await fillSearchForm(tester);

      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('book_flight_ui-flt')));
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
  });
}
