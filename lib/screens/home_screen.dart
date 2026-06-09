import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/booking.dart';
import '../models/event.dart';
import '../services/booking_service.dart';

class BookingFormDialog extends StatefulWidget {
  const BookingFormDialog({
    super.key,
    required this.event,
    required this.bookingService,
  });

  final Event event;
  final BookingService bookingService;

  @override
  State<BookingFormDialog> createState() => _BookingFormDialogState();
}

class _BookingFormDialogState extends State<BookingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _seatsController = TextEditingController(text: '1');

  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final seatCount = int.parse(_seatsController.text.trim());
    final result = widget.bookingService.book(
      eventId: widget.event.id,
      passengerName: _nameController.text,
      email: _emailController.text,
      seatCount: seatCount,
    );

    if (result.isSuccess) {
      Navigator.of(context).pop(result.booking);
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice =
        widget.event.price * (int.tryParse(_seatsController.text) ?? 1);

    return AlertDialog(
      title: Text('Бронирование: ${widget.event.title}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Свободных мест: ${widget.event.availableSeats}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('passenger_name_field'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Имя пассажира',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    widget.bookingService.validatePassengerName(value ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('email_field'),
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    widget.bookingService.validateEmail(value ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('seats_field'),
                controller: _seatsController,
                decoration: InputDecoration(
                  labelText: 'Количество мест (макс. ${BookingService.maxSeatCount})',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final count = int.tryParse(value?.trim() ?? '');
                  if (count == null) {
                    return 'Введите количество мест';
                  }
                  return widget.bookingService.validateSeatCount(
                    count,
                    widget.event.availableSeats,
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Итого: ${totalPrice.toStringAsFixed(0)} ₽',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('cancel_button'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          key: const Key('book_button'),
          onPressed: _submit,
          child: const Text('Забронировать'),
        ),
      ],
    );
  }
}

class BookingsListScreen extends StatelessWidget {
  const BookingsListScreen({
    super.key,
    required this.bookingService,
    required this.onBookingCancelled,
  });

  final BookingService bookingService;
  final VoidCallback onBookingCancelled;

  String _eventTitle(String eventId) {
    return bookingService.getEventById(eventId)?.title ?? 'Неизвестно';
  }

  @override
  Widget build(BuildContext context) {
    final bookings = bookingService.bookings;

    if (bookings.isEmpty) {
      return const Center(
        child: Text('Нет активных бронирований'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return Card(
          key: Key('booking_card_${booking.id}'),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(_eventTitle(booking.eventId)),
            subtitle: Text(
              '${booking.passengerName} • ${booking.seatCount} мест(а)\n'
              '${booking.totalPrice.toStringAsFixed(0)} ₽',
            ),
            isThreeLine: true,
            trailing: IconButton(
              key: Key('cancel_booking_${booking.id}'),
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Отменить бронирование',
              onPressed: () {
                bookingService.cancelBooking(booking.id);
                onBookingCancelled();
              },
            ),
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.bookingService});

  final BookingService bookingService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  void _refresh() => setState(() {});

  Future<void> _openBookingDialog(Event event) async {
    final booking = await showDialog<Booking>(
      context: context,
      builder: (context) => BookingFormDialog(
        event: widget.bookingService.getEventById(event.id) ?? event,
        bookingService: widget.bookingService,
      ),
    );

    if (booking != null && mounted) {
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Билет забронирован! Номер: ${booking.id}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Бронирование билетов'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _selectedTab == 0
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.bookingService.events.length,
              itemBuilder: (context, index) {
                final event = widget.bookingService.events[index];
                return Card(
                  key: Key('event_card_${event.id}'),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(event.title),
                    subtitle: Text(
                      '${event.venue}\n'
                      '${_formatDate(event.date)} • '
                      '${event.price.toStringAsFixed(0)} ₽\n'
                      'Свободно мест: ${event.availableSeats}',
                    ),
                    isThreeLine: true,
                    trailing: FilledButton(
                      key: Key('book_event_${event.id}'),
                      onPressed: event.availableSeats > 0
                          ? () => _openBookingDialog(event)
                          : null,
                      child: const Text('Купить'),
                    ),
                  ),
                );
              },
            )
          : BookingsListScreen(
              bookingService: widget.bookingService,
              onBookingCancelled: _refresh,
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event),
            label: 'Мероприятия',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number),
            label: 'Мои билеты',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
