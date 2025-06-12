import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_fantasy_league/models/league.dart';

void main() {
  group('League Model Tests', () {
    late League testLeague;

    setUp(() {
      testLeague = League(
        id: 'test-league-id',
        name: 'Test League',
        commissionerId: 'commissioner-123',
        mode: LeagueMode.walletLeague,
        scoringType: ScoringType.raw,
        seasonWeek: 1,
        maxTeams: 10,
        isPublic: true,
        description: 'Test league description',
        inviteCode: 'ABC123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    test('should create League with required fields', () {
      expect(testLeague.id, 'test-league-id');
      expect(testLeague.name, 'Test League');
      expect(testLeague.commissionerId, 'commissioner-123');
      expect(testLeague.mode, LeagueMode.walletLeague);
      expect(testLeague.scoringType, ScoringType.raw);
      expect(testLeague.seasonWeek, 1);
      expect(testLeague.maxTeams, 10);
      expect(testLeague.isPublic, true);
    });

    test('should validate league correctly', () {
      expect(testLeague.isValidLeague(), true);

      // Test invalid league with empty name
      final invalidLeague = testLeague.copyWith(name: '');
      expect(invalidLeague.isValidLeague(), false);

      // Test invalid league with empty commissioner ID
      final invalidLeague2 = testLeague.copyWith(commissionerId: '');
      expect(invalidLeague2.isValidLeague(), false);

      // Test invalid league with negative season week
      final invalidLeague3 = testLeague.copyWith(seasonWeek: -1);
      expect(invalidLeague3.isValidLeague(), false);

      // Test invalid league with zero max teams
      final invalidLeague4 = testLeague.copyWith(maxTeams: 0);
      expect(invalidLeague4.isValidLeague(), false);

      // Test invalid league with too many max teams
      final invalidLeague5 = testLeague.copyWith(maxTeams: 25);
      expect(invalidLeague5.isValidLeague(), false);
    });

    test('should check if teams can be added', () {
      expect(testLeague.canAddTeam(5), true); // 5 < 10
      expect(testLeague.canAddTeam(10), false); // 10 = 10
      expect(testLeague.canAddTeam(15), false); // 15 > 10
    });

    test('should check commissioner correctly', () {
      expect(testLeague.isCommissioner('commissioner-123'), true);
      expect(testLeague.isCommissioner('other-user'), false);
      expect(testLeague.isCommissioner(''), false);
    });

    test('should copy with new values', () {
      final updatedLeague = testLeague.copyWith(
        name: 'Updated League',
        seasonWeek: 2,
        isPublic: false,
      );

      expect(updatedLeague.name, 'Updated League');
      expect(updatedLeague.seasonWeek, 2);
      expect(updatedLeague.isPublic, false);
      
      // Other fields should remain unchanged
      expect(updatedLeague.id, testLeague.id);
      expect(updatedLeague.commissionerId, testLeague.commissionerId);
      expect(updatedLeague.mode, testLeague.mode);
    });

    test('should serialize to and from JSON', () {
      final json = testLeague.toJson();
      final deserializedLeague = League.fromJson(json);

      expect(deserializedLeague.id, testLeague.id);
      expect(deserializedLeague.name, testLeague.name);
      expect(deserializedLeague.commissionerId, testLeague.commissionerId);
      expect(deserializedLeague.mode, testLeague.mode);
      expect(deserializedLeague.scoringType, testLeague.scoringType);
      expect(deserializedLeague.seasonWeek, testLeague.seasonWeek);
      expect(deserializedLeague.maxTeams, testLeague.maxTeams);
      expect(deserializedLeague.isPublic, testLeague.isPublic);
      expect(deserializedLeague.description, testLeague.description);
      expect(deserializedLeague.inviteCode, testLeague.inviteCode);
    });

    test('should handle Firestore conversion', () {
      final firestoreData = testLeague.toFirestore();
      
      // ID should not be included in Firestore data
      expect(firestoreData.containsKey('id'), false);
      expect(firestoreData['name'], testLeague.name);
      expect(firestoreData['commissionerId'], testLeague.commissionerId);
    });

    test('should implement equality correctly', () {
      final sameLeague = League(
        id: testLeague.id,
        name: testLeague.name,
        commissionerId: testLeague.commissionerId,
        mode: testLeague.mode,
        scoringType: testLeague.scoringType,
        seasonWeek: testLeague.seasonWeek,
        maxTeams: testLeague.maxTeams,
        isPublic: testLeague.isPublic,
        createdAt: testLeague.createdAt,
        updatedAt: testLeague.updatedAt,
      );

      final differentLeague = testLeague.copyWith(id: 'different-id');

      expect(testLeague == sameLeague, true);
      expect(testLeague == differentLeague, false);
      expect(testLeague.hashCode == sameLeague.hashCode, true);
    });

    test('should have meaningful toString', () {
      final stringRepresentation = testLeague.toString();
      
      expect(stringRepresentation.contains('League{'), true);
      expect(stringRepresentation.contains('test-league-id'), true);
      expect(stringRepresentation.contains('Test League'), true);
      expect(stringRepresentation.contains('walletLeague'), true);
    });
  });

  group('LeagueMode Tests', () {
    test('should have correct enum values', () {
      expect(LeagueMode.values.length, 2);
      expect(LeagueMode.values.contains(LeagueMode.walletLeague), true);
      expect(LeagueMode.values.contains(LeagueMode.memeCoinLeague), true);
    });
  });

  group('ScoringType Tests', () {
    test('should have correct enum values', () {
      expect(ScoringType.values.length, 3);
      expect(ScoringType.values.contains(ScoringType.raw), true);
      expect(ScoringType.values.contains(ScoringType.riskAdjusted), true);
      expect(ScoringType.values.contains(ScoringType.par), true);
    });
  });

  group('TimestampConverter Tests', () {
    test('should convert DateTime to Timestamp and back', () {
      const converter = TimestampConverter();
      final dateTime = DateTime(2024, 1, 1, 12, 0, 0);
      
      final timestamp = converter.toJson(dateTime);
      final convertedBack = converter.fromJson(timestamp);
      
      expect(convertedBack.year, dateTime.year);
      expect(convertedBack.month, dateTime.month);
      expect(convertedBack.day, dateTime.day);
    });

    test('should handle string date conversion', () {
      const converter = TimestampConverter();
      final dateString = '2024-01-01T12:00:00.000Z';
      
      final convertedDate = converter.fromJson(dateString);
      
      expect(convertedDate.year, 2024);
      expect(convertedDate.month, 1);
      expect(convertedDate.day, 1);
    });

    test('should handle milliseconds conversion', () {
      const converter = TimestampConverter();
      final milliseconds = DateTime(2024, 1, 1).millisecondsSinceEpoch;
      
      final convertedDate = converter.fromJson(milliseconds);
      
      expect(convertedDate.year, 2024);
      expect(convertedDate.month, 1);
      expect(convertedDate.day, 1);
    });

    test('should throw error for invalid input', () {
      const converter = TimestampConverter();
      
      expect(
        () => converter.fromJson({'invalid': 'object'}),
        throwsArgumentError,
      );
    });
  });
}