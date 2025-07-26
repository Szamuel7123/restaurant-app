import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum BookingStatus { pending, confirmed, cancelled, completed, noShow }

enum TableSize { small, medium, large, party }

class TableBookingModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String tableNumber;
  final TableSize tableSize;
  final int numberOfGuests;
  final DateTime bookingDate;
  final TimeOfDay bookingTime;
  final int durationMinutes;
  final BookingStatus status;
  final String? specialRequests;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  TableBookingModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.tableNumber,
    required this.tableSize,
    required this.numberOfGuests,
    required this.bookingDate,
    required this.bookingTime,
    this.durationMinutes = 120,
    required this.status,
    this.specialRequests,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  factory TableBookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timeData = data['bookingTime'] as Map<String, dynamic>;

    return TableBookingModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      tableNumber: data['tableNumber'] ?? '',
      tableSize: TableSize.values.firstWhere(
        (size) =>
            size.toString() == 'TableSize.${data['tableSize'] ?? 'medium'}',
        orElse: () => TableSize.medium,
      ),
      numberOfGuests: data['numberOfGuests'] ?? 2,
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      bookingTime: TimeOfDay(
        hour: timeData['hour'] ?? 12,
        minute: timeData['minute'] ?? 0,
      ),
      durationMinutes: data['durationMinutes'] ?? 120,
      status: BookingStatus.values.firstWhere(
        (status) =>
            status.toString() == 'BookingStatus.${data['status'] ?? 'pending'}',
        orElse: () => BookingStatus.pending,
      ),
      specialRequests: data['specialRequests'],
      cancellationReason: data['cancellationReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'tableNumber': tableNumber,
      'tableSize': tableSize.toString().split('.').last,
      'numberOfGuests': numberOfGuests,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'bookingTime': {
        'hour': bookingTime.hour,
        'minute': bookingTime.minute,
      },
      'durationMinutes': durationMinutes,
      'status': status.toString().split('.').last,
      'specialRequests': specialRequests,
      'cancellationReason': cancellationReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  String get statusDisplayName {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.noShow:
        return 'No Show';
    }
  }

  String get formattedBookingTime {
    return '${bookingTime.hour.toString().padLeft(2, '0')}:${bookingTime.minute.toString().padLeft(2, '0')}';
  }

  String get formattedBookingDate {
    return '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}';
  }

  DateTime get bookingDateTime {
    return DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
      bookingTime.hour,
      bookingTime.minute,
    );
  }

  bool get isUpcoming {
    return bookingDateTime.isAfter(DateTime.now());
  }

  bool get canBeCancelled {
    return status == BookingStatus.pending || status == BookingStatus.confirmed;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TableBookingModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
