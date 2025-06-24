import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/models/appointment_model.dart';
import 'package:oraculum/models/medium_model.dart';

class AppointmentController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxBool isLoading = false.obs;
  final RxList<AppointmentModel> appointments = <AppointmentModel>[].obs;
  final RxList<String> availableTimes = <String>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxString selectedTime = ''.obs;
  final RxInt selectedDuration = 30.obs;
  final RxDouble totalAmount = 0.0.obs;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    loadUserAppointments();
  }

  Future<void> loadUserAppointments() async {
    if (currentUserId == null) return;

    try {
      isLoading.value = true;
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('clientId', isEqualTo: currentUserId)
          .orderBy('scheduledDate', descending: true)
          .get();

      appointments.value = querySnapshot.docs.map((doc) {
        return AppointmentModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Erro ao carregar agendamentos: $e');
      Get.snackbar(
        'Erro',
        'Erro ao carregar agendamentos',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<String>> getAvailableTimes(String mediumId, DateTime date) async {
    try {
      final mediumDoc = await _firestore.collection('mediums').doc(mediumId).get();
      if (!mediumDoc.exists) return [];

      final mediumData = mediumDoc.data() as Map<String, dynamic>;
      final availability = mediumData['availability'] as Map<String, dynamic>? ?? {};

      final weekday = _getWeekdayString(date.weekday);
      final dayAvailability = availability[weekday] as Map<String, dynamic>?;

      if (dayAvailability == null || dayAvailability['isAvailable'] != true) {
        return [];
      }

      final startTime = dayAvailability['startTime'] as String? ?? '09:00';
      final endTime = dayAvailability['endTime'] as String? ?? '18:00';

      final times = _generateTimeSlots(startTime, endTime);

      final bookedTimes = await _getBookedTimes(mediumId, date);

      return times.where((time) => !bookedTimes.contains(time)).toList();
    } catch (e) {
      debugPrint('Erro ao buscar horários disponíveis: $e');
      return [];
    }
  }

  List<String> _generateTimeSlots(String startTime, String endTime) {
    final times = <String>[];
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);

    DateTime current = start;
    while (current.isBefore(end)) {
      times.add('${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}');
      current = current.add(const Duration(minutes: 30));
    }

    return times;
  }

  DateTime _parseTime(String timeString) {
    final parts = timeString.split(':');
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  String _getWeekdayString(int weekday) {
    const weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return weekdays[weekday - 1];
  }

  Future<List<String>> _getBookedTimes(String mediumId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection('appointments')
          .where('mediumId', isEqualTo: mediumId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .where('scheduledDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('scheduledDate', isLessThan: endOfDay.toIso8601String())
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        final scheduledDate = DateTime.parse(data['scheduledDate']);
        return '${scheduledDate.hour.toString().padLeft(2, '0')}:${scheduledDate.minute.toString().padLeft(2, '0')}';
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar horários ocupados: $e');
      return [];
    }
  }

  Future<bool> bookAppointment(MediumModel medium, DateTime appointmentDateTime, int duration, String description) async {
    if (currentUserId == null) return false;

    try {
      isLoading.value = true;

      final user = _auth.currentUser;
      if (user == null) return false;

      final appointment = AppointmentModel(
        id: '',
        clientId: currentUserId!,
        mediumId: medium.id,
        mediumName: medium.name,
        clientName: user.displayName ?? user.email ?? 'Cliente',
        scheduledDate: appointmentDateTime,
        duration: duration,
        amount: (medium.pricePerMinute * duration),
        status: 'pending',
        description: description,
        consultationType: 'Consulta Geral',
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('appointments').add(appointment.toMap());

      final savedAppointment = appointment.copyWith(id: docRef.id);
      appointments.insert(0, savedAppointment);

      Get.snackbar(
        'Sucesso',
        'Agendamento realizado com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      return true;
    } catch (e) {
      debugPrint('Erro ao realizar agendamento: $e');
      Get.snackbar(
        'Erro',
        'Erro ao realizar agendamento: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> cancelAppointment(String appointmentId, String reason) async {
    try {
      isLoading.value = true;

      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancelReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final index = appointments.indexWhere((apt) => apt.id == appointmentId);
      if (index != -1) {
        appointments[index] = appointments[index].copyWith(
          status: 'cancelled',
          cancelReason: reason,
          updatedAt: DateTime.now(),
        );
      }

      Get.snackbar(
        'Sucesso',
        'Agendamento cancelado com sucesso',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      debugPrint('Erro ao cancelar agendamento: $e');
      Get.snackbar(
        'Erro',
        'Erro ao cancelar agendamento',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void updateSelectedDate(DateTime date) {
    selectedDate.value = date;
    selectedTime.value = '';
    availableTimes.clear();
  }

  void updateSelectedTime(String time) {
    selectedTime.value = time;
  }

  void updateSelectedDuration(int duration) {
    selectedDuration.value = duration;
  }

  void calculateTotalAmount(double pricePerMinute) {
    totalAmount.value = pricePerMinute * selectedDuration.value;
  }

  List<AppointmentModel> get pendingAppointments =>
      appointments.where((apt) => apt.isPending).toList();

  List<AppointmentModel> get confirmedAppointments =>
      appointments.where((apt) => apt.isConfirmed).toList();

  List<AppointmentModel> get completedAppointments =>
      appointments.where((apt) => apt.isCompleted).toList();

  List<AppointmentModel> get upcomingAppointments =>
      appointments.where((apt) =>
      (apt.isPending || apt.isConfirmed) &&
          apt.scheduledDate.isAfter(DateTime.now())
      ).toList();
}
