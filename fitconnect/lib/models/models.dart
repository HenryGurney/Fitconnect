import 'package:flutter/foundation.dart';

@immutable
class ProfileModel {
  final String id;
  final String name;
  final String sport;
  final String skill;
  final String location;
  final String? imageUrl;
  final String tier;
  final int reliabilityScore;
  final bool isAdmin;
  final DateTime? updatedAt;

  bool get isPremium {
    final tierLower = tier.toLowerCase();
    return tierLower == 'premium' || tierLower == 'pro' || isAdmin;
  }

  const ProfileModel({
    required this.id,
    required this.name,
    required this.sport,
    required this.skill,
    required this.location,
    this.imageUrl,
    this.tier = 'free',
    this.reliabilityScore = 100,
    this.isAdmin = false,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final tierStr = json['tier']?.toString().toLowerCase() ?? 'free';
    final bool adminFlag = json['is_admin'] == true || tierStr == 'admin';

    return ProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Athlete',
      sport: json['sport']?.toString() ?? 'Futsal',
      skill: json['skill_level']?.toString() ?? json['skill']?.toString() ?? 'Intermediate',
      location: json['location']?.toString() ?? 'Kuala Lumpur',
      imageUrl: json['image_url']?.toString() ??
          json['imageUrl']?.toString() ??
          json['avatar_url']?.toString() ??
          json['avatarUrl']?.toString() ??
          json['photo_url']?.toString() ??
          json['photoUrl']?.toString() ??
          json['profile_image']?.toString(),
      tier: tierStr,
      reliabilityScore: json['reliability_score'] is int
          ? json['reliability_score'] as int
          : int.tryParse(json['reliability_score']?.toString() ?? '100') ?? 100,
      isAdmin: adminFlag,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sport': sport,
      'skill_level': skill,
      'location': location,
      'image_url': imageUrl,
      'tier': tier,
      'reliability_score': reliabilityScore,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? sport,
    String? skill,
    String? location,
    String? imageUrl,
    String? tier,
    int? reliabilityScore,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sport: sport ?? this.sport,
      skill: skill ?? this.skill,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      tier: tier ?? this.tier,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@immutable
class LobbyModel {
  final String id;
  final String title;
  final String sport;
  final String locationName;
  final double latitude;
  final double longitude;
  final List<String> skills;
  final int maxParticipants;
  final String hostId;
  final DateTime? createdAt;
  final String? matchDate;
  final String? matchTime;
  final bool hasReferee;
  final String? refereeId;
  final String? refereeName;
  final ProfileModel? hostProfile;

  const LobbyModel({
    required this.id,
    required this.title,
    required this.sport,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.skills,
    required this.maxParticipants,
    required this.hostId,
    this.createdAt,
    this.matchDate,
    this.matchTime,
    this.hasReferee = false,
    this.refereeId,
    this.refereeName,
    this.hostProfile,
  });

  factory LobbyModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedSkills = [];
    if (json['skills'] != null) {
      if (json['skills'] is List) {
        parsedSkills = (json['skills'] as List)
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }

    ProfileModel? parsedHostProfile;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      parsedHostProfile = ProfileModel.fromJson(json['profiles'] as Map<String, dynamic>);
    }

    final rawTitle = json['title']?.toString() ?? 'Casual Match';
    final bool refFlag = json['has_referee'] == true ||
        rawTitle.toLowerCase().contains('referee') ||
        rawTitle.toLowerCase().contains('[ref]');

    return LobbyModel(
      id: json['id']?.toString() ?? '',
      title: rawTitle,
      sport: json['sport']?.toString() ?? 'Futsal',
      locationName: json['location_name']?.toString() ?? json['location']?.toString() ?? 'Unknown Venue',
      latitude: double.tryParse(json['latitude']?.toString() ?? '3.1390') ?? 3.1390,
      longitude: double.tryParse(json['longitude']?.toString() ?? '101.6869') ?? 101.6869,
      skills: parsedSkills.isEmpty ? ['Open to All'] : parsedSkills,
      maxParticipants: json['max_participants'] is int
          ? json['max_participants'] as int
          : int.tryParse(json['max_participants']?.toString() ?? '10') ?? 10,
      hostId: json['host_id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      matchDate: json['match_date']?.toString() ?? json['date']?.toString(),
      matchTime: json['match_time']?.toString() ?? json['time']?.toString(),
      hasReferee: refFlag,
      refereeId: json['referee_id']?.toString(),
      refereeName: json['referee_name']?.toString(),
      hostProfile: parsedHostProfile,
    );
  }

  /// Extracts clean title without fee, referee or gender bracket tags
  String get cleanTitle {
    var text = title;
    text = text.replaceAll(RegExp(r'•\s*\[[^\]]*\]?'), '');
    text = text.replaceAll(RegExp(r'\[[^\]]*\]?'), '');
    text = text.replaceAll(RegExp(r'[\[\]]'), '');
    text = text.replaceAll(RegExp(r'•\s*$'), '');
    final trimmed = text.trim();
    return trimmed.isNotEmpty ? trimmed : title;
  }

  /// Extracts fee per pax (e.g. "RM 10 / pax" or "Free")
  String? get feePerPax {
    final feeMatch = RegExp(r'(?:\[)?(RM\s*[\d\.]+(?:\s*\/\s*pax)?|Free(?:[^\s\]]*)?)(?:\])?', caseSensitive: false).firstMatch(title);
    if (feeMatch != null) {
      final fee = feeMatch.group(1)?.replaceAll(RegExp(r'[\[\]]'), '').trim();
      if (fee != null && fee.isNotEmpty) {
        return fee;
      }
    }
    return null;
  }

  /// Extracts gender restriction (e.g. "Male Only", "Female Only")
  String? get genderRestriction {
    if (title.toLowerCase().contains('male only')) return 'Male Only';
    if (title.toLowerCase().contains('female only')) return 'Female Only';
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'sport': sport,
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'skills': skills,
      'max_participants': maxParticipants,
      'host_id': hostId,
      'has_referee': hasReferee,
      if (refereeId != null) 'referee_id': refereeId,
      if (refereeName != null) 'referee_name': refereeName,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (matchDate != null) 'match_date': matchDate,
      if (matchTime != null) 'match_time': matchTime,
    };
  }
}

@immutable
class LobbyParticipantModel {
  final String id;
  final String lobbyId;
  final String userId;
  final String status; // 'pending', 'approved', 'rejected'
  final String role; // 'player', 'referee'
  final String? paymentStatus; // 'unpaid', 'paid', 'exempt'
  final DateTime? createdAt;
  final ProfileModel? userProfile;

  const LobbyParticipantModel({
    required this.id,
    required this.lobbyId,
    required this.userId,
    required this.status,
    this.role = 'player',
    this.paymentStatus,
    this.createdAt,
    this.userProfile,
  });

  factory LobbyParticipantModel.fromJson(Map<String, dynamic> json) {
    ProfileModel? parsedProfile;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      parsedProfile = ProfileModel.fromJson(json['profiles'] as Map<String, dynamic>);
    }

    return LobbyParticipantModel(
      id: json['id']?.toString() ?? '',
      lobbyId: json['lobby_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      role: json['role']?.toString() ?? 'player',
      paymentStatus: json['payment_status']?.toString() ?? (json['paid'] == true ? 'paid' : 'unpaid'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      userProfile: parsedProfile,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lobby_id': lobbyId,
      'user_id': userId,
      'status': status,
      'role': role,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

@immutable
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String? imageUrl;
  final bool isReceipt;
  final DateTime createdAt;
  final ProfileModel? senderProfile;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.imageUrl,
    this.isReceipt = false,
    required this.createdAt,
    this.senderProfile,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    ProfileModel? parsedSender;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      parsedSender = ProfileModel.fromJson(json['profiles'] as Map<String, dynamic>);
    }

    final rawImage = json['image_url']?.toString() ?? json['imageUrl']?.toString() ?? json['attachment_url']?.toString();

    return MessageModel(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      imageUrl: rawImage,
      isReceipt: json['is_receipt'] == true || (rawImage != null && (json['content']?.toString().contains('Receipt') ?? false)),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      senderProfile: parsedSender,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_receipt': isReceipt,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

@immutable
class ConversationModel {
  final ProfileModel athlete;
  final MessageModel? lastMessage;
  final int unreadCount;

  const ConversationModel({
    required this.athlete,
    this.lastMessage,
    this.unreadCount = 0,
  });
}

