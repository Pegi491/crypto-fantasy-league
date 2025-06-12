import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_fantasy_league/models/score.dart';
import 'package:crypto_fantasy_league/models/league.dart';

void main() {
  group('TeamScore Tests', () {
    late TeamScore testScore;

    setUp(() {
      testScore = TeamScore(
        teamId: 'team-123',
        leagueId: 'league-456',
        week: 5,
        scoringType: ScoringType.raw,
        rawReturn: 125.5,
        finalScore: 98.3,
        ranking: 2,
        assetScores: {
          'asset1': AssetScore(
            assetId: 'asset1',
            assetSymbol: 'BTC',
            startValue: 50000.0,
            endValue: 52000.0,
            returnPercent: 4.0,
            basePoints: 40.0,
            points: 80.0,
            isCaptain: true,
            shieldUsed: false,
            isFreeAgentPickup: false,
            rotisserieRankings: {},
            calculatedAt: DateTime(2024, 1, 1),
          ),
        },
        calculatedAt: DateTime(2024, 1, 1),
        riskScore: 85.2,
        rotisserieScore: 92.1,
      );
    });

    test('should create TeamScore with all fields', () {
      expect(testScore.teamId, 'team-123');
      expect(testScore.leagueId, 'league-456');
      expect(testScore.week, 5);
      expect(testScore.scoringType, ScoringType.raw);
      expect(testScore.rawReturn, 125.5);
      expect(testScore.finalScore, 98.3);
      expect(testScore.ranking, 2);
      expect(testScore.riskScore, 85.2);
      expect(testScore.rotisserieScore, 92.1);
    });

    test('should validate score correctly', () {
      expect(testScore.isValidScore(), true);

      // Test invalid score with empty team ID
      final invalidScore = testScore.copyWith(teamId: '');
      expect(invalidScore.isValidScore(), false);

      // Test invalid score with negative week
      final invalidScore2 = testScore.copyWith(week: -1);
      expect(invalidScore2.isValidScore(), false);

      // Test invalid score with negative ranking
      final invalidScore3 = testScore.copyWith(ranking: 0);
      expect(invalidScore3.isValidScore(), false);
    });

    test('should calculate average asset score correctly', () {
      expect(testScore.averageAssetScore, 80.0);

      final multiAssetScore = testScore.copyWith(
        assetScores: {
          'asset1': testScore.assetScores['asset1']!,
          'asset2': testScore.assetScores['asset1']!.copyWith(
            assetId: 'asset2',
            points: 60.0,
          ),
        },
      );
      expect(multiAssetScore.averageAssetScore, 70.0); // (80 + 60) / 2
    });

    test('should find best and worst performing assets', () {
      final multiAssetScore = testScore.copyWith(
        assetScores: {
          'asset1': testScore.assetScores['asset1']!,
          'asset2': testScore.assetScores['asset1']!.copyWith(
            assetId: 'asset2',
            points: 60.0,
          ),
          'asset3': testScore.assetScores['asset1']!.copyWith(
            assetId: 'asset3',
            points: 100.0,
          ),
        },
      );

      final best = multiAssetScore.bestPerformingAsset;
      expect(best?.assetId, 'asset3');
      expect(best?.points, 100.0);

      final worst = multiAssetScore.worstPerformingAsset;
      expect(worst?.assetId, 'asset2');
      expect(worst?.points, 60.0);
    });

    test('should find captain score correctly', () {
      final captainScore = testScore.getCaptainScore();
      expect(captainScore?.assetId, 'asset1');
      expect(captainScore?.isCaptain, true);

      final noCaptainScore = testScore.copyWith(
        assetScores: {
          'asset1': testScore.assetScores['asset1']!.copyWith(isCaptain: false),
        },
      );
      expect(noCaptainScore.getCaptainScore(), null);
    });

    test('should find shielded assets correctly', () {
      expect(testScore.shieldedAssets.length, 0);

      final shieldedScore = testScore.copyWith(
        assetScores: {
          'asset1': testScore.assetScores['asset1']!.copyWith(shieldUsed: true),
        },
      );
      expect(shieldedScore.shieldedAssets.length, 1);
      expect(shieldedScore.shieldedAssets.first.assetId, 'asset1');
    });

    test('should calculate captain bonus points correctly', () {
      expect(testScore.captainBonusPoints, 40.0); // Base points of captain

      final noCaptainScore = testScore.copyWith(
        assetScores: {
          'asset1': testScore.assetScores['asset1']!.copyWith(isCaptain: false),
        },
      );
      expect(noCaptainScore.captainBonusPoints, 0.0);
    });

    test('should copy with new values', () {
      final updatedScore = testScore.copyWith(
        week: 6,
        finalScore: 150.0,
        ranking: 1,
      );

      expect(updatedScore.week, 6);
      expect(updatedScore.finalScore, 150.0);
      expect(updatedScore.ranking, 1);
      
      // Other fields should remain unchanged
      expect(updatedScore.teamId, testScore.teamId);
      expect(updatedScore.rawReturn, testScore.rawReturn);
    });

    test('should convert to JSON structure', () {
      final json = testScore.toJson();
      
      expect(json['teamId'], testScore.teamId);
      expect(json['week'], testScore.week);
      expect(json['rawReturn'], testScore.rawReturn);
      expect(json['finalScore'], testScore.finalScore);
      expect(json['ranking'], testScore.ranking);
    });

    test('should implement equality correctly', () {
      final sameScore = TeamScore(
        teamId: testScore.teamId,
        leagueId: testScore.leagueId,
        week: testScore.week,
        scoringType: testScore.scoringType,
        rawReturn: testScore.rawReturn,
        finalScore: testScore.finalScore,
        ranking: testScore.ranking,
        assetScores: testScore.assetScores,
        calculatedAt: testScore.calculatedAt,
        riskScore: testScore.riskScore,
        rotisserieScore: testScore.rotisserieScore,
      );

      final differentScore = testScore.copyWith(week: 6);

      expect(testScore == sameScore, true);
      expect(testScore == differentScore, false);
      expect(testScore.hashCode == sameScore.hashCode, true);
    });
  });

  group('AssetScore Tests', () {
    late AssetScore testAssetScore;

    setUp(() {
      testAssetScore = AssetScore(
        assetId: 'asset-456',
        assetSymbol: 'ETH',
        startValue: 3000.0,
        endValue: 3500.0,
        returnPercent: 16.67,
        basePoints: 45.8,
        points: 91.6,
        isCaptain: true,
        shieldUsed: false,
        isFreeAgentPickup: false,
        rotisserieRankings: {
          'price_change': 8.0,
          'volume_change': 6.0,
          'holder_growth': 7.0,
          'social_score': 9.0,
        },
        calculatedAt: DateTime(2024, 1, 1),
      );
    });

    test('should create AssetScore correctly', () {
      expect(testAssetScore.assetId, 'asset-456');
      expect(testAssetScore.assetSymbol, 'ETH');
      expect(testAssetScore.startValue, 3000.0);
      expect(testAssetScore.endValue, 3500.0);
      expect(testAssetScore.returnPercent, 16.67);
      expect(testAssetScore.basePoints, 45.8);
      expect(testAssetScore.points, 91.6);
      expect(testAssetScore.isCaptain, true);
      expect(testAssetScore.shieldUsed, false);
    });

    test('should calculate captain bonus points correctly', () {
      expect(testAssetScore.captainBonusPoints, 45.8); // Same as base points

      final nonCaptainScore = testAssetScore.copyWith(isCaptain: false);
      expect(nonCaptainScore.captainBonusPoints, 0.0);
    });

    test('should calculate free agent penalty correctly', () {
      expect(testAssetScore.freeAgentPenalty, 0.0);

      final freeAgentScore = testAssetScore.copyWith(isFreeAgentPickup: true);
      expect(freeAgentScore.freeAgentPenalty, -2.0);
    });

    test('should calculate net gain/loss correctly', () {
      expect(testAssetScore.netGainLoss, 500.0); // 3500 - 3000
    });

    test('should check return performance correctly', () {
      expect(testAssetScore.isPositiveReturn, true);
      expect(testAssetScore.isNegativeReturn, false);

      final negativeScore = testAssetScore.copyWith(returnPercent: -5.0);
      expect(negativeScore.isPositiveReturn, false);
      expect(negativeScore.isNegativeReturn, true);
    });

    test('should handle rotisserie rankings correctly', () {
      expect(testAssetScore.priceChangeRank, 8.0);
      expect(testAssetScore.volumeChangeRank, 6.0);
      expect(testAssetScore.holderGrowthRank, 7.0);
      expect(testAssetScore.socialScoreRank, 9.0);
      expect(testAssetScore.totalRotisseriePoints, 30.0); // 8+6+7+9
    });

    test('should copy with new values', () {
      final updatedScore = testAssetScore.copyWith(
        endValue: 4000.0,
        returnPercent: 33.33,
        points: 120.0,
      );

      expect(updatedScore.endValue, 4000.0);
      expect(updatedScore.returnPercent, 33.33);
      expect(updatedScore.points, 120.0);
      
      // Other fields should remain unchanged
      expect(updatedScore.assetId, testAssetScore.assetId);
      expect(updatedScore.startValue, testAssetScore.startValue);
    });

    test('should serialize to and from JSON', () {
      final json = testAssetScore.toJson();
      final deserializedScore = AssetScore.fromJson(json);

      expect(deserializedScore.assetId, testAssetScore.assetId);
      expect(deserializedScore.assetSymbol, testAssetScore.assetSymbol);
      expect(deserializedScore.returnPercent, testAssetScore.returnPercent);
      expect(deserializedScore.points, testAssetScore.points);
      expect(deserializedScore.isCaptain, testAssetScore.isCaptain);
    });
  });

  group('LeagueStandings Tests', () {
    late LeagueStandings testStandings;
    late List<TeamStanding> testStandingsList;

    setUp(() {
      testStandingsList = [
        TeamStanding(
          teamId: 'team-1',
          teamName: 'Team Alpha',
          rank: 1,
          weeklyScore: 125.5,
          totalScore: 350.5,
          wins: 2,
          losses: 1,
          streak: 2,
        ),
        TeamStanding(
          teamId: 'team-2',
          teamName: 'Team Beta',
          rank: 2,
          weeklyScore: 98.3,
          totalScore: 320.1,
          wins: 1,
          losses: 2,
          streak: -1,
        ),
      ];

      testStandings = LeagueStandings(
        leagueId: 'league-789',
        week: 3,
        standings: testStandingsList,
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    test('should create LeagueStandings correctly', () {
      expect(testStandings.leagueId, 'league-789');
      expect(testStandings.week, 3);
      expect(testStandings.standings.length, 2);
    });

    test('should get team standing by ID correctly', () {
      final team1 = testStandings.getTeamStanding('team-1');
      expect(team1?.teamName, 'Team Alpha');
      expect(team1?.rank, 1);

      final nonExistent = testStandings.getTeamStanding('team-999');
      expect(nonExistent, null);
    });

    test('should get top teams correctly', () {
      final top1 = testStandings.getTopTeams(1);
      expect(top1.length, 1);
      expect(top1[0].teamName, 'Team Alpha');

      final top2 = testStandings.getTopTeams(2);
      expect(top2.length, 2);
      expect(top2[0].teamName, 'Team Alpha');
      expect(top2[1].teamName, 'Team Beta');

      final top5 = testStandings.getTopTeams(5);
      expect(top5.length, 2); // Only 2 teams available
    });

    test('should copy with new values', () {
      final newStandings = [testStandingsList[0]]; // Only first team
      final updatedStandings = testStandings.copyWith(
        week: 4,
        standings: newStandings,
      );

      expect(updatedStandings.week, 4);
      expect(updatedStandings.standings.length, 1);
      
      // Other fields should remain unchanged
      expect(updatedStandings.leagueId, testStandings.leagueId);
    });

    test('should convert to JSON structure', () {
      final json = testStandings.toJson();

      expect(json['leagueId'], testStandings.leagueId);
      expect(json['week'], testStandings.week);
      expect(json['standings'] is List, true);
    });
  });

  group('TeamStanding Tests', () {
    late TeamStanding testStanding;

    setUp(() {
      testStanding = TeamStanding(
        teamId: 'team-555',
        teamName: 'Team Gamma',
        rank: 3,
        weeklyScore: 95.2,
        totalScore: 280.7,
        wins: 1,
        losses: 2,
        streak: -2,
      );
    });

    test('should create TeamStanding correctly', () {
      expect(testStanding.teamId, 'team-555');
      expect(testStanding.teamName, 'Team Gamma');
      expect(testStanding.rank, 3);
      expect(testStanding.weeklyScore, 95.2);
      expect(testStanding.totalScore, 280.7);
      expect(testStanding.wins, 1);
      expect(testStanding.losses, 2);
      expect(testStanding.streak, -2);
    });

    test('should serialize to and from JSON', () {
      final json = testStanding.toJson();
      final deserializedStanding = TeamStanding.fromJson(json);

      expect(deserializedStanding.teamId, testStanding.teamId);
      expect(deserializedStanding.teamName, testStanding.teamName);
      expect(deserializedStanding.rank, testStanding.rank);
      expect(deserializedStanding.weeklyScore, testStanding.weeklyScore);
      expect(deserializedStanding.totalScore, testStanding.totalScore);
      expect(deserializedStanding.wins, testStanding.wins);
      expect(deserializedStanding.losses, testStanding.losses);
      expect(deserializedStanding.streak, testStanding.streak);
    });
  });
}