import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String clientId;
  final String mediumId;
  final String mediumName;
  final String? mediumImageUrl;
  final String clientName;
  final DateTime scheduledDate;
  final int duration;
  final double amount;
  final String status;
  final String description;
  final String consultationType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final DateTime? canceledAt;
  final String? cancelReason;
  final String? feedback;
  final double? rating;
  final Map<String, dynamic>? paymentInfo;
  final String? paymentStatus;
  final String? paymentMethod;

  AppointmentModel({
    required this.id,
    required this.clientId,
    required this.mediumId,
    required this.mediumName,
    required this.clientName,
    required this.scheduledDate,
    required this.duration,
    required this.amount,
    required this.status,
    this.description = '',
    this.consultationType = 'Consulta Geral',
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.canceledAt,
    this.cancelReason,
    this.feedback,
    this.rating,
    this.paymentInfo,
    this.paymentStatus,
    this.paymentMethod,
    this.mediumImageUrl
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AppointmentModel(
      id: id,
      clientId: map['clientId'] ?? '',
      mediumId: map['mediumId'] ?? '',
      mediumName: map['mediumName'] ?? '',
      clientName: map['clientName'] ?? '',
      scheduledDate: _parseDateTime(map['scheduledDate']),
      duration: map['duration'] ?? 30,
      amount: (map['amount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      description: map['description'] ?? '',
      consultationType: map['consultationType'] ?? 'Consulta Geral',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? _parseDateTime(map['updatedAt']) : null,
      completedAt: map['completedAt'] != null ? _parseDateTime(map['completedAt']) : null,
      canceledAt: map['canceledAt'] != null ? _parseDateTime(map['canceledAt']) : null,
      cancelReason: map['cancelReason'],
      feedback: map['feedback'],
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      paymentInfo: map['paymentInfo'],
      paymentStatus: map['paymentStatus'],
      paymentMethod: map['paymentMethod'],
      mediumImageUrl: map['mediumImageUrl'],
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'mediumId': mediumId,
      'mediumName': mediumName,
      'clientName': clientName,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'duration': duration,
      'amount': amount,
      'status': status,
      'description': description,
      'consultationType': consultationType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'canceledAt': canceledAt != null ? Timestamp.fromDate(canceledAt!) : null,
      'cancelReason': cancelReason,
      'feedback': feedback,
      'rating': rating,
      'paymentInfo': paymentInfo,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'mediumImageUrl': mediumImageUrl
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? clientId,
    String? mediumId,
    String? mediumName,
    String? clientName,
    DateTime? scheduledDate,
    int? duration,
    double? amount,
    String? status,
    String? description,
    String? consultationType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? canceledAt,
    String? cancelReason,
    String? feedback,
    double? rating,
    Map<String, dynamic>? paymentInfo,
    String? paymentStatus,
    String? paymentMethod,
    String? mediumImageUrl
  }) {
    return AppointmentModel(
        id: id ?? this.id,
        clientId: clientId ?? this.clientId,
        mediumId: mediumId ?? this.mediumId,
        mediumName: mediumName ?? this.mediumName,
        clientName: clientName ?? this.clientName,
        scheduledDate: scheduledDate ?? this.scheduledDate,
        duration: duration ?? this.duration,
        amount: amount ?? this.amount,
        status: status ?? this.status,
        description: description ?? this.description,
        consultationType: consultationType ?? this.consultationType,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        completedAt: completedAt ?? this.completedAt,
        canceledAt: canceledAt ?? this.canceledAt,
        cancelReason: cancelReason ?? this.cancelReason,
        feedback: feedback ?? this.feedback,
        rating: rating ?? this.rating,
        paymentInfo: paymentInfo ?? this.paymentInfo,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        mediumImageUrl: mediumImageUrl ?? this.mediumImageUrl
    );
  }

  // Status getters
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled' || status == 'canceled';

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmado';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
      case 'canceled':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  }

  // Formatters
  String get formattedAmount => 'R\$ ${amount.toStringAsFixed(2)}';
  String get formattedDuration => '$duration min';

  // Helper methods
  bool get canBeCancelled {
    return (isPending || isConfirmed) &&
        scheduledDate.isAfter(DateTime.now().add(const Duration(hours: 2)));
  }

  bool get isUpcoming {
    return (isPending || isConfirmed) &&
        scheduledDate.isAfter(DateTime.now());
  }

  @override
  String toString() {
    return 'AppointmentModel(id: $id, mediumName: $mediumName, scheduledDate: $scheduledDate, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppointmentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
