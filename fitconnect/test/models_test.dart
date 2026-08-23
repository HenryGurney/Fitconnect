import 'package:flutter_test/flutter_test.dart';
import 'package:fitconnect/models/models.dart';

void main() {
  group('ProfileModel Unit Tests', () {
    test('ProfileModel.fromJson parses complete json correctly', () {
      final json = {
        'id': 'user-123',
        'name': 'Aiman Harith',
        'sport': 'Futsal',
        'skill': 'Competitive',
        'location': 'Kuala Lumpur',
        'image_url': 'https://example.com/avatar.jpg',
        'tier': 'premium',
        'reliability_score': 95,
        'updated_at': '2026-08-07T12:00:00.000Z',
      };

      final profile = ProfileModel.fromJson(json);

      expect(profile.id, equals('user-123'));
      expect(profile.name, equals('Aiman Harith'));
      expect(profile.sport, equals('Futsal'));
      expect(profile.skill, equals('Competitive'));
      expect(profile.location, equals('Kuala Lumpur'));
      expect(profile.imageUrl, equals('https://example.com/avatar.jpg'));
      expect(profile.tier, equals('premium'));
      expect(profile.reliabilityScore, equals(95));
      expect(profile.updatedAt, equals(DateTime.parse('2026-08-07T12:00:00.000Z')));
    });

    test('ProfileModel.fromJson handles null and missing fields gracefully', () {
      final json = <String, dynamic>{};

      final profile = ProfileModel.fromJson(json);

      expect(profile.id, equals(''));
      expect(profile.name, equals('Athlete'));
      expect(profile.sport, equals('Futsal'));
      expect(profile.skill, equals('Intermediate'));
      expect(profile.location, equals('Kuala Lumpur'));
      expect(profile.imageUrl, isNull);
      expect(profile.tier, equals('free'));
      expect(profile.reliabilityScore, equals(100));
      expect(profile.updatedAt, isNull);
    });

    test('ProfileModel.toJson serializes correctly', () {
      const profile = ProfileModel(
        id: 'user-456',
        name: 'Aina',
        sport: 'Tennis',
        skill: 'Pro',
        location: 'Subang Jaya',
        tier: 'free',
        reliabilityScore: 100,
      );

      final json = profile.toJson();

      expect(json['id'], equals('user-456'));
      expect(json['name'], equals('Aina'));
      expect(json['sport'], equals('Tennis'));
      expect(json['skill_level'], equals('Pro'));
      expect(json['location'], equals('Subang Jaya'));
      expect(json['tier'], equals('free'));
      expect(json['reliability_score'], equals(100));
    });
  });

  group('LobbyModel Unit Tests', () {
    test('LobbyModel.fromJson parses complete json correctly', () {
      final json = {
        'id': 'lobby-789',
        'title': 'Friday Night Futsal',
        'sport': 'Futsal',
        'location_name': 'Subang Sports Complex',
        'latitude': '3.1415',
        'longitude': '101.68',
        'skills': ['Intermediate', 'Pro'],
        'max_participants': 12,
        'host_id': 'host-101',
        'created_at': '2026-08-07T10:00:00.000Z',
      };

      final lobby = LobbyModel.fromJson(json);

      expect(lobby.id, equals('lobby-789'));
      expect(lobby.title, equals('Friday Night Futsal'));
      expect(lobby.sport, equals('Futsal'));
      expect(lobby.locationName, equals('Subang Sports Complex'));
      expect(lobby.latitude, equals(3.1415));
      expect(lobby.longitude, equals(101.68));
      expect(lobby.skills, equals(['Intermediate', 'Pro']));
      expect(lobby.maxParticipants, equals(12));
      expect(lobby.hostId, equals('host-101'));
      expect(lobby.createdAt, equals(DateTime.parse('2026-08-07T10:00:00.000Z')));
    });

    test('LobbyModel.fromJson handles empty skills and invalid coordinates safely', () {
      final json = {
        'id': 'lobby-000',
        'latitude': 'invalid',
        'longitude': null,
      };

      final lobby = LobbyModel.fromJson(json);

      expect(lobby.id, equals('lobby-000'));
      expect(lobby.latitude, equals(3.1390));
      expect(lobby.longitude, equals(101.6869));
      expect(lobby.skills, equals(['Open to All']));
      expect(lobby.maxParticipants, equals(10));
    });
  });

  group('LobbyParticipantModel Unit Tests', () {
    test('LobbyParticipantModel.fromJson parses correctly', () {
      final json = {
        'id': 'part-1',
        'lobby_id': 'lobby-789',
        'user_id': 'user-123',
        'status': 'approved',
      };

      final participant = LobbyParticipantModel.fromJson(json);

      expect(participant.id, equals('part-1'));
      expect(participant.lobbyId, equals('lobby-789'));
      expect(participant.userId, equals('user-123'));
      expect(participant.status, equals('approved'));
    });
  });
}
