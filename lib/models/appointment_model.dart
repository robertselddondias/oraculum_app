import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String userId;
  final String mediumId;
  final DateTime dateTime;
  final int durationMinutes;
  final String status;
  final String paymentId;
  final double amount;
  final DateTime createdAt;
  final String? notes;
  final String? feedback;
  final double? rating;
  final String? userName;
  final String? userPhone;
  final String? userEmail;
  final String? mediumName;
  final String? mediumSpecialty;
  final String? cancelReason;
  final DateTime? canceledAt;
  final DateTime? completedAt;
  final String? type;
  final String? paymentStatus;
  final String? paymentMethod;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.mediumId,
    required this.dateTime,
    required this.durationMinutes,
    required this.status,
    required this.paymentId,
    required this.amount,
    required this.createdAt,
    this.notes,
    this.feedback,
    this.rating,
    this.userName,
    this.userPhone,
    this.userEmail,
    this.mediumName,
    this.mediumSpecialty,
    this.cancelReason,
    this.canceledAt,
    this.completedAt,
    this.type,
    this.paymentStatus,
    this.paymentMethod,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AppointmentModel(
      id: id,
      userId: map['userId'] ?? '',
      mediumId: map['mediumId'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      durationMinutes: map['durationMinutes'] ?? 0,
      status: map['status'] ?? 'pending',
      paymentId: map['paymentId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      notes: map['notes'],
      feedback: map['feedback'],
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      userName: map['userName'],
      userPhone: map['userPhone'],
      userEmail: map['userEmail'],
      mediumName: map['mediumName'],
      mediumSpecialty: map['mediumSpecialty'],
      cancelReason: map['cancelReason'],
      canceledAt: map['canceledAt'] != null ? (map['canceledAt'] as Timestamp).toDate() : null,
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
      type: map['type'],
      paymentStatus: map['paymentStatus'],
      paymentMethod: map['paymentMethod'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mediumId': mediumId,
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'status': status,
      'paymentId': paymentId,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
      'feedback': feedback,
      'rating': rating,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'mediumName': mediumName,
      'mediumSpecialty': mediumSpecialty,
      'cancelReason': cancelReason,
      'canceledAt': canceledAt != null ? Timestamp.fromDate(canceledAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'type': type,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? userId,
    String? mediumId,
    DateTime? dateTime,
    int? durationMinutes,
    String? status,
    String? paymentId,
    double? amount,
    DateTime? createdAt,
    String? notes,
    String? feedback,
    double? rating,
    String? userName,
    String? userPhone,
    String? userEmail,
    String? mediumName,
    String? mediumSpecialty,
    String? cancelReason,
    DateTime? canceledAt,
    DateTime? completedAt,
    String? type,
    String? paymentStatus,
    String? paymentMethod,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mediumId: mediumId ?? this.mediumId,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      paymentId: paymentId ?? this.paymentId,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      feedback: feedback ?? this.feedback,
      rating: rating ?? this.rating,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      mediumName: mediumName ?? this.mediumName,
      mediumSpecialty: mediumSpecialty ?? this.mediumSpecialty,
      cancelReason: cancelReason ?? this.cancelReason,
      canceledAt: canceledAt ?? this.canceledAt,
      completedAt: completedAt ?? this.completedAt,
      type: type ?? this.type,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  int get duration => durationMinutes;

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmado';
      case 'completed':
        return 'Concluído';
      case 'canceled':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  }

  String get formattedAmount {
    return 'R\$ ${amount.toStringAsFixed(2)}';
  }

  String get formattedDuration {
    return '${durationMinutes} min';
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCanceled => status == 'canceled';

  bool get canBeConfirmed => status == 'pending';
  bool get canBeCanceled => status == 'pending' || status == 'confirmed';
  bool get canBeCompleted => status == 'confirmed';

  DateTime get endTime => dateTime.add(Duration(minutes: durationMinutes));

  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get isFuture => dateTime.isAfter(DateTime.now());

  Duration get timeUntilAppointment => dateTime.difference(DateTime.now());
  Duration? get timeSinceAppointment => isPast ? DateTime.now().difference(dateTime) : null;
}
