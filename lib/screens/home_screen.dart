import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/booking.dart';
import '../models/flight.dart';
import '../models/service_class.dart';
import '../services/booking_service.dart';

class BookingFormDialog extends StatefulWidget {
  const BookingFormDialog({
    super.key,
    required this.flight,
    required this.bookingService,
    required this.departureDate,
    required this.returnDate,
    required this.adults,
    required this.children,
    required this.serviceClass,
  });

  final Flight flight;
  final BookingService bookingService;
  final DateTime departureDate;
  final DateTime returnDate;
  final int adults;
  final int children;
  final ServiceClass serviceClass;

  @override
  State<BookingFormDialog> createState() => _BookingFormDialogState();
}

class _BookingFormDialogState extends State<BookingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    final result = widget.bookingService.book(
      flightId: widget.flight.id,
      passengerName: _nameController.text,
      email: _emailController.text,
      departureDate: widget.departureDate,
      returnDate: widget.returnDate,
      adults: widget.adults,
      children: widget.children,
      serviceClass: widget.serviceClass,
    );

    if (result.isSuccess) {
      Navigator.of(context).pop(result.booking);
    } else {
      setState(() => _errorMessage = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.bookingService.calculatePrice(
      flight: widget.flight,
      adults: widget.adults,
      children: widget.children,
      serviceClass: widget.serviceClass,
    );

    return AlertDialog(
      title: Text(
        '${widget.flight.origin} → ${widget.flight.destination}',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.flight.airline} • ${widget.serviceClass.label}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'Взрослые: ${widget.adults}, дети: ${widget.children}',
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

  String _flightRoute(String flightId) {
    final flight = bookingService.getFlightById(flightId);
    if (flight == null) return 'Неизвестный рейс';
    return '${flight.origin} → ${flight.destination}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bookings = bookingService.bookings;

    if (bookings.isEmpty) {
      return const Center(child: Text('Нет активных бронирований'));
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
            leading: const Icon(Icons.flight),
            title: Text(_flightRoute(booking.flightId)),
            subtitle: Text(
              '${booking.passengerName}\n'
              'Вылет: ${_formatDate(booking.departureDate)} • '
              'Возврат: ${_formatDate(booking.returnDate)}\n'
              '${booking.serviceClass.label} • '
              'Взр.: ${booking.adults}, дети: ${booking.children}\n'
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
  List<Flight> _searchResults = [];
  DateTime? _lastDepartureDate;
  DateTime? _lastReturnDate;
  int _lastAdults = 1;
  int _lastChildren = 0;
  ServiceClass _lastServiceClass = ServiceClass.economy;

  void _refresh() => setState(() {});

  void _onSearch(List<Flight> results, _SearchParams params) {
    _lastDepartureDate = params.departureDate;
    _lastReturnDate = params.returnDate;
    _lastAdults = params.adults;
    _lastChildren = params.children;
    _lastServiceClass = params.serviceClass;
    setState(() => _searchResults = results);
  }

  Future<void> _openBookingDialog(Flight flight) async {
    final booking = await showDialog<Booking>(
      context: context,
      builder: (context) => BookingFormDialog(
        flight: widget.bookingService.getFlightById(flight.id) ?? flight,
        bookingService: widget.bookingService,
        departureDate: _lastDepartureDate!,
        returnDate: _lastReturnDate!,
        adults: _lastAdults,
        children: _lastChildren,
        serviceClass: _lastServiceClass,
      ),
    );

    if (booking != null && mounted) {
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Билет забронирован! Номер: ${booking.id}'),
        ),
      );
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Авиабилеты'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _selectedTab == 0
          ? _SearchTab(
              bookingService: widget.bookingService,
              onSearch: _onSearch,
              searchResults: _searchResults,
              lastAdults: _lastAdults,
              lastChildren: _lastChildren,
              lastServiceClass: _lastServiceClass,
              onBookFlight: _openBookingDialog,
              formatTime: _formatTime,
              calculatePrice: widget.bookingService.calculatePrice,
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
            icon: Icon(Icons.search),
            label: 'Поиск',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number),
            label: 'Мои билеты',
          ),
        ],
      ),
    );
  }
}

class _SearchParams {
  const _SearchParams({
    required this.departureDate,
    required this.returnDate,
    required this.adults,
    required this.children,
    required this.serviceClass,
  });

  final DateTime departureDate;
  final DateTime returnDate;
  final int adults;
  final int children;
  final ServiceClass serviceClass;
}

class _SearchTab extends StatefulWidget {
  const _SearchTab({
    required this.bookingService,
    required this.onSearch,
    required this.searchResults,
    required this.lastAdults,
    required this.lastChildren,
    required this.lastServiceClass,
    required this.onBookFlight,
    required this.formatTime,
    required this.calculatePrice,
  });

  final BookingService bookingService;
  final void Function(List<Flight> results, _SearchParams params) onSearch;
  final List<Flight> searchResults;
  final int lastAdults;
  final int lastChildren;
  final ServiceClass lastServiceClass;
  final Future<void> Function(Flight) onBookFlight;
  final String Function(DateTime) formatTime;
  final double Function({
    required Flight flight,
    required int adults,
    required int children,
    required ServiceClass serviceClass,
  }) calculatePrice;

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final _formKey = GlobalKey<FormState>();
  final _adultsController = TextEditingController(text: '1');
  final _childrenController = TextEditingController(text: '0');

  String? _origin;
  String? _destination;
  DateTime? _departureDate;
  DateTime? _returnDate;
  ServiceClass _serviceClass = ServiceClass.economy;

  @override
  void dispose() {
    _adultsController.dispose();
    _childrenController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required bool isDeparture,
    DateTime? initial,
    DateTime? firstDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: firstDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      if (isDeparture) {
        _departureDate = picked;
        if (_returnDate != null && _returnDate!.isBefore(picked)) {
          _returnDate = picked;
        }
      } else {
        _returnDate = picked;
      }
    });
  }

  void _search() {
    if (_departureDate == null || _returnDate == null) {
      setState(() {});
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final adults = int.parse(_adultsController.text.trim());
    final children = int.parse(_childrenController.text.trim());

    final results = widget.bookingService.searchFlights(
      origin: _origin!,
      destination: _destination!,
      departureDate: _departureDate!,
      returnDate: _returnDate!,
      adults: adults,
      children: children,
      serviceClass: _serviceClass,
    );

    widget.onSearch(
      results,
      _SearchParams(
        departureDate: _departureDate!,
        returnDate: _returnDate!,
        adults: adults,
        children: children,
        serviceClass: _serviceClass,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Выберите дату';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cities = widget.bookingService.cities;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Поиск авиабилетов',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: const Key('origin_field'),
                      initialValue: _origin,
                      decoration: const InputDecoration(
                        labelText: 'Откуда',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flight_takeoff),
                      ),
                      items: cities
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) => setState(() => _origin = value),
                      validator: (value) =>
                          value == null ? 'Выберите город отправления' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const Key('destination_field'),
                      initialValue: _destination,
                      decoration: const InputDecoration(
                        labelText: 'Куда',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flight_land),
                      ),
                      items: cities
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) => setState(() => _destination = value),
                      validator: (value) =>
                          value == null ? 'Выберите город назначения' : null,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      key: const Key('departure_date_field'),
                      onTap: () =>
                          _pickDate(isDeparture: true, initial: _departureDate),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Дата вылета',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(_formatDate(_departureDate)),
                      ),
                    ),
                    if (_departureDate == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Выберите дату вылета',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    InkWell(
                      key: const Key('return_date_field'),
                      onTap: () => _pickDate(
                        isDeparture: false,
                        initial: _returnDate ?? _departureDate,
                        firstDate: _departureDate ?? DateTime.now(),
                      ),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Дата возвращения',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        child: Text(_formatDate(_returnDate)),
                      ),
                    ),
                    if (_returnDate == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Выберите дату возвращения',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const Key('adults_field'),
                            controller: _adultsController,
                            decoration: const InputDecoration(
                              labelText: 'Взрослые',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters:
                                [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              final count = int.tryParse(value?.trim() ?? '');
                              if (count == null) return 'Введите число';
                              return widget.bookingService.validateAdults(count);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            key: const Key('children_field'),
                            controller: _childrenController,
                            decoration: const InputDecoration(
                              labelText: 'Дети',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.child_care),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters:
                                [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              final count = int.tryParse(value?.trim() ?? '');
                              if (count == null) return 'Введите число';
                              return widget.bookingService
                                  .validateChildren(count);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ServiceClass>(
                      key: const Key('service_class_field'),
                      initialValue: _serviceClass,
                      decoration: const InputDecoration(
                        labelText: 'Класс обслуживания',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.airline_seat_recline_extra),
                      ),
                      items: ServiceClass.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _serviceClass = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      key: const Key('search_button'),
                      onPressed: _search,
                      icon: const Icon(Icons.search),
                      label: const Text('Найти билеты'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.searchResults.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('Введите параметры и нажмите «Найти билеты»'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final flight = widget.searchResults[index];
                  final price = widget.calculatePrice(
                    flight: flight,
                    adults: widget.lastAdults,
                    children: widget.lastChildren,
                    serviceClass: widget.lastServiceClass,
                  );

                  return Card(
                    key: Key('flight_card_${flight.id}'),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.flight, size: 32),
                      title: Text('${flight.origin} → ${flight.destination}'),
                      subtitle: Text(
                        '${flight.airline}\n'
                        'Вылет: ${widget.formatTime(flight.departureDateTime)} • '
                        'Свободно мест: ${flight.availableSeats}',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${price.toStringAsFixed(0)} ₽',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          FilledButton(
                            key: Key('book_flight_${flight.id}'),
                            onPressed: () => widget.onBookFlight(flight),
                            child: const Text('Купить'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: widget.searchResults.length,
              ),
            ),
          ),
      ],
    );
  }
}
