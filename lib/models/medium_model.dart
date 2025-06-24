import 'package:cloud_firestore/cloud_firestore.dart';

class MediumModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String description;
  final String? imageUrl;
  final List<String> specialties;
  final double rating;
  final int reviewsCount;
  final double pricePerMinute;
  final bool isActive;
  final bool isAvailable;
  final bool isOnline;
  final Map<String, dynamic> availability;
  final String biography;
  final String bio;
  final String experience;
  final int yearsOfExperience;
  final List<String> languages;
  final int totalAppointments;
  final int totalReviews;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSeen;

  MediumModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.description,
    this.imageUrl,
    required this.specialties,
    required this.rating,
    required this.reviewsCount,
    required this.pricePerMinute,
    required this.isActive,
    required this.isAvailable,
    required this.isOnline,
    required this.availability,
    required this.biography,
    required this.bio,
    required this.experience,
    required this.yearsOfExperience,
    required this.languages,
    required this.totalAppointments,
    required this.totalReviews,
    required this.createdAt,
    required this.updatedAt,
    this.lastSeen,
  });

  factory MediumModel.fromMap(Map<String, dynamic> map, String id) {
    return MediumModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      description: map['description'] ?? map['bio'] ?? '',
      imageUrl: map['imageUrl'],
      specialties: List<String>.from(map['specialties'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewsCount: map['reviewsCount'] ?? map['totalReviews'] ?? 0,
      pricePerMinute: (map['pricePerMinute'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? true,
      isAvailable: map['isAvailable'] ?? false,
      isOnline: map['isOnline'] ?? false,
      availability: Map<String, dynamic>.from(map['availability'] ?? {}),
      biography: map['biography'] ?? map['bio'] ?? map['description'] ?? '',
      bio: map['bio'] ?? map['biography'] ?? map['description'] ?? '',
      experience: map['experience'] ?? '',
      yearsOfExperience: map['yearsOfExperience'] ?? 0,
      languages: List<String>.from(map['languages'] ?? ['Português']),
      totalAppointments: map['totalAppointments'] ?? 0,
      totalReviews: map['totalReviews'] ?? map['reviewsCount'] ?? 0,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      lastSeen: _parseDateTime(map['lastSeen']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    } else if (value.runtimeType.toString().contains('Timestamp')) {
      try {
        return value.toDate();
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'description': description,
      'imageUrl': imageUrl,
      'specialties': specialties,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'totalReviews': totalReviews,
      'pricePerMinute': pricePerMinute,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'isOnline': isOnline,
      'availability': availability,
      'biography': biography,
      'bio': bio,
      'experience': experience,
      'yearsOfExperience': yearsOfExperience,
      'languages': languages,
      'totalAppointments': totalAppointments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  MediumModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? description,
    String? imageUrl,
    List<String>? specialties,
    double? rating,
    int? reviewsCount,
    double? pricePerMinute,
    bool? isActive,
    bool? isAvailable,
    bool? isOnline,
    Map<String, dynamic>? availability,
    String? biography,
    String? bio,
    String? experience,
    int? yearsOfExperience,
    List<String>? languages,
    int? totalAppointments,
    int? totalReviews,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeen,
  }) {
    return MediumModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      specialties: specialties ?? this.specialties,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      pricePerMinute: pricePerMinute ?? this.pricePerMinute,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      isOnline: isOnline ?? this.isOnline,
      availability: availability ?? this.availability,
      biography: biography ?? this.biography,
      bio: bio ?? this.bio,
      experience: experience ?? this.experience,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      languages: languages ?? this.languages,
      totalAppointments: totalAppointments ?? this.totalAppointments,
      totalReviews: totalReviews ?? this.totalReviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  // Métodos auxiliares para compatibilidade
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  String get displayName => name.isNotEmpty ? name : email;

  String get displayBio => bio.isNotEmpty ? bio : (biography.isNotEmpty ? biography : description);

  bool get isProfileComplete {
    return name.isNotEmpty &&
        displayBio.isNotEmpty &&
        specialties.isNotEmpty &&
        pricePerMinute > 0;
  }

  String get formattedRating => rating.toStringAsFixed(1);

  String get formattedPrice => 'R\$ ${pricePerMinute.toStringAsFixed(2)}/min';

  @override
  String toString() {
    return 'MediumModel(id: $id, name: $name, email: $email, isActive: $isActive, isAvailable: $isAvailable)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediumModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
