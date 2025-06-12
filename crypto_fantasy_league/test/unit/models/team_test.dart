import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_fantasy_league/models/team.dart';

void main() {
  group('Team Model Tests', () {
    late Team testTeam;

    setUp(() {
      testTeam = Team(
        id: 'test-team-id',
        leagueId: 'test-league-id',
        userId: 'user-123',
        name: 'Test Team',
        avatar: 'avatar-url',
        draft: ['asset1', 'asset2', 'asset3'],
        bench: ['asset4'],
        wins: 5,
        losses: 3,
        streak: 2,
        totalPoints: 125.5,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );
    });

    test('should create Team with all fields', () {
      expect(testTeam.id, 'test-team-id');
      expect(testTeam.leagueId, 'test-league-id');
      expect(testTeam.userId, 'user-123');
      expect(testTeam.name, 'Test Team');
      expect(testTeam.avatar, 'avatar-url');
      expect(testTeam.draft.length, 3);
      expect(testTeam.bench.length, 1);
      expect(testTeam.wins, 5);
      expect(testTeam.losses, 3);
      expect(testTeam.streak, 2);
      expect(testTeam.totalPoints, 125.5);
    });

    test('should validate team correctly', () {
      expect(testTeam.isValidTeam(), true);

      // Test invalid team with empty name
      final invalidTeam = testTeam.copyWith(name: '');
      expect(invalidTeam.isValidTeam(), false);

      // Test invalid team with empty user ID
      final invalidTeam2 = testTeam.copyWith(userId: '');
      expect(invalidTeam2.isValidTeam(), false);

      // Test invalid team with too many draft players
      final invalidTeam3 = testTeam.copyWith(
        draft: List.generate(8, (i) => 'asset$i'),
      );
      expect(invalidTeam3.isValidTeam(), false);

      // Test invalid team with too many bench players
      final invalidTeam4 = testTeam.copyWith(
        bench: List.generate(4, (i) => 'bench$i'),
      );
      expect(invalidTeam4.isValidTeam(), false);

      // Test invalid team with negative wins
      final invalidTeam5 = testTeam.copyWith(wins: -1);
      expect(invalidTeam5.isValidTeam(), false);
    });

    test('should check draft and bench capacity', () {
      expect(testTeam.canAddToDraft(), true); // 3 < 7
      expect(testTeam.canAddToBench(), true); // 1 < 3

      final fullDraftTeam = testTeam.copyWith(
        draft: List.generate(7, (i) => 'asset$i'),
      );
      expect(fullDraftTeam.canAddToDraft(), false);

      final fullBenchTeam = testTeam.copyWith(
        bench: List.generate(3, (i) => 'bench$i'),
      );
      expect(fullBenchTeam.canAddToBench(), false);
    });

    test('should check if team has specific asset', () {
      expect(testTeam.hasAsset('asset1'), true);
      expect(testTeam.hasAsset('asset4'), true);
      expect(testTeam.hasAsset('nonexistent'), false);
    });

    test('should calculate win percentage correctly', () {
      expect(testTeam.winPercentage, closeTo(0.625, 0.001)); // 5/8 = 0.625

      final noGamesTeam = testTeam.copyWith(wins: 0, losses: 0);
      expect(noGamesTeam.winPercentage, 0.0);
    });

    test('should calculate total games correctly', () {
      expect(testTeam.totalGames, 8); // 5 + 3
    });

    test('should identify streak type correctly', () {
      expect(testTeam.isOnWinStreak, true); // streak = 2 > 0
      expect(testTeam.isOnLossStreak, false);
      expect(testTeam.streakLength, 2);

      final lossStreakTeam = testTeam.copyWith(streak: -3);
      expect(lossStreakTeam.isOnWinStreak, false);
      expect(lossStreakTeam.isOnLossStreak, true);
      expect(lossStreakTeam.streakLength, 3);
    });

    test('should add win correctly', () {
      final updatedTeam = testTeam.addWin();
      
      expect(updatedTeam.wins, 6);
      expect(updatedTeam.losses, 3);
      expect(updatedTeam.streak, 3); // Continues win streak
      expect(updatedTeam.updatedAt.isAfter(testTeam.updatedAt), true);

      // Test adding win after loss streak
      final lossStreakTeam = testTeam.copyWith(streak: -2);
      final winAfterLoss = lossStreakTeam.addWin();
      expect(winAfterLoss.streak, 1); // Starts new win streak
    });

    test('should add loss correctly', () {
      final updatedTeam = testTeam.addLoss();
      
      expect(updatedTeam.wins, 5);
      expect(updatedTeam.losses, 4);
      expect(updatedTeam.streak, -1); // Starts loss streak
      expect(updatedTeam.updatedAt.isAfter(testTeam.updatedAt), true);

      // Test adding loss after another loss
      final lossTeam = updatedTeam.addLoss();
      expect(lossTeam.streak, -2); // Continues loss streak
    });

    test('should update points correctly', () {
      final updatedTeam = testTeam.updatePoints(25.5);
      
      expect(updatedTeam.totalPoints, 151.0); // 125.5 + 25.5
      expect(updatedTeam.updatedAt.isAfter(testTeam.updatedAt), true);
    });

    test('should copy with new values', () {
      final updatedTeam = testTeam.copyWith(
        name: 'Updated Team',
        wins: 6,
        draft: ['new1', 'new2'],
      );

      expect(updatedTeam.name, 'Updated Team');
      expect(updatedTeam.wins, 6);
      expect(updatedTeam.draft, ['new1', 'new2']);
      
      // Other fields should remain unchanged
      expect(updatedTeam.id, testTeam.id);
      expect(updatedTeam.userId, testTeam.userId);
      expect(updatedTeam.losses, testTeam.losses);
    });

    test('should serialize to and from JSON', () {
      final json = testTeam.toJson();
      final deserializedTeam = Team.fromJson(json);

      expect(deserializedTeam.id, testTeam.id);
      expect(deserializedTeam.name, testTeam.name);
      expect(deserializedTeam.draft, testTeam.draft);
      expect(deserializedTeam.bench, testTeam.bench);
      expect(deserializedTeam.wins, testTeam.wins);
      expect(deserializedTeam.losses, testTeam.losses);
      expect(deserializedTeam.streak, testTeam.streak);
      expect(deserializedTeam.totalPoints, testTeam.totalPoints);
    });
  });

  group('TeamWeeklyData Tests', () {
    late TeamWeeklyData testWeeklyData;

    setUp(() {
      testWeeklyData = TeamWeeklyData(
        teamId: 'team-123',
        week: 5,
        captainAssetId: 'captain-asset',
        shield: ShieldStatus.available(),
        faMovesRemaining: 3,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    test('should create TeamWeeklyData correctly', () {
      expect(testWeeklyData.teamId, 'team-123');
      expect(testWeeklyData.week, 5);
      expect(testWeeklyData.captainAssetId, 'captain-asset');
      expect(testWeeklyData.shield.status, ShieldStatusType.available);
      expect(testWeeklyData.faMovesRemaining, 3);
    });

    test('should check free agent usage', () {
      expect(testWeeklyData.canUseFreeAgent(), true);

      final noMovesData = testWeeklyData.copyWith(faMovesRemaining: 0);
      expect(noMovesData.canUseFreeAgent(), false);
    });

    test('should check shield activation', () {
      expect(testWeeklyData.canActivateShield(), true);

      final activatedData = testWeeklyData.copyWith(
        shield: ShieldStatus(status: ShieldStatusType.activated, assetId: 'asset1'),
      );
      expect(activatedData.canActivateShield(), false);
    });

    test('should use free agent move', () {
      final updatedData = testWeeklyData.useFreeAgent();
      
      expect(updatedData.faMovesRemaining, 2);
      expect(updatedData.updatedAt.isAfter(testWeeklyData.updatedAt), true);
    });

    test('should activate shield', () {
      final updatedData = testWeeklyData.activateShield('asset123');
      
      expect(updatedData.shield.status, ShieldStatusType.activated);
      expect(updatedData.shield.assetId, 'asset123');
      expect(updatedData.updatedAt.isAfter(testWeeklyData.updatedAt), true);
    });
  });

  group('ShieldStatus Tests', () {
    test('should create available shield', () {
      final shield = ShieldStatus.available();
      
      expect(shield.status, ShieldStatusType.available);
      expect(shield.assetId, null);
      expect(shield.day, null);
    });

    test('should activate shield', () {
      final availableShield = ShieldStatus.available();
      final activatedShield = availableShield.activate('asset123');
      
      expect(activatedShield.status, ShieldStatusType.activated);
      expect(activatedShield.assetId, 'asset123');
      expect(activatedShield.day, null);
    });

    test('should consume shield', () {
      final activatedShield = ShieldStatus(
        status: ShieldStatusType.activated,
        assetId: 'asset123',
      );
      final consumedShield = activatedShield.consume('Monday');
      
      expect(consumedShield.status, ShieldStatusType.consumed);
      expect(consumedShield.assetId, 'asset123');
      expect(consumedShield.day, 'Monday');
    });

    test('should serialize shield status', () {
      final shield = ShieldStatus(
        status: ShieldStatusType.activated,
        assetId: 'asset123',
      );
      
      final json = shield.toJson();
      final deserializedShield = ShieldStatus.fromJson(json);
      
      expect(deserializedShield.status, shield.status);
      expect(deserializedShield.assetId, shield.assetId);
    });
  });

  group('FreeAgentMove Tests', () {
    late FreeAgentMove testMove;

    setUp(() {
      testMove = FreeAgentMove(
        id: 'move-123',
        teamId: 'team-456',
        addAssetId: 'add-asset',
        dropAssetId: 'drop-asset',
        timestamp: DateTime(2024, 1, 1),
      );
    });

    test('should create FreeAgentMove correctly', () {
      expect(testMove.id, 'move-123');
      expect(testMove.teamId, 'team-456');
      expect(testMove.addAssetId, 'add-asset');
      expect(testMove.dropAssetId, 'drop-asset');
    });

    test('should serialize FA move', () {
      final json = testMove.toJson();
      final deserializedMove = FreeAgentMove.fromJson(json);
      
      expect(deserializedMove.id, testMove.id);
      expect(deserializedMove.teamId, testMove.teamId);
      expect(deserializedMove.addAssetId, testMove.addAssetId);
      expect(deserializedMove.dropAssetId, testMove.dropAssetId);
    });

    test('should handle Firestore conversion', () {
      final firestoreData = testMove.toFirestore();
      
      // ID should not be included in Firestore data
      expect(firestoreData.containsKey('id'), false);
      expect(firestoreData['teamId'], testMove.teamId);
      expect(firestoreData['addAssetId'], testMove.addAssetId);
    });
  });
}