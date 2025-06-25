import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/models/appointment_model.dart';
import 'package:oraculum/models/medium_model.dart';

class AppointmentService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String appointmentsCollection = 'appointments';
  static const String mediumsCollection = 'mediums';
  static const String usersCollection = 'users';

  String? get currentUserId => _auth.currentUser?.uid;

  // ========== APPOINTMENT MANAGEMENT ==========

  /// Buscar todos os agendamentos do usuário atual
  Future<List<AppointmentModel>> getUserAppointments({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('Usuário não autenticado');
      }

      debugPrint('=== getUserAppointments() ===');
      debugPrint('UserId: $currentUserId');

      Query query = _firestore
          .collection(appointmentsCollection)
          .where('clientId', isEqualTo: currentUserId);

      if (startDate != null) {
        query = query.where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query
          .orderBy('scheduledDate', descending: true)
          .get();

      final appointments = <AppointmentModel>[];

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Enriquecer dados se necessário
          await _enrichAppointmentData(data);

          final appointment = AppointmentModel.fromMap(data, doc.id);
          appointments.add(appointment);
        } catch (e) {
          debugPrint('❌ Erro ao processar agendamento ${doc.id}: $e');
        }
      }

      debugPrint('✅ ${appointments.length} agendamentos carregados');
      return appointments;

    } catch (e) {
      debugPrint('❌ Erro ao buscar agendamentos: $e');
      throw Exception('Erro ao carregar agendamentos: $e');
    }
  }

  /// Stream para escutar agendamentos em tempo real
  Stream<List<AppointmentModel>> getUserAppointmentsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(appointmentsCollection)
        .where('clientId', isEqualTo: currentUserId)
        .orderBy('scheduledDate', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final appointments = <AppointmentModel>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          await _enrichAppointmentData(data);
          final appointment = AppointmentModel.fromMap(data, doc.id);
          appointments.add(appointment);
        } catch (e) {
          debugPrint('❌ Erro ao processar agendamento em stream ${doc.id}: $e');
        }
      }

      return appointments;
    });
  }

  /// Criar novo agendamento
  Future<String> createAppointment({
    required String mediumId,
    required DateTime scheduledDate,
    required int duration,
    required double amount,
    required String description,
    String consultationType = 'Consulta Geral',
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('Usuário não autenticado');
      }

      debugPrint('=== createAppointment() ===');

      final user = _auth.currentUser!;

      // Buscar dados do médium
      final mediumDoc = await _firestore.collection(mediumsCollection).doc(mediumId).get();
      if (!mediumDoc.exists) {
        throw Exception('Médium não encontrado');
      }

      final mediumData = mediumDoc.data()!;

      final appointmentData = {
        'clientId': currentUserId,
        'mediumId': mediumId,
        'mediumName': mediumData['name'] ?? 'Médium',
        'clientName': user.displayName ?? user.email ?? 'Cliente',
        'scheduledDate': Timestamp.fromDate(scheduledDate),
        'duration': duration,
        'amount': amount,
        'status': 'pending',
        'description': description,
        'consultationType': consultationType,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': null,
        'completedAt': null,
        'canceledAt': null,
        'cancelReason': null,
        'feedback': null,
        'rating': null,
        'paymentInfo': null,
        'paymentStatus': 'pending',
        'paymentMethod': null,
      };

      final docRef = await _firestore
          .collection(appointmentsCollection)
          .add(appointmentData);

      debugPrint('✅ Agendamento criado: ${docRef.id}');
      return docRef.id;

    } catch (e) {
      debugPrint('❌ Erro ao criar agendamento: $e');
      throw Exception('Erro ao criar agendamento: $e');
    }
  }

  /// Cancelar agendamento
  Future<void> cancelAppointment(String appointmentId, String reason) async {
    try {
      debugPrint('=== cancelAppointment() ===');
      debugPrint('AppointmentId: $appointmentId');

      final appointmentDoc = await _firestore
          .collection(appointmentsCollection)
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        throw Exception('Agendamento não encontrado');
      }

      final appointmentData = appointmentDoc.data()!;

      // Verificar se o usuário pode cancelar
      if (appointmentData['clientId'] != currentUserId) {
        throw Exception('Você não pode cancelar este agendamento');
      }

      final status = appointmentData['status'];
      if (status == 'cancelled' || status == 'canceled' || status == 'completed') {
        throw Exception('Este agendamento não pode ser cancelado');
      }

      await _firestore
          .collection(appointmentsCollection)
          .doc(appointmentId)
          .update({
        'status': 'cancelled',
        'cancelReason': reason,
        'canceledAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      debugPrint('✅ Agendamento cancelado: $appointmentId');

    } catch (e) {
      debugPrint('❌ Erro ao cancelar agendamento: $e');
      throw Exception('Erro ao cancelar agendamento: $e');
    }
  }

  /// Buscar agendamento específico
  Future<AppointmentModel?> getAppointment(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection(appointmentsCollection)
          .doc(appointmentId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      await _enrichAppointmentData(data);

      return AppointmentModel.fromMap(data, doc.id);

    } catch (e) {
      debugPrint('❌ Erro ao buscar agendamento: $e');
      return null;
    }
  }

  /// Atualizar agendamento
  Future<void> updateAppointment(String appointmentId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore
          .collection(appointmentsCollection)
          .doc(appointmentId)
          .update(updates);

      debugPrint('✅ Agendamento atualizado: $appointmentId');

    } catch (e) {
      debugPrint('❌ Erro ao atualizar agendamento: $e');
      throw Exception('Erro ao atualizar agendamento: $e');
    }
  }

  // ========== AVAILABILITY MANAGEMENT ==========

  /// Verificar horários disponíveis para um médium em uma data específica
  Future<List<String>> getAvailableTimes(String mediumId, DateTime date) async {
    try {
      debugPrint('=== getAvailableTimes() ===');
      debugPrint('MediumId: $mediumId, Date: $date');

      // Buscar configurações de disponibilidade do médium
      final mediumDoc = await _firestore.collection(mediumsCollection).doc(mediumId).get();
      if (!mediumDoc.exists) return [];

      final mediumData = mediumDoc.data()!;
      final availability = mediumData['availability'] as Map<String, dynamic>? ?? {};

      final weekday = _getWeekdayString(date.weekday);
      final dayAvailability = availability[weekday] as Map<String, dynamic>?;

      if (dayAvailability == null || dayAvailability['isAvailable'] != true) {
        debugPrint('Médium não disponível neste dia');
        return [];
      }

      final startTime = dayAvailability['startTime'] as String? ?? '09:00';
      final endTime = dayAvailability['endTime'] as String? ?? '18:00';

      // Gerar slots de tempo
      final timeSlots = _generateTimeSlots(startTime, endTime);

      // Buscar horários já ocupados
      final bookedTimes = await _getBookedTimes(mediumId, date);

      // Filtrar horários disponíveis
      final availableTimes = timeSlots.where((time) => !bookedTimes.contains(time)).toList();

      debugPrint('✅ ${availableTimes.length} horários disponíveis encontrados');
      return availableTimes;

    } catch (e) {
      debugPrint('❌ Erro ao buscar horários disponíveis: $e');
      return [];
    }
  }

  /// Verificar se um horário específico está disponível
  Future<bool> isTimeSlotAvailable(String mediumId, DateTime dateTime) async {
    try {
      final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

      final availableTimes = await getAvailableTimes(mediumId, date);
      return availableTimes.contains(time);

    } catch (e) {
      debugPrint('❌ Erro ao verificar disponibilidade: $e');
      return false;
    }
  }

  // ========== HELPER METHODS ==========

  /// Enriquecer dados do agendamento com informações do médium e cliente
  Future<void> _enrichAppointmentData(Map<String, dynamic> appointmentData) async {
    try {
      final mediumId = appointmentData['mediumId'];
      final clientId = appointmentData['clientId'];

      // Buscar dados do médium se não existirem
      if (mediumId != null && (appointmentData['mediumName'] == null || appointmentData['mediumName'].toString().isEmpty)) {
        final mediumDoc = await _firestore.collection(mediumsCollection).doc(mediumId).get();
        if (mediumDoc.exists) {
          final mediumData = mediumDoc.data()!;
          appointmentData['mediumName'] = mediumData['name'] ?? 'Médium';
        }
      }

      // Buscar dados do cliente se não existirem
      if (clientId != null && (appointmentData['clientName'] == null || appointmentData['clientName'].toString().isEmpty)) {
        final userDoc = await _firestore.collection(usersCollection).doc(clientId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          appointmentData['clientName'] = userData['name'] ?? userData['displayName'] ?? 'Cliente';
        }
      }

    } catch (e) {
      debugPrint('❌ Erro ao enriquecer dados: $e');
    }
  }

  /// Gerar slots de tempo disponíveis
  List<String> _generateTimeSlots(String startTime, String endTime) {
    final times = <String>[];
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);

    DateTime current = start;
    while (current.isBefore(end)) {
      times.add('${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}');
      current = current.add(const Duration(minutes: 30)); // Slots de 30 minutos
    }

    return times;
  }

  /// Converter string de tempo para DateTime
  DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Converter número do dia da semana para string
  String _getWeekdayString(int weekday) {
    const weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return weekdays[weekday - 1];
  }

  /// Buscar horários já ocupados em uma data
  Future<List<String>> _getBookedTimes(String mediumId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(appointmentsCollection)
          .where('mediumId', isEqualTo: mediumId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('scheduledDate', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final scheduledDate = (data['scheduledDate'] as Timestamp).toDate();
        return '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
      }).toList();

    } catch (e) {
      debugPrint('❌ Erro ao buscar horários ocupados: $e');
      return [];
    }
  }

  // ========== FILTERING METHODS ==========

  /// Filtrar agendamentos por status
  List<AppointmentModel> filterByStatus(List<AppointmentModel> appointments, String status) {
    return appointments.where((appointment) => appointment.status == status).toList();
  }

  /// Filtrar agendamentos próximos (pendentes ou confirmados e futuros)
  List<AppointmentModel> getUpcomingAppointments(List<AppointmentModel> appointments) {
    final now = DateTime.now();
    return appointments.where((appointment) =>
    (appointment.isPending || appointment.isConfirmed) &&
        appointment.scheduledDate.isAfter(now)
    ).toList();
  }

  /// Filtrar agendamentos concluídos
  List<AppointmentModel> getCompletedAppointments(List<AppointmentModel> appointments) {
    return appointments.where((appointment) => appointment.isCompleted).toList();
  }

  /// Filtrar agendamentos cancelados
  List<AppointmentModel> getCancelledAppointments(List<AppointmentModel> appointments) {
    return appointments.where((appointment) => appointment.isCancelled).toList();
  }

  /// Filtrar agendamentos por período
  List<AppointmentModel> filterByDateRange(
      List<AppointmentModel> appointments,
      DateTime startDate,
      DateTime endDate,
      ) {
    return appointments.where((appointment) =>
    appointment.scheduledDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
        appointment.scheduledDate.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  // ========== STATISTICS METHODS ==========

  /// Obter estatísticas dos agendamentos do usuário
  Map<String, int> getAppointmentStats(List<AppointmentModel> appointments) {
    return {
      'total': appointments.length,
      'pending': appointments.where((a) => a.isPending).length,
      'confirmed': appointments.where((a) => a.isConfirmed).length,
      'completed': appointments.where((a) => a.isCompleted).length,
      'cancelled': appointments.where((a) => a.isCancelled).length,
      'upcoming': getUpcomingAppointments(appointments).length,
    };
  }

  /// Calcular valor total gasto em agendamentos
  double getTotalAmountSpent(List<AppointmentModel> appointments) {
    return appointments
        .where((a) => a.isCompleted)
        .fold(0.0, (sum, appointment) => sum + appointment.amount);
  }

  /// Obter médium mais consultado
  String? getMostConsultedMedium(List<AppointmentModel> appointments) {
    if (appointments.isEmpty) return null;

    final mediumCounts = <String, int>{};
    for (final appointment in appointments) {
      mediumCounts[appointment.mediumName] = (mediumCounts[appointment.mediumName] ?? 0) + 1;
    }

    return mediumCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
