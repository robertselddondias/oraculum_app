import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/models/appointment_model.dart';
import 'package:oraculum/models/medium_model.dart';
import 'package:oraculum/services/appointment_service.dart';
import 'package:oraculum/services/firebase_service.dart';

class MediumController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AppointmentService _appointmentService = Get.find<AppointmentService>();
  final AuthController _authController = Get.find<AuthController>();

  // ========== OBSERVABLES ==========
  final RxBool isLoading = false.obs;
  final RxBool isLoadingAppointments = false.obs;
  final RxBool isBooking = false.obs;

  final RxList<MediumModel> allMediums = <MediumModel>[].obs;
  final RxList<MediumModel> filteredMediums = <MediumModel>[].obs;
  final Rx<MediumModel?> selectedMedium = Rx<MediumModel?>(null);
  final RxList<AppointmentModel> userAppointments = <AppointmentModel>[].obs;

  // Filters
  final RxString selectedSpecialty = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxDouble minPrice = 0.0.obs;
  final RxDouble maxPrice = 100.0.obs;
  final RxBool isOnlineOnly = false.obs;

  // Specialties
  final RxList<String> specialties = <String>[
    'Tarot',
    'Astrologia',
    'Vidência',
    'Mediunidade',
    'Leitura de Aura',
    'Numerologia',
    'Psicografia',
    'Quiromancia',
    'Runas',
    'Oráculos'
  ].obs;

  // Statistics
  final RxMap<String, int> stats = <String, int>{}.obs;

  // ========== GETTERS ==========
  String? get currentUserId => _authController.currentUser.value?.uid;

  @override
  void onInit() {
    super.onInit();
    debugPrint('=== MediumController.onInit() ===');

    loadMediums();

    // Listen to filter changes
    ever(selectedSpecialty, (_) => _applyFilters());
    ever(searchQuery, (_) => _applyFilters());
    ever(minPrice, (_) => _applyFilters());
    ever(maxPrice, (_) => _applyFilters());
    ever(isOnlineOnly, (_) => _applyFilters());
  }

  @override
  void onClose() {
    debugPrint('=== MediumController.onClose() ===');
    super.onClose();
  }

  // ========== MEDIUM MANAGEMENT ==========

  /// Carregar todos os médiuns
  Future<void> loadMediums({bool silent = false}) async {
    try {
      if (!silent) isLoading.value = true;
      debugPrint('=== Carregando médiuns ===');

      final mediumsSnapshot = await _firebaseService.firestore
          .collection('mediums')
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .get();

      if (mediumsSnapshot.docs.isNotEmpty) {
        final mediumsList = mediumsSnapshot.docs
            .map((doc) => MediumModel.fromMap(doc.data(), doc.id))
            .toList();

        allMediums.value = mediumsList;
        _applyFilters();
        _updateStatistics();

        debugPrint('✅ ${mediumsList.length} médiuns carregados');
      } else {
        allMediums.clear();
        filteredMediums.clear();
        debugPrint('ℹ️ Nenhum médium encontrado');
      }

    } catch (e) {
      debugPrint('❌ Erro ao carregar médiuns: $e');

      if (!silent) {
        Get.snackbar(
          'Erro',
          'Não foi possível carregar os médiuns',
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

  /// Refresh médiuns
  Future<void> refreshMediums() async {
    await loadMediums(silent: false);
  }

  /// Selecionar médium
  void selectMedium(String mediumId) {
    try {
      final medium = allMediums.firstWhere((medium) => medium.id == mediumId);
      selectedMedium.value = medium;
      debugPrint('✅ Médium selecionado: ${medium.name}');
    } catch (e) {
      debugPrint('❌ Médium não encontrado: $mediumId');
      Get.snackbar(
        'Erro',
        'Médium não encontrado',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Buscar médium por ID
  Future<MediumModel?> getMediumById(String mediumId) async {
    try {
      final doc = await _firebaseService.firestore
          .collection('mediums')
          .doc(mediumId)
          .get();

      if (doc.exists) {
        return MediumModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erro ao buscar médium: $e');
      return null;
    }
  }

  // ========== FILTERING AND SEARCH ==========

  /// Filtrar por especialidade
  void filterBySpecialty(String specialty) {
    selectedSpecialty.value = specialty;
  }

  /// Atualizar busca por texto
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Filtrar por faixa de preço
  void filterByPriceRange(double min, double max) {
    minPrice.value = min;
    maxPrice.value = max;
  }

  /// Filtrar apenas médiuns online
  void toggleOnlineFilter(bool onlineOnly) {
    isOnlineOnly.value = onlineOnly;
  }

  /// Limpar todos os filtros
  void clearFilters() {
    selectedSpecialty.value = '';
    searchQuery.value = '';
    minPrice.value = 0.0;
    maxPrice.value = 100.0;
    isOnlineOnly.value = false;
  }

  /// Aplicar filtros
  void _applyFilters() {
    List<MediumModel> filtered = List.from(allMediums);

    // Filtro por especialidade
    if (selectedSpecialty.value.isNotEmpty) {
      filtered = filtered.where((medium) =>
          medium.specialties.contains(selectedSpecialty.value)
      ).toList();
    }

    // Filtro por busca de texto
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((medium) =>
      medium.name.toLowerCase().contains(query) ||
          medium.bio.toLowerCase().contains(query) ||
          medium.specialties.any((specialty) =>
              specialty.toLowerCase().contains(query))
      ).toList();
    }

    // Filtro por faixa de preço
    filtered = filtered.where((medium) =>
    medium.pricePerMinute >= minPrice.value &&
        medium.pricePerMinute <= maxPrice.value
    ).toList();

    // Filtro por médiuns online
    if (isOnlineOnly.value) {
      filtered = filtered.where((medium) => medium.isOnline).toList();
    }

    // Ordenar por rating
    filtered.sort((a, b) => b.rating.compareTo(a.rating));

    filteredMediums.value = filtered;
    debugPrint('🔍 Filtros aplicados: ${filtered.length} médiuns encontrados');
  }

  // ========== APPOINTMENT MANAGEMENT ==========

  /// Carregar agendamentos do usuário
  Future<void> loadUserAppointments({bool silent = false}) async {
    if (currentUserId == null) {
      debugPrint('❌ Usuário não autenticado');
      return;
    }

    try {
      if (!silent) isLoadingAppointments.value = true;
      debugPrint('=== Carregando agendamentos do usuário ===');

      final appointments = await _appointmentService.getUserAppointments();
      userAppointments.value = appointments;

      debugPrint('✅ ${appointments.length} agendamentos carregados');

    } catch (e) {
      debugPrint('❌ Erro ao carregar agendamentos: $e');

      if (!silent) {
        Get.snackbar(
          'Erro',
          'Não foi possível carregar os agendamentos',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (!silent) isLoadingAppointments.value = false;
    }
  }

  /// Criar agendamento
  Future<bool> bookAppointment(
      String mediumId,
      DateTime dateTime,
      int durationMinutes, {
        String description = '',
        String consultationType = 'Consulta Geral',
      }) async {
    if (currentUserId == null) {
      Get.snackbar(
        'Erro',
        'Você precisa estar logado para fazer um agendamento',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      isBooking.value = true;
      debugPrint('=== Criando agendamento ===');
      debugPrint('MédiumId: $mediumId');
      debugPrint('DateTime: $dateTime');
      debugPrint('Duração: $durationMinutes min');

      // Buscar dados do médium
      final medium = allMediums.firstWhereOrNull((m) => m.id == mediumId);
      if (medium == null) {
        throw Exception('Médium não encontrado');
      }

      // Calcular valor
      final amount = medium.pricePerMinute * durationMinutes;
      debugPrint('Valor calculado: R\$ ${amount.toStringAsFixed(2)}');

      // Verificar créditos
      final paymentController = Get.find<PaymentController>();
      final hasCredits = await paymentController.checkUserCredits(currentUserId!, amount);

      if (!hasCredits) {
        Get.snackbar(
          'Créditos Insuficientes',
          'Você precisa de R\$ ${amount.toStringAsFixed(2)} em créditos para este agendamento',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return false;
      }

      // Processar pagamento com créditos
      final paymentResult = await paymentController.processPaymentWithCredits(
          currentUserId!,
          amount,
          'Agendamento com ${medium.name} por $durationMinutes minutos',
          mediumId,
          'appointment'
      );

      if (paymentResult.isEmpty) {
        throw Exception('Falha ao processar o pagamento');
      }

      // Criar agendamento via AppointmentService
      final appointmentId = await _appointmentService.createAppointment(
        mediumId: mediumId,
        scheduledDate: dateTime,
        duration: durationMinutes,
        amount: amount,
        description: description,
        mediumImageUrl: medium.imageUrl,
        consultationType: consultationType,
      );

      // Atualizar pagamento com ID do agendamento
      await _firebaseService.firestore
          .collection('payments')
          .doc(paymentResult)
          .update({
        'appointmentId': appointmentId,
        'status': 'completed',
        'completedAt': DateTime.now(),
      });

      // Recarregar agendamentos
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
      debugPrint('❌ Erro ao criar agendamento: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível realizar o agendamento: ${_sanitizeError(e)}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isBooking.value = false;
    }
  }

  /// Cancelar agendamento
  Future<bool> cancelAppointment(String appointmentId, {String reason = 'Cancelado pelo cliente'}) async {
    try {
      isLoading.value = true;
      debugPrint('=== Cancelando agendamento: $appointmentId ===');

      await _appointmentService.cancelAppointment(appointmentId, reason);
      await loadUserAppointments(silent: true);

      Get.snackbar(
        'Sucesso',
        'Agendamento cancelado com sucesso!',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      debugPrint('✅ Agendamento cancelado');
      return true;

    } catch (e) {
      debugPrint('❌ Erro ao cancelar agendamento: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível cancelar o agendamento: ${_sanitizeError(e)}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Adicionar avaliação
  Future<bool> addReview(String appointmentId, double rating, String feedback) async {
    try {
      isLoading.value = true;
      debugPrint('=== Adicionando avaliação ===');
      debugPrint('AppointmentId: $appointmentId');
      debugPrint('Rating: $rating');

      // Atualizar agendamento com avaliação
      await _appointmentService.updateAppointment(appointmentId, {
        'rating': rating,
        'feedback': feedback,
        'reviewedAt': DateTime.now(),
        'status': 'completed', // Marcar como concluído após avaliação
      });

      // Recarregar agendamentos
      await loadUserAppointments(silent: true);

      Get.snackbar(
        'Sucesso',
        'Avaliação enviada com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      debugPrint('✅ Avaliação adicionada');
      return true;

    } catch (e) {
      debugPrint('❌ Erro ao adicionar avaliação: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível enviar a avaliação: ${_sanitizeError(e)}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ========== AVAILABILITY METHODS ==========

  /// Verificar disponibilidade de um médium
  Future<List<String>> getAvailableTimes(String mediumId, DateTime date) async {
    try {
      return await _appointmentService.getAvailableTimes(mediumId, date);
    } catch (e) {
      debugPrint('❌ Erro ao buscar horários disponíveis: $e');
      return [];
    }
  }

  /// Verificar se um horário específico está disponível
  Future<bool> isTimeSlotAvailable(String mediumId, DateTime dateTime) async {
    try {
      return await _appointmentService.isTimeSlotAvailable(mediumId, dateTime);
    } catch (e) {
      debugPrint('❌ Erro ao verificar disponibilidade: $e');
      return false;
    }
  }

  // ========== STATISTICS AND ANALYTICS ==========

  /// Atualizar estatísticas
  void _updateStatistics() {
    stats.value = {
      'totalMediums': allMediums.length,
      'onlineMediums': allMediums.where((m) => m.isOnline).length,
      'specialtiesCount': _getUniqueSpecialties().length,
      'averageRating': _calculateAverageRating(),
      'filteredCount': filteredMediums.length,
    };
  }

  /// Obter especialidades únicas
  List<String> _getUniqueSpecialties() {
    final Set<String> uniqueSpecialties = {};
    for (final medium in allMediums) {
      uniqueSpecialties.addAll(medium.specialties);
    }
    return uniqueSpecialties.toList()..sort();
  }

  /// Calcular rating médio
  int _calculateAverageRating() {
    if (allMediums.isEmpty) return 0;

    final totalRating = allMediums.fold(0.0, (sum, medium) => sum + medium.rating);
    return (totalRating / allMediums.length).round();
  }

  /// Obter médiuns mais bem avaliados
  List<MediumModel> get topRatedMediums {
    final sorted = List<MediumModel>.from(allMediums);
    sorted.sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(5).toList();
  }

  /// Obter médiuns online
  List<MediumModel> get onlineMediums =>
      allMediums.where((medium) => medium.isOnline).toList();

  /// Obter médiuns por especialidade
  List<MediumModel> getMediumsBySpecialty(String specialty) =>
      allMediums.where((medium) => medium.specialties.contains(specialty)).toList();

  // ========== APPOINTMENT GETTERS ==========

  /// Agendamentos pendentes
  List<AppointmentModel> get pendingAppointments =>
      userAppointments.where((apt) => apt.isPending).toList();

  /// Agendamentos confirmados
  List<AppointmentModel> get confirmedAppointments =>
      userAppointments.where((apt) => apt.isConfirmed).toList();

  /// Agendamentos concluídos
  List<AppointmentModel> get completedAppointments =>
      userAppointments.where((apt) => apt.isCompleted).toList();

  /// Próximo agendamento
  AppointmentModel? get nextAppointment {
    final upcoming = userAppointments
        .where((apt) => apt.isUpcoming)
        .toList();

    if (upcoming.isEmpty) return null;

    upcoming.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return upcoming.first;
  }

  // ========== HELPER METHODS ==========

  /// Sanitizar mensagem de erro
  String _sanitizeError(dynamic error) {
    String errorMsg = error.toString();
    if (errorMsg.startsWith('Exception: ')) {
      errorMsg = errorMsg.replaceFirst('Exception: ', '');
    }
    return errorMsg;
  }

  /// Formatar preço
  String formatPrice(double price) => 'R\$ ${price.toStringAsFixed(2)}/min';

  /// Verificar se médium é favorito (placeholder)
  bool isFavorite(String mediumId) {
    // TODO: Implementar sistema de favoritos
    return false;
  }

  /// Adicionar/remover favorito (placeholder)
  Future<void> toggleFavorite(String mediumId) async {
    // TODO: Implementar sistema de favoritos
    debugPrint('Toggle favorite: $mediumId');
  }

  // ========== DEBUG METHODS ==========

  /// Log do estado atual
  void logCurrentState() {
    debugPrint('=== MediumController State ===');
    debugPrint('Total mediums: ${allMediums.length}');
    debugPrint('Filtered mediums: ${filteredMediums.length}');
    debugPrint('Selected specialty: ${selectedSpecialty.value}');
    debugPrint('Search query: "${searchQuery.value}"');
    debugPrint('Price range: ${minPrice.value} - ${maxPrice.value}');
    debugPrint('Online only: ${isOnlineOnly.value}');
    debugPrint('User appointments: ${userAppointments.length}');
    debugPrint('Selected medium: ${selectedMedium.value?.name ?? 'None'}');
    debugPrint('=================================');
  }
}
