import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:oraculum/models/medium_model.dart';
import 'package:oraculum/utils/zodiac_utils.dart';

class MediumsListScreen extends StatefulWidget {
  const MediumsListScreen({super.key});

  @override
  State<MediumsListScreen> createState() => _MediumsListScreenState();
}

class _MediumsListScreenState extends State<MediumsListScreen> {
  final MediumController _controller = Get.find<MediumController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _controller.loadMediums();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth > 768;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF392F5A),
              Color(0xFF483D8B),
              Color(0xFF8C6BAE),
              Color(0xFF4A3988),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Estrelas no background
            ...ZodiacUtils.buildStarParticles(context, isTablet ? 35 : 25),

            Column(
              children: [
                _buildCustomAppBar(horizontalPadding, isSmallScreen, isTablet),
                _buildSearchSection(horizontalPadding, isSmallScreen, isTablet),
                _buildSpecialtiesFilter(),
                Expanded(
                  child: Obx(() {
                    if (_controller.isLoading.value) {
                      return _buildLoadingState();
                    }

                    if (_controller.filteredMediums.isEmpty) {
                      return _buildEmptyState(isTablet);
                    }

                    return _buildMediumsList(horizontalPadding, isSmallScreen, isTablet);
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(double horizontalPadding, bool isSmallScreen, bool isTablet) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: 16,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Médiuns Disponíveis',
              style: TextStyle(
                fontSize: isTablet ? 24 : isSmallScreen ? 20 : 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(double horizontalPadding, bool isSmallScreen, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar médiuns...',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: isTablet ? 16 : isSmallScreen ? 14 : 15,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withOpacity(0.7),
            ),
            suffixIcon: Obx(() => searchQuery.value.isNotEmpty
                ? IconButton(
              icon: Icon(
                Icons.clear,
                color: Colors.white.withOpacity(0.7),
              ),
              onPressed: () {
                _searchController.clear();
                searchQuery.value = '';
                _applyFilters();
              },
            )
                : const SizedBox()),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          onChanged: (value) {
            searchQuery.value = value;
            _applyFilters();
          },
        ),
      ),
    );
  }

  Widget _buildSpecialtiesFilter() {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _controller.specialties.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Obx(() => _buildFilterChip(
              label: 'Todos',
              isSelected: _controller.selectedSpecialty.isEmpty,
              onTap: () => _controller.filterBySpecialty(''),
            ));
          }

          final specialty = _controller.specialties[index - 1];
          return Obx(() => _buildFilterChip(
            label: specialty,
            isSelected: _controller.selectedSpecialty.value == specialty,
            onTap: () => _controller.filterBySpecialty(specialty),
          ));
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Colors.white, Colors.white70],
          )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF392F5A) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: isTablet ? 80 : 60,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum médium encontrado',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros de busca',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: isTablet ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediumsList(double horizontalPadding, bool isSmallScreen, bool isTablet) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: _controller.filteredMediums.length,
      itemBuilder: (context, index) {
        final medium = _controller.filteredMediums[index];
        return _buildMediumCard(medium, index, isSmallScreen, isTablet);
      },
    );
  }

  Widget _buildMediumCard(MediumModel medium, int index, bool isSmallScreen, bool isTablet) {
    final cardHeight = isTablet ? 160.0 : isSmallScreen ? 130.0 : 140.0;

    return Container(
      height: cardHeight,
      margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.25),
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () {
            _controller.selectMedium(medium.id);
            Get.toNamed(AppRoutes.mediumProfile);
          },
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            child: Row(
              children: [
                _buildProfileImage(medium, isSmallScreen, isTablet),
                SizedBox(width: isTablet ? 16 : 12),
                _buildMediumInfo(medium, isSmallScreen, isTablet),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 100 * index),
      duration: const Duration(milliseconds: 400),
    ).slideX(begin: 0.4, end: 0, curve: Curves.easeOutQuart);
  }

  Widget _buildProfileImage(MediumModel medium, bool isSmallScreen, bool isTablet) {
    final imageSize = isTablet ? 80.0 : isSmallScreen ? 60.0 : 70.0;

    return Stack(
      children: [
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Colors.white30, Colors.white10],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.network(
              medium.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6B46C1), Color(0xFF9333EA)],
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: imageSize * 0.5,
                    color: Colors.white.withOpacity(0.8),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: medium.isAvailable
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [Colors.grey.shade500, Colors.grey.shade600],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: (medium.isAvailable
                      ? const Color(0xFF10B981)
                      : Colors.grey.shade500).withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              medium.isAvailable ? 'Online' : 'Offline',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediumInfo(MediumModel medium, bool isSmallScreen, bool isTablet) {
    final nameSize = isTablet ? 18.0 : isSmallScreen ? 16.0 : 17.0;
    final descSize = isTablet ? 14.0 : isSmallScreen ? 12.0 : 13.0;
    final priceSize = isTablet ? 16.0 : isSmallScreen ? 14.0 : 15.0;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  medium.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: nameSize,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFB923C), Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.white,
                      size: isTablet ? 16 : 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      medium.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 12 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Flexible(
            child: Text(
              medium.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: descSize,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              maxLines: isTablet ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: medium.specialties.take(2).map((specialty) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  specialty,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 11 : 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_money,
                        color: Colors.white,
                        size: isTablet ? 16 : 14,
                      ),
                      Text(
                        'R\$ ${medium.pricePerMinute.toStringAsFixed(2)}/min',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: priceSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Colors.white70],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    _controller.selectMedium(medium.id);
                    Get.toNamed(AppRoutes.booking);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 16 : 12,
                      vertical: isTablet ? 12 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Agendar',
                    style: TextStyle(
                      color: const Color(0xFF392F5A),
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    final query = searchQuery.value.toLowerCase();
    final specialty = _controller.selectedSpecialty.value;

    if (query.isEmpty && specialty.isEmpty) {
      _controller.filteredMediums.value = List.from(_controller.allMediums);
      return;
    }

    _controller.filteredMediums.value = _controller.allMediums.where((medium) {
      final matchesName = query.isEmpty || medium.name.toLowerCase().contains(query);
      final matchesSpecialty = specialty.isEmpty || medium.specialties.contains(specialty);
      return matchesName && matchesSpecialty;
    }).toList();
  }
}
