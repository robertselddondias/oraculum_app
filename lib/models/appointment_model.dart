class AppointmentModel {
  final String id;
  final String clientId;
  final String mediumId;
  final String mediumName;
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
  final String? cancelReason;
  final Map<String, dynamic>? paymentInfo;

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
    this.cancelReason,
    this.paymentInfo,
  });

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AppointmentModel(
      id: id,
      clientId: map['clientId'] ?? '',
      mediumId: map['mediumId'] ?? '',
      mediumName: map['mediumName'] ?? '',
      clientName: map['clientName'] ?? '',
      scheduledDate: DateTime.parse(map['scheduledDate']),
      duration: map['duration'] ?? 30,
      amount: (map['amount'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending',
      description: map['description'] ?? '',
      consultationType: map['consultationType'] ?? 'Consulta Geral',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      cancelReason: map['cancelReason'],
      paymentInfo: map['paymentInfo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'mediumId': mediumId,
      'mediumName': mediumName,
      'clientName': clientName,
      'scheduledDate': scheduledDate.toIso8601String(),
      'duration': duration,
      'amount': amount,
      'status': status,
      'description': description,
      'consultationType': consultationType,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'cancelReason': cancelReason,
      'paymentInfo': paymentInfo,
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
    String? cancelReason,
    Map<String, dynamic>? paymentInfo,
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
      cancelReason: cancelReason ?? this.cancelReason,
      paymentInfo: paymentInfo ?? this.paymentInfo,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'confirmed':
        return 'Confirmado';
      case 'completed':
        return 'Concluído';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconhecido';
    }
  }

  String get formattedAmount => 'R\$ ${amount.toStringAsFixed(2)}';

  String get formattedDuration => '$duration min';

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
