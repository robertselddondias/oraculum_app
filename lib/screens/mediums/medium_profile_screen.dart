import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:oraculum/models/medium_model.dart';

class MediumProfileScreen extends StatelessWidget {
  const MediumProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MediumController controller = Get.find<MediumController>();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      body: Obx(() {
        if (controller.selectedMedium.value == null) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF392F5A), Color(0xFF8C6BAE)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        Future<List<Map<String, dynamic>>> _loadMediumReviews(String mediumId) async {
          try {
            final reviewsSnapshot = await FirebaseFirestore.instance
                .collection('medium_reviews')
                .where('mediumId', isEqualTo: mediumId)
                .orderBy('createdAt', descending: true)
                .limit(10)
                .get();

            return reviewsSnapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList();
          } catch (e) {
            print('Erro ao carregar avaliações: $e');
            return [];
          }
        }

        String _formatDate(dynamic timestamp) {
          try {
            if (timestamp == null) return 'Data não disponível';

            DateTime date;
            if (timestamp is String) {
              date = DateTime.parse(timestamp);
            } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
              date = timestamp.toDate();
            } else if (timestamp is DateTime) {
              date = timestamp;
            } else {
              return 'Data inválida';
            }

            final now = DateTime.now();
            final difference = now.difference(date);

            if (difference.inDays == 0) {
              return 'Hoje';
            } else if (difference.inDays == 1) {
              return 'Ontem';
            } else if (difference.inDays < 7) {
              return '${difference.inDays} dias atrás';
            } else if (difference.inDays < 30) {
              final weeks = (difference.inDays / 7).floor();
              return weeks == 1 ? '1 semana atrás' : '$weeks semanas atrás';
            } else if (difference.inDays < 365) {
              final months = (difference.inDays / 30).floor();
              return months == 1 ? '1 mês atrás' : '$months meses atrás';
            } else {
              final years = (difference.inDays / 365).floor();
              return years == 1 ? '1 ano atrás' : '$years anos atrás';
            }
          } catch (e) {
            return 'Data inválida';
          }
        }

        final medium = controller.selectedMedium.value!;

        return CustomScrollView(
          slivers: [
            _buildAppBar(context, medium, isSmallScreen),
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF392F5A), Color(0xFF8C6BAE), Color(0xFF533483)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(context, medium, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      _buildAboutSection(context, medium, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      _buildSpecialtiesSection(context, medium, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      _buildAvailabilityFromFirestore(context, medium, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 28 : 36),
                      _buildBookingButton(context, medium, isSmallScreen),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAppBar(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final expandedHeight = isSmallScreen ? 220.0 : 260.0;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: const Color(0xFF392F5A),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              medium.imageUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF8E78FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.white54,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ],
        ),
        title: Text(
          medium.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.favorite_border, color: Colors.white),
          ),
          onPressed: () {
            Get.snackbar(
              'Favoritos',
              'Médium adicionado aos favoritos!',
              backgroundColor: Colors.pink,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
            );
          },
          tooltip: 'Adicionar aos favoritos',
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.share, color: Colors.white),
          ),
          onPressed: () {
            Get.snackbar(
              'Compartilhar',
              'Compartilhando perfil do médium...',
              backgroundColor: Colors.blue,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              margin: const EdgeInsets.all(16),
            );
          },
          tooltip: 'Compartilhar',
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final titleSize = isSmallScreen ? 20.0 : 22.0;
    final iconSize = isSmallScreen ? 16.0 : 18.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medium.name,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: iconSize,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          medium.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${medium.reviewsCount} avaliações)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: medium.isAvailable
                        ? [Colors.green, Colors.lightGreen]
                        : [Colors.grey, Colors.grey.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      medium.isAvailable ? Icons.check_circle : Icons.schedule,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      medium.isAvailable ? 'Disponível' : 'Indisponível',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.attach_money,
                  iconColor: Colors.green,
                  title: 'R\$ ${medium.pricePerMinute.toStringAsFixed(2)}',
                  subtitle: 'por minuto',
                  isSmallScreen: isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.workspace_premium,
                  iconColor: Colors.orange,
                  title: '${medium.yearsOfExperience}',
                  subtitle: 'anos de experiência',
                  isSmallScreen: isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.people,
                  iconColor: Colors.blue,
                  title: '${medium.totalAppointments}+',
                  subtitle: 'consultas realizadas',
                  isSmallScreen: isSmallScreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: isSmallScreen ? 20 : 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 11,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 18.0 : 20.0;
    final contentTextSize = isSmallScreen ? 14.0 : 15.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8E78FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sobre',
                style: TextStyle(
                  fontSize: sectionTitleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            medium.biography,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              height: 1.6,
              fontSize: contentTextSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialtiesSection(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 18.0 : 20.0;
    final chipTextSize = isSmallScreen ? 12.0 : 13.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9D8A), Color(0xFF6C63FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Especialidades',
                style: TextStyle(
                  fontSize: sectionTitleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: medium.specialties.map((specialty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8E78FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  specialty,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: chipTextSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityFromFirestore(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 18.0 : 20.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Disponibilidade',
                style: TextStyle(
                  fontSize: sectionTitleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>?>(
            future: _loadMediumAvailability(medium.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return Text(
                  'Erro ao carregar disponibilidade',
                  style: TextStyle(
                    color: Colors.red.withOpacity(0.8),
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                );
              }

              final availabilityData = snapshot.data!;
              return _buildAvailabilityScheduleFromData(availabilityData, isSmallScreen);
            },
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _loadMediumAvailability(String mediumId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('medium_availability')
          .doc(mediumId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['availability'] ?? data;
      }
      return null;
    } catch (e) {
      print('Erro ao carregar disponibilidade: $e');
      return null;
    }
  }

  Widget _buildAvailabilityScheduleFromData(Map<String, dynamic> availabilityData, bool isSmallScreen) {
    final textSize = isSmallScreen ? 13.0 : 14.0;

    final weekDays = {
      'monday': 'Segunda-feira',
      'tuesday': 'Terça-feira',
      'wednesday': 'Quarta-feira',
      'thursday': 'Quinta-feira',
      'friday': 'Sexta-feira',
      'saturday': 'Sábado',
      'sunday': 'Domingo',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horários de atendimento:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: textSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: weekDays.entries.map((entry) {
            final dayKey = entry.key;
            final dayName = entry.value;

            final dayAvailability = availabilityData[dayKey] as Map<String, dynamic>?;
            final isAvailable = dayAvailability?['isAvailable'] == true;

            if (!isAvailable) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: textSize,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Indisponível',
                        style: TextStyle(
                          color: Colors.red.shade200,
                          fontSize: textSize - 1,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final startTime = dayAvailability?['startTime'] ?? '09:00';
            final endTime = dayAvailability?['endTime'] ?? '18:00';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: textSize,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$startTime - $endTime',
                      style: TextStyle(
                        color: Colors.green.shade200,
                        fontSize: textSize - 1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBookingButton(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final buttonTextSize = isSmallScreen ? 16.0 : 18.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: medium.isAvailable
              ? [const Color(0xFF6C63FF), const Color(0xFF8E78FF)]
              : [Colors.grey, Colors.grey.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: medium.isAvailable ? [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ] : [],
      ),
      child: ElevatedButton.icon(
        onPressed: medium.isAvailable
            ? () => Get.toNamed(AppRoutes.booking)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(
          medium.isAvailable ? Icons.calendar_today : Icons.block,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          medium.isAvailable ? 'Agendar Consulta' : 'Indisponível para Agendamento',
          style: TextStyle(
            fontSize: buttonTextSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
