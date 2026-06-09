import 'booking.dart';

class BookingResult {
  const BookingResult.success(this.booking)
      : errorMessage = null,
        isSuccess = true;

  const BookingResult.failure(this.errorMessage)
      : booking = null,
        isSuccess = false;

  final bool isSuccess;
  final Booking? booking;
  final String? errorMessage;
}
