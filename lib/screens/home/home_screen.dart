import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/models/medium_model.dart';
import 'package:oraculum/utils/zodiac_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final AuthController _authController = Get.find<AuthController>();
  final HoroscopeController _horoscopeController = Get.find<HoroscopeController>();
  final MediumController _mediumController = Get.find<MediumController>();
  final PaymentController _paymentController = Get.find<PaymentController>();

  late AnimationController _animationController;
  late AnimationController _backgroundController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  final ValueNotifier<bool> _dataLoaded = ValueNotifier<bool>(false);
  final ValueNotifier<Map<String, dynamic>> _parsedHoroscope = ValueNotifier<Map<String, dynamic>>({});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _topAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
    ).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );

    _bottomAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.bottomRight,
      end: Alignment.bottomLeft,
    ).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );

    _horoscopeController.dailyHoroscope.listen((horoscope) {
      if (horoscope != null && horoscope.content.isNotEmpty) {
        _parseHoroscopeData(horoscope.content);
      }
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.repeat(reverse: true, period: 3000.ms);
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadInitialData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _dataLoaded.value = false;
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _parseHoroscopeData(String content) {
    try {
      final Map<String, dynamic> data = json.decode(content);
      _parsedHoroscope.value = data;
    } catch (e) {
      _parsedHoroscope.value = {
        'geral': {'title': 'Geral', 'body': content},
      };
    }
  }

  Future<void> _loadInitialData() async {
    if (_dataLoaded.value) return;

    _dataLoaded.value = true;

    try {
      if (_authController.userModel.value != null) {
        final birthDate = _authController.userModel.value!.birthDate;
        if (birthDate != null) {
          final sign = ZodiacUtils.getZodiacSignFromDate(birthDate);
          await _horoscopeController.getDailyHoroscope(sign);
        } else {
          await _horoscopeController.getDailyHoroscope('Áries');
        }
        await _paymentController.loadUserCredits();
      } else {
        await _horoscopeController.getDailyHoroscope('Áries');
      }

      await _mediumController.loadMediums();
    } catch (e) {
      _dataLoaded.value = false;
      debugPrint('Erro ao carregar dados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth >= 600;

    final horizontalPadding = isTablet ? 32.0 : isSmallScreen ? 16.0 : 20.0;
    final verticalSpacing = isTablet ? 28.0 : isSmallScreen ? 16.0 : 20.0;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_topAlignmentAnimation, _bottomAlignmentAnimation]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _topAlignmentAnimation.value,
                end: _bottomAlignmentAnimation.value,
                colors: [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                  const Color(0xFF0F3460),
                  const Color(0xFF533483),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  _dataLoaded.value = false;
                  await _loadInitialData();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: verticalSpacing),
                            _buildWelcomeHeader(isSmallScreen, isTablet),
                            SizedBox(height: verticalSpacing),
                            _buildZodiacCard(isSmallScreen, isTablet),
                            SizedBox(height: verticalSpacing),
                            _buildQuickServices(context, isSmallScreen, isTablet),
                            SizedBox(height: verticalSpacing),
                            _buildFeaturedMediums(isSmallScreen, isTablet),
                            SizedBox(height: verticalSpacing),
                            _buildAccountStatus(isSmallScreen, isTablet),
                            SizedBox(height: verticalSpacing),
                            _buildPromotionalBanner(isSmallScreen, isTablet),
                            SizedBox(height: verticalSpacing * 2),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(bool isSmallScreen, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: isTablet ? 18 : isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w400,
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
            SizedBox(height: 4),
            Obx(() {
              final user = _authController.userModel.value;
              final firstName = user?.name.split(' ').first ?? 'Visitante';
              return Text(
                firstName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 28 : isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3);
            }),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withOpacity(0.3),
                const Color(0xFF8E78FF).withOpacity(0.2),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: () => Get.toNamed(AppRoutes.notificationList),
            icon: Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: isTablet ? 24 : 20,
            ),
            tooltip: 'Notificações',
          ),
        ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.5, 0.5)),
      ],
    );
  }

  Widget _buildZodiacCard(bool isSmallScreen, bool isTablet) {
    return Obx(() {
      final user = _authController.userModel.value;
      if (user == null || user.birthDate == null) {
        return _buildDefaultZodiacCard(isSmallScreen, isTablet);
      }

      final userSign = ZodiacUtils.getZodiacSignFromDate(user.birthDate!);
      final signColor = ZodiacUtils.getSignColor(userSign);
      final element = ZodiacUtils.getElement(userSign);

      return Container(
        padding: EdgeInsets.all(isTablet ? 28 : 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [
              signColor.withOpacity(0.3),
              signColor.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          border: Border.all(
            color: signColor.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: signColor.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Partículas de estrelas para efeito visual seguindo o padrão
            ...ZodiacUtils.buildStarParticles(context, isTablet ? 15 : 10),

            // Imagem do signo como fundo decorativo
            Positioned(
              right: -30,
              top: -30,
              child: Opacity(
                opacity: 0.15,
                child: ZodiacUtils.buildZodiacImage(
                  userSign,
                  size: isTablet ? 140 : 100,
                  color: signColor,
                ),
              ),
            ),

            // Conteúdo principal
            Column(
              children: [
                Row(
                  children: [
                    // Container circular com imagem do signo
                    Container(
                      width: isTablet ? 70 : 60,
                      height: isTablet ? 70 : 60,
                      padding: EdgeInsets.all(isTablet ? 12 : 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            signColor.withOpacity(0.3),
                            signColor.withOpacity(0.1),
                          ],
                        ),
                        border: Border.all(
                          color: signColor.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: signColor.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: ZodiacUtils.buildZodiacImage(
                          userSign,
                          size: isTablet ? 46 : 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seu Signo',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            userSign,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTablet ? 28 : 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Elemento: $element',
                            style: TextStyle(
                              color: signColor,
                              fontSize: isTablet ? 14 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 24 : 20),

                // Resumo do horóscopo diário
                Obx(() {
                  final dailyHoroscope = _horoscopeController.dailyHoroscope.value;

                  if (dailyHoroscope != null && dailyHoroscope.content.isNotEmpty) {
                    String horoscopeSummary = '';

                    try {
                      final Map<String, dynamic> data = json.decode(dailyHoroscope.content);

                      if (data.containsKey('resumo')) {
                        horoscopeSummary = data['resumo']['body'] ?? data['resumo'].toString();
                      } else if (data.containsKey('geral')) {
                        horoscopeSummary = data['geral']['body'] ?? data['geral'].toString();
                      } else if (data.containsKey('amor')) {
                        horoscopeSummary = data['amor']['body'] ?? data['amor'].toString();
                      } else {
                        horoscopeSummary = data.values.first.toString();
                      }
                    } catch (e) {
                      horoscopeSummary = dailyHoroscope.content;
                    }

                    if (horoscopeSummary.length > 120) {
                      horoscopeSummary = '${horoscopeSummary.substring(0, 120)}...';
                    }

                    return Container(
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: signColor,
                                size: isTablet ? 20 : 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Horóscopo de Hoje',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 12 : 10),
                          Text(
                            horoscopeSummary,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isTablet ? 14 : 12,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }

                  return Container(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_horoscopeController.isLoading.value)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(signColor),
                            ),
                          )
                        else
                          Icon(
                            Icons.refresh,
                            color: signColor,
                            size: isTablet ? 20 : 18,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _horoscopeController.isLoading.value
                                ? 'Carregando seu horóscopo...'
                                : 'Toque para carregar seu horóscopo',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: isTablet ? 14 : 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                SizedBox(height: isTablet ? 20 : 16),

                // Botão para ver horóscopo completo
                GestureDetector(
                  onTap: () {
                    if (_horoscopeController.dailyHoroscope.value == null) {
                      _horoscopeController.getDailyHoroscope(userSign);
                    }
                    Get.toNamed(AppRoutes.navigation, arguments: 1);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: isTablet ? 16 : 14,
                      horizontal: isTablet ? 20 : 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_graph,
                          color: signColor,
                          size: isTablet ? 24 : 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ver horóscopo completo',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: isTablet ? 20 : 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2).scale(
        begin: const Offset(0.95, 0.95),
        curve: Curves.elasticOut,
        duration: 800.ms,
      );
    });
  }

  Widget _buildDefaultZodiacCard(bool isSmallScreen, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 28 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.2),
            const Color(0xFF8E78FF).withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_circle,
            color: const Color(0xFF6C63FF),
            size: isTablet ? 48 : 40,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            'Faça login para descobrir seu signo',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'E receba previsões personalizadas',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isTablet ? 14 : 12,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2);
  }

  Widget _buildTodayHoroscope(bool isSmallScreen, bool isTablet) {
    return Obx(() {
      final user = _authController.userModel.value;
      if (user == null || user.birthDate == null) return const SizedBox.shrink();

      final userSign = ZodiacUtils.getZodiacSignFromDate(user.birthDate!);
      final signColor = ZodiacUtils.getSignColor(userSign);

      return Container(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.15),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C63FF),
                        const Color(0xFF8E78FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.today,
                    color: Colors.white,
                    size: isTablet ? 24 : 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horóscopo de Hoje',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, d MMMM', 'pt_BR').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isTablet ? 14 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => Get.toNamed(AppRoutes.horoscope),
                    icon: const Icon(Icons.open_in_full, color: Colors.white70),
                    tooltip: 'Ver horóscopo completo',
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Obx(() {
              if (_horoscopeController.isLoading.value) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Carregando sua previsão...',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isTablet ? 14 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final horoscope = _horoscopeController.dailyHoroscope.value;
              if (horoscope == null || horoscope.content.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: isTablet ? 24 : 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Não foi possível carregar sua previsão. Toque para tentar novamente.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 14 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ValueListenableBuilder<Map<String, dynamic>>(
                valueListenable: _parsedHoroscope,
                builder: (context, parsedData, child) {
                  String displayText = horoscope.content;
                  if (parsedData.isNotEmpty && parsedData.containsKey('geral')) {
                    displayText = parsedData['geral']['body'] ?? horoscope.content;
                  }

                  return Container(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    decoration: BoxDecoration(
                      color: signColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: signColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      displayText.length > 200
                          ? '${displayText.substring(0, 200)}...'
                          : displayText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: isTablet ? 16 : 14,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ).animate(delay: 1200.ms).fadeIn(duration: 600.ms).slideY(begin: 0.2);
    });
  }

  Widget _buildAccountStatus(bool isSmallScreen, bool isTablet) {
    return Obx(() {
      final user = _authController.userModel.value;
      if (user == null) return const SizedBox.shrink();

      return Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF9D8A).withOpacity(0.2),
                    const Color(0xFFFF8A80).withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFFF9D8A).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: const Color(0xFFFF9D8A),
                        size: isTablet ? 24 : 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Créditos',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isTablet ? 14 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Obx(() {
                    final credits = _paymentController.userCredits.value;
                    return Text(
                      'R\$ ${credits.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.settings),
              child: Container(
                padding: EdgeInsets.all(isTablet ? 20 : 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8E78FF).withOpacity(0.2),
                      const Color(0xFF7C6EF0).withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF8E78FF).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: const Color(0xFF8E78FF),
                          size: isTablet ? 24 : 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Perfil',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isTablet ? 14 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ver dados',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ).animate(delay: 1800.ms).fadeIn().slideX(begin: 0.2);
    });
  }

  Widget _buildPromotionalBanner(bool isSmallScreen, bool isTablet) {
    return Container(
      width: double.infinity,
      height: isTablet ? 148 : isSmallScreen ? 108 : 128,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF392F5A),
            const Color(0xFF8C6BAE),
            const Color(0xFF6C63FF),
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Get.toNamed(AppRoutes.paymentMethods),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                ...List.generate(15, (index) {
                  return Positioned(
                    left: (index * 47.0) % 300,
                    top: (index * 23.0) % 100,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ).animate(delay: Duration(milliseconds: index * 200))
                        .fadeIn(duration: 1000.ms)
                        .then(delay: 500.ms)
                        .fadeOut(duration: 1000.ms),
                  );
                }),

                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    Icons.auto_awesome,
                    size: isTablet ? 90 : 70,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(isTablet ? 18 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '🎁 OFERTA ESPECIAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 11 : 9,
                          ),
                        ),
                      ),
                      SizedBox(height: isTablet ? 8 : 4),
                      Flexible(
                        child: Text(
                          'Ganhe até 15% de desconto\nem créditos',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 16 : isSmallScreen ? 12 : 14,
                            height: 1.1,
                          ),
                        ),
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Oferta válida por tempo limitado',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: isTablet ? 12 : isSmallScreen ? 9 : 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 8,
                              vertical: isTablet ? 4 : 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Aproveitar',
                                  style: TextStyle(
                                    color: const Color(0xFF392F5A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: isTablet ? 11 : 9,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(
                                  Icons.arrow_forward,
                                  size: isTablet ? 12 : 10,
                                  color: const Color(0xFF392F5A),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: 2000.ms).fadeIn().slideY(begin: 0.3);
  }

  Widget _buildQuickServices(BuildContext context, bool isSmallScreen, bool isTablet) {
    final services = [
      {
        'title': 'Tarô',
        'subtitle': 'Leitura de cartas',
        'icon': Icons.auto_fix_high,
        'gradient': [const Color(0xFFFF9D8A), const Color(0xFFFF8A80)],
        'route': AppRoutes.tarotReading,
      },
      {
        'title': 'Médiuns',
        'subtitle': 'Consulta ao vivo',
        'icon': Icons.video_call,
        'gradient': [const Color(0xFF8E78FF), const Color(0xFF7C6EF0)],
        'route': AppRoutes.mediumsList,
      },
      {
        'title': 'Mapa Astral',
        'subtitle': 'Análise completa',
        'icon': Icons.public,
        'gradient': [const Color(0xFF392F5A), const Color(0xFF2D2545)],
        'route': AppRoutes.birthChart,
      },
      {
        'title': 'Compatibilidade',
        'subtitle': 'Entre signos',
        'icon': Icons.favorite,
        'gradient': [const Color(0xFF6C63FF), const Color(0xFF5A52E8)],
        'route': AppRoutes.compatibility,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Serviços Espirituais',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 22 : isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ).animate(delay: 1200.ms).fadeIn().slideX(begin: -0.2),
        SizedBox(height: isTablet ? 16 : 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: isTablet ? 1.6 : isSmallScreen ? 1.4 : 1.5,
            crossAxisSpacing: isTablet ? 16 : 12,
            mainAxisSpacing: isTablet ? 16 : 12,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return _buildServiceCard(
              service: service,
              index: index,
              isSmallScreen: isSmallScreen,
              isTablet: isTablet,
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required Map<String, dynamic> service,
    required int index,
    required bool isSmallScreen,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: service['gradient'] as List<Color>,
        ),
        boxShadow: [
          BoxShadow(
            color: (service['gradient'] as List<Color>)[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Get.toNamed(service['route']),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 18 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isTablet ? 10 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    service['icon'],
                    color: Colors.white,
                    size: isTablet ? 24 : isSmallScreen ? 18 : 20,
                  ),
                ),
                const Spacer(),
                Text(
                  service['title'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 16 : isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  service['subtitle'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: isTablet ? 12 : isSmallScreen ? 10 : 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 1400 + (index * 100)))
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.2, curve: Curves.easeOutQuad)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.elasticOut);
  }

  Widget _buildFeaturedMediums(bool isSmallScreen, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Médiuns Disponíveis',
              style: TextStyle(
                color: Colors.white,
                fontSize: isTablet ? 22 : isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.mediumsList),
                icon: Icon(
                  Icons.people,
                  size: isTablet ? 16 : 14,
                  color: Colors.white70,
                ),
                label: Text(
                  'Ver Todos',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isTablet ? 13 : 11,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 14 : 10,
                    vertical: isTablet ? 6 : 4,
                  ),
                ),
              ),
            ),
          ],
        ).animate(delay: 2200.ms).fadeIn().slideX(begin: -0.2),
        SizedBox(height: isTablet ? 16 : 12),
        SizedBox(
          height: isTablet ? 240 : isSmallScreen ? 200 : 220,
          child: Obx(() {
            if (_mediumController.isLoading.value) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                        strokeWidth: 2,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Carregando médiuns...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isTablet ? 14 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (_mediumController.allMediums.isEmpty) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search,
                        color: Colors.white60,
                        size: isTablet ? 48 : 40,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum médium disponível',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tente novamente mais tarde',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isTablet ? 14 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final featuredMediums = _mediumController.allMediums.take(6).toList();

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 4),
              itemCount: featuredMediums.length,
              itemBuilder: (context, index) {
                final medium = featuredMediums[index];
                return _buildEnhancedMediumCard(
                  medium: medium,
                  index: index,
                  isSmallScreen: isSmallScreen,
                  isTablet: isTablet,
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEnhancedMediumCard({
    required MediumModel medium,
    required int index,
    required bool isSmallScreen,
    required bool isTablet,
  }) {
    final cardWidth = isTablet ? 180.0 : isSmallScreen ? 140.0 : 160.0;

    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: isTablet ? 16 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _mediumController.selectMedium(medium.id);
            Get.toNamed(AppRoutes.mediumProfile);
          },
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 14),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: isTablet ? 70 : isSmallScreen ? 55 : 60,
                      height: isTablet ? 70 : isSmallScreen ? 55 : 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6C63FF),
                            const Color(0xFF8E78FF),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: medium.imageUrl!.isNotEmpty
                            ? Image.network(
                          medium.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(
                                Icons.person,
                                color: Colors.white,
                                size: isTablet ? 32 : 28,
                              ),
                        )
                            : Icon(
                          Icons.person,
                          color: Colors.white,
                          size: isTablet ? 32 : 28,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: medium.isAvailable ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isTablet ? 14 : 12),
                Text(
                  medium.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 16 : isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6),
                if (medium.specialties.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E78FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF8E78FF).withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      medium.specialties.first,
                      style: TextStyle(
                        color: const Color(0xFF8E78FF),
                        fontSize: isTablet ? 12 : isSmallScreen ? 9 : 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      color: const Color(0xFFFF9D8A),
                      size: isTablet ? 18 : 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      medium.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 14 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: isTablet ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6C63FF),
                        const Color(0xFF8E78FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        medium.isAvailable ? Icons.videocam : Icons.schedule,
                        color: Colors.white,
                        size: isTablet ? 16 : 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        medium.isAvailable ? 'Consultar' : 'Agendar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 2400 + (index * 100)))
        .fadeIn(duration: 500.ms)
        .slideX(begin: 0.3, curve: Curves.easeOutQuad)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.elasticOut);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia,';
    if (hour < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }
}
