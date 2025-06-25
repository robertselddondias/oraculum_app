import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/models/appointment_model.dart';
import 'package:oraculum/models/medium_model.dart';
import 'package:oraculum/services/appointment_service.dart';

class AppointmentController extends GetxController {
  final AppointmentService _appointmentService = Get.find<AppointmentService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========== OBSERVABLES ==========
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxList<AppointmentModel> appointments = <AppointmentModel>[].obs;
  final RxList<String> availableTimes = <String>[].obs;

  // Booking form state
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxString selectedTime = ''.obs;
  final RxInt selectedDuration = 30.obs;
  final RxDouble totalAmount = 0.0.obs;
  final RxString selectedMediumId = ''.obs;

  // Filters and search
  final RxString currentFilter = 'all'.obs;
  final RxString searchQuery = ''.obs;
  final Rx<DateTime?> filterStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> filterEndDate = Rx<DateTime?>(null);

  // Statistics
  final RxMap<String, int> stats = <String, int>{}.obs;
  final RxDouble totalSpent = 0.0.obs;
  final RxString mostConsultedMedium = ''.obs;

  // ========== GETTERS ==========
  String? get currentUserId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  @override
  void onInit() {
    super.onInit();
    debugPrint('=== AppointmentController.onInit() ===');

    if (currentUserId != null) {
      loadUserAppointments();
    }

    // Listen to filter changes
    ever(currentFilter, (_) => _applyFilters());
    ever(searchQuery, (_) => _applyFilters());
    ever(filterStartDate, (_) => _applyFilters());
    ever(filterEndDate, (_) => _applyFilters());
  }

  @override
  void onClose() {
    debugPrint('=== AppointmentController.onClose() ===');
    super.onClose();
  }

  // ========== APPOINTMENT MANAGEMENT ==========

  /// Carregar todos os agendamentos do usuário
  Future<void> loadUserAppointments({bool silent = false}) async {
    if (currentUserId == null) {
      debugPrint('❌ Usuário não autenticado');
      return;
    }

    try {
      if (!silent) isLoading.value = true;
      debugPrint('=== Carregando agendamentos do usuário: $currentUserId ===');

      final appointmentsList = await _appointmentService.getUserAppointments(
        startDate: filterStartDate.value,
        endDate: filterEndDate.value,
      );

      appointments.value = appointmentsList;
      _updateStatistics();

      debugPrint('✅ ${appointmentsList.length} agendamentos carregados');

    } catch (e) {
      debugPrint('❌ Erro ao carregar agendamentos: $e');

      if (!silent) {
        Get.snackbar(
          'Erro',
          'Não foi possível carregar os agendamentos',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  /// Refresh manual dos agendamentos
  Future<void> refreshAppointments() async {
    try {
      isRefreshing.value = true;
      await loadUserAppointments(silent: true);
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Criar novo agendamento
  Future<bool> createAppointment({
    required MediumModel medium,
    required DateTime scheduledDate,
    required int duration,
    required String description,
    String consultationType = 'Consulta Geral',
  }) async {
    if (currentUserId == null) {
      _showError('Usuário não autenticado');
      return false;
    }

    try {
      isLoading.value = true;
      debugPrint('=== Criando novo agendamento ===');
      debugPrint('Médium: ${medium.name}');
      debugPrint('Data: $scheduledDate');
      debugPrint('Duração: $duration min');

      // Verificar se o horário ainda está disponível
      final isAvailable = await _appointmentService.isTimeSlotAvailable(medium.id, scheduledDate);
      if (!isAvailable) {
        Get.snackbar(
          'Horário Indisponível',
          'Este horário não está mais disponível. Escolha outro.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return false;
      }

      final appointmentId = await _appointmentService.createAppointment(
        mediumId: medium.id,
        scheduledDate: scheduledDate,
        duration: duration,
        amount: (medium.pricePerMinute * duration),
        description: description,
        consultationType: consultationType,
      );

      // Recarregar a lista de agendamentos
      await loadUserAppointments(silent: true);

      Get.snackbar(
        'Sucesso',
        'Agendamento realizado com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      debugPrint('✅ Agendamento criado: $appointmentId');
      return true;

    } catch (e) {
      debugPrint('❌ Erro ao realizar agendamento: $e');
      _showError('Erro ao realizar agendamento: ${_sanitizeError(e)}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Cancelar agendamento
  Future<bool> cancelAppointment(String appointmentId, String reason) async {
    try {
      isLoading.value = true;
      debugPrint('=== Cancelando agendamento: $appointmentId ===');
      debugPrint('Motivo: $reason');

      await _appointmentService.cancelAppointment(appointmentId, reason);

      // Atualizar na lista local
      final index = appointments.indexWhere((apt) => apt.id == appointmentId);
      if (index != -1) {
        appointments[index] = appointments[index].copyWith(
          status: 'cancelled',
          cancelReason: reason,
          canceledAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _updateStatistics();
      }

      Get.snackbar(
        'Sucesso',
        'Agendamento cancelado com sucesso',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      debugPrint('✅ Agendamento cancelado com sucesso');
      return true;

    } catch (e) {
      debugPrint('❌ Erro ao cancelar agendamento: $e');
      _showError('Não foi possível cancelar o agendamento: ${_sanitizeError(e)}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Buscar agendamento específico
  Future<AppointmentModel?> getAppointment(String appointmentId) async {
    try {
      return await _appointmentService.getAppointment(appointmentId);
    } catch (e) {
      debugPrint('❌ Erro ao buscar agendamento: $e');
      return null;
    }
  }

  // ========== AVAILABILITY MANAGEMENT ==========

  /// Carregar horários disponíveis para um médium
  Future<void> loadAvailableTimes(String mediumId, DateTime date) async {
    try {
      availableTimes.clear();
      selectedMediumId.value = mediumId;

      debugPrint('=== Carregando horários disponíveis ===');
      debugPrint('MédiumId: $mediumId');
      debugPrint('Data: $date');

      final times = await _appointmentService.getAvailableTimes(mediumId, date);
      availableTimes.value = times;

      debugPrint('✅ ${times.length} horários disponíveis encontrados');

    } catch (e) {
      debugPrint('❌ Erro ao carregar horários disponíveis: $e');
      Get.snackbar(
        'Erro',
        'Erro ao buscar horários disponíveis',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Verificar se um horário está disponível
  Future<bool> checkTimeSlotAvailability(String mediumId, DateTime dateTime) async {
    try {
      return await _appointmentService.isTimeSlotAvailable(mediumId, dateTime);
    } catch (e) {
      debugPrint('❌ Erro ao verificar disponibilidade: $e');
      return false;
    }
  }

  // ========== BOOKING FORM MANAGEMENT ==========

  /// Atualizar data selecionada
  void updateSelectedDate(DateTime date) {
    selectedDate.value = date;
    selectedTime.value = '';
    availableTimes.clear();

    if (selectedMediumId.value.isNotEmpty) {
      loadAvailableTimes(selectedMediumId.value, date);
    }
  }

  /// Atualizar horário selecionado
  void updateSelectedTime(String time) {
    selectedTime.value = time;
  }

  /// Atualizar duração selecionada
  void updateSelectedDuration(int duration) {
    selectedDuration.value = duration;
  }

  /// Calcular valor total
  void calculateTotalAmount(double pricePerMinute) {
    totalAmount.value = pricePerMinute * selectedDuration.value;
  }

  /// Resetar formulário de agendamento
  void resetBookingForm() {
    selectedDate.value = DateTime.now();
    selectedTime.value = '';
    selectedDuration.value = 30;
    totalAmount.value = 0.0;
    selectedMediumId.value = '';
    availableTimes.clear();
  }

  // ========== FILTERING AND SEARCH ==========

  /// Definir filtro atual
  void setFilter(String filter) {
    currentFilter.value = filter;
  }

  /// Atualizar consulta de busca
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Definir período de filtro
  void setDateFilter(DateTime? startDate, DateTime? endDate) {
    filterStartDate.value = startDate;
    filterEndDate.value = endDate;
    loadUserAppointments();
  }

  /// Limpar todos os filtros
  void clearFilters() {
    currentFilter.value = 'all';
    searchQuery.value = '';
    filterStartDate.value = null;
    filterEndDate.value = null;
  }

  /// Aplicar filtros à lista de agendamentos
  void _applyFilters() {
    // A filtragem é feita através dos getters que retornam listas filtradas
    // Isso garante que a UI seja atualizada automaticamente
  }

  // ========== FILTERED GETTERS ==========

  /// Todos os agendamentos
  List<AppointmentModel> get allAppointments => appointments;

  /// Agendamentos filtrados por busca
  List<AppointmentModel> get searchFilteredAppointments {
    if (searchQuery.value.isEmpty) return appointments;

    return appointments.where((appointment) =>
    appointment.mediumName.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
        appointment.consultationType.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
        appointment.description.toLowerCase().contains(searchQuery.value.toLowerCase())
    ).toList();
  }

  /// Agendamentos pendentes
  List<AppointmentModel> get pendingAppointments =>
      _appointmentService.filterByStatus(searchFilteredAppointments, 'pending');

  /// Agendamentos confirmados
  List<AppointmentModel> get confirmedAppointments =>
      _appointmentService.filterByStatus(searchFilteredAppointments, 'confirmed');

  /// Agendamentos concluídos
  List<AppointmentModel> get completedAppointments =>
      _appointmentService.getCompletedAppointments(searchFilteredAppointments);

  /// Agendamentos cancelados
  List<AppointmentModel> get cancelledAppointments =>
      _appointmentService.getCancelledAppointments(searchFilteredAppointments);

  /// Agendamentos próximos (futuros e ativos)
  List<AppointmentModel> get upcomingAppointments =>
      _appointmentService.getUpcomingAppointments(searchFilteredAppointments);

  /// Agendamentos de hoje
  List<AppointmentModel> get todayAppointments {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _appointmentService.filterByDateRange(
        searchFilteredAppointments,
        todayStart,
        todayEnd
    );
  }

  /// Agendamentos desta semana
  List<AppointmentModel> get weekAppointments {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return _appointmentService.filterByDateRange(
        searchFilteredAppointments,
        startOfWeek,
        endOfWeek
    );
  }

  /// Agendamentos deste mês
  List<AppointmentModel> get monthAppointments {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _appointmentService.filterByDateRange(
        searchFilteredAppointments,
        startOfMonth,
        endOfMonth
    );
  }

  // ========== STATISTICS AND ANALYTICS ==========

  /// Atualizar estatísticas
  void _updateStatistics() {
    stats.value = _appointmentService.getAppointmentStats(appointments);
    totalSpent.value = _appointmentService.getTotalAmountSpent(appointments);
    mostConsultedMedium.value = _appointmentService.getMostConsultedMedium(appointments) ?? '';
  }

  /// Verificar se há agendamentos para hoje
  bool get hasAppointmentsToday => todayAppointments.isNotEmpty;

  /// Próximo agendamento
  AppointmentModel? get nextAppointment {
    final upcoming = upcomingAppointments;
    if (upcoming.isEmpty) return null;

    upcoming.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return upcoming.first;
  }

  /// Último agendamento concluído
  AppointmentModel? get lastCompletedAppointment {
    final completed = completedAppointments;
    if (completed.isEmpty) return null;

    completed.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    return completed.first;
  }

  /// Taxa de cancelamento (%)
  double get cancellationRate {
    if (appointments.isEmpty) return 0.0;
    return (cancelledAppointments.length / appointments.length) * 100;
  }

  /// Média de valor por consulta
  double get averageAppointmentAmount {
    final completed = completedAppointments;
    if (completed.isEmpty) return 0.0;

    final total = completed.fold(0.0, (sum, apt) => sum + apt.amount);
    return total / completed.length;
  }

  // ========== HELPER METHODS ==========

  /// Mostrar erro para o usuário
  void _showError(String message) {
    Get.snackbar(
      'Erro',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  /// Sanitizar mensagem de erro
  String _sanitizeError(dynamic error) {
    String errorMsg = error.toString();
    if (errorMsg.startsWith('Exception: ')) {
      errorMsg = errorMsg.replaceFirst('Exception: ', '');
    }
    return errorMsg;
  }

  /// Formatar data para exibição
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formatar horário para exibição
  String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Verificar se um agendamento pode ser cancelado
  bool canCancelAppointment(AppointmentModel appointment) {
    return appointment.canBeCancelled;
  }

  /// Obter cor do status
  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obter ícone do status
  IconData getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // ========== DEBUG METHODS ==========

  /// Log do estado atual
  void logCurrentState() {
    debugPrint('=== AppointmentController State ===');
    debugPrint('UserId: $currentUserId');
    debugPrint('Total appointments: ${appointments.length}');
    debugPrint('Pending: ${pendingAppointments.length}');
    debugPrint('Confirmed: ${confirmedAppointments.length}');
    debugPrint('Completed: ${completedAppointments.length}');
    debugPrint('Cancelled: ${cancelledAppointments.length}');
    debugPrint('Upcoming: ${upcomingAppointments.length}');
    debugPrint('Total spent: R\$ ${totalSpent.value.toStringAsFixed(2)}');
    debugPrint('Most consulted: ${mostConsultedMedium.value}');
    debugPrint('Current filter: ${currentFilter.value}');
    debugPrint('Search query: "${searchQuery.value}"');
    debugPrint('====================================');
  }
}
