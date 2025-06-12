// ABOUTME: Score data model for tracking team performance and league rankings
// ABOUTME: Handles different scoring types (raw, risk-adjusted, rotisserie) and weekly calculations

import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'league.dart'; // For TimestampConverter and ScoringType

part 'score.g.dart';

@JsonSerializable()
class TeamScore {
  final String teamId;
  final String leagueId;
  final int week;
  final ScoringType scoringType;
  final double rawReturn;
  final double? riskScore;
  final double? rotisserieScore;
  final double finalScore;
  final int ranking;
  final Map<String, AssetScore> assetScores;
  
  @JsonKey(name: 'calculated_at')
  @TimestampConverter()
  final DateTime calculatedAt;

  const TeamScore({
    required this.teamId,
    required this.leagueId,
    required this.week,
    required this.scoringType,
    required this.rawReturn,
    required this.finalScore,
    required this.ranking,
    required this.assetScores,
    required this.calculatedAt,
    this.riskScore,
    this.rotisserieScore,
  });

  factory TeamScore.fromJson(Map<String, dynamic> json) => 
      _$TeamScoreFromJson(json);

  Map<String, dynamic> toJson() => _$TeamScoreToJson(this);

  factory TeamScore.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamScore.fromJson(data);
  }

  Map<String, dynamic> toFirestore() => toJson();

  TeamScore copyWith({
    String? teamId,
    String? leagueId,
    int? week,
    ScoringType? scoringType,
    double? rawReturn,
    double? riskScore,
    double? rotisserieScore,
    double? finalScore,
    int? ranking,
    Map<String, AssetScore>? assetScores,
    DateTime? calculatedAt,
  }) {
    return TeamScore(
      teamId: teamId ?? this.teamId,
      leagueId: leagueId ?? this.leagueId,
      week: week ?? this.week,
      scoringType: scoringType ?? this.scoringType,
      rawReturn: rawReturn ?? this.rawReturn,
      riskScore: riskScore ?? this.riskScore,
      rotisserieScore: rotisserieScore ?? this.rotisserieScore,
      finalScore: finalScore ?? this.finalScore,
      ranking: ranking ?? this.ranking,
      assetScores: assetScores ?? Map.from(this.assetScores),
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  double get averageAssetScore {
    if (assetScores.isEmpty) return 0.0;
    final total = assetScores.values
        .map((score) => score.points)
        .reduce((a, b) => a + b);
    return total / assetScores.length;
  }

  AssetScore? get bestPerformingAsset {
    if (assetScores.isEmpty) return null;
    return assetScores.values
        .reduce((a, b) => a.points > b.points ? a : b);
  }

  AssetScore? get worstPerformingAsset {
    if (assetScores.isEmpty) return null;
    return assetScores.values
        .reduce((a, b) => a.points < b.points ? a : b);
  }

  AssetScore? getCaptainScore() {
    return assetScores.values
        .where((score) => score.isCaptain)
        .firstOrNull;
  }

  List<AssetScore> get shieldedAssets {
    return assetScores.values
        .where((score) => score.shieldUsed)
        .toList();
  }

  double get captainBonusPoints {
    final captainScore = getCaptainScore();
    return captainScore?.captainBonusPoints ?? 0.0;
  }

  bool isValidScore() {
    return teamId.isNotEmpty &&
           leagueId.isNotEmpty &&
           week >= 0 &&
           !finalScore.isNaN &&
           ranking > 0;
  }

  @override
  String toString() {
    return 'TeamScore{teamId: $teamId, week: $week, scoringType: $scoringType, '
           'rawReturn: ${rawReturn.toStringAsFixed(2)}, '
           'finalScore: ${finalScore.toStringAsFixed(2)}, ranking: $ranking}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamScore &&
          runtimeType == other.runtimeType &&
          teamId == other.teamId &&
          leagueId == other.leagueId &&
          week == other.week;

  @override
  int get hashCode =>
      teamId.hashCode ^
      leagueId.hashCode ^
      week.hashCode;
}

@JsonSerializable()
class AssetScore {
  final String assetId;
  final String assetSymbol;
  final double startValue;
  final double endValue;
  final double returnPercent;
  final double basePoints;
  final double points; // Final points after multipliers
  final bool isCaptain;
  final bool shieldUsed;
  final bool isFreeAgentPickup;
  final Map<String, double> rotisserieRankings; // For meme coin leagues
  
  @JsonKey(name: 'calculated_at')
  @TimestampConverter()
  final DateTime calculatedAt;

  const AssetScore({
    required this.assetId,
    required this.assetSymbol,
    required this.startValue,
    required this.endValue,
    required this.returnPercent,
    required this.basePoints,
    required this.points,
    required this.isCaptain,
    required this.shieldUsed,
    required this.isFreeAgentPickup,
    required this.rotisserieRankings,
    required this.calculatedAt,
  });

  factory AssetScore.fromJson(Map<String, dynamic> json) => 
      _$AssetScoreFromJson(json);

  Map<String, dynamic> toJson() => _$AssetScoreToJson(this);

  AssetScore copyWith({
    String? assetId,
    String? assetSymbol,
    double? startValue,
    double? endValue,
    double? returnPercent,
    double? basePoints,
    double? points,
    bool? isCaptain,
    bool? shieldUsed,
    bool? isFreeAgentPickup,
    Map<String, double>? rotisserieRankings,
    DateTime? calculatedAt,
  }) {
    return AssetScore(
      assetId: assetId ?? this.assetId,
      assetSymbol: assetSymbol ?? this.assetSymbol,
      startValue: startValue ?? this.startValue,
      endValue: endValue ?? this.endValue,
      returnPercent: returnPercent ?? this.returnPercent,
      basePoints: basePoints ?? this.basePoints,
      points: points ?? this.points,
      isCaptain: isCaptain ?? this.isCaptain,
      shieldUsed: shieldUsed ?? this.shieldUsed,
      isFreeAgentPickup: isFreeAgentPickup ?? this.isFreeAgentPickup,
      rotisserieRankings: rotisserieRankings ?? Map.from(this.rotisserieRankings),
      calculatedAt: calculatedAt ?? this.calculatedAt,
    );
  }

  double get captainBonusPoints {
    return isCaptain ? basePoints : 0.0; // Captain gets 2x, so bonus is basePoints
  }

  double get freeAgentPenalty {
    return isFreeAgentPickup ? -2.0 : 0.0;
  }

  double get netGainLoss => endValue - startValue;

  bool get isPositiveReturn => returnPercent > 0;

  bool get isNegativeReturn => returnPercent < 0;

  // For rotisserie scoring in meme coin leagues
  double get priceChangeRank => rotisserieRankings['price_change'] ?? 0.0;
  double get volumeChangeRank => rotisserieRankings['volume_change'] ?? 0.0;
  double get holderGrowthRank => rotisserieRankings['holder_growth'] ?? 0.0;
  double get socialScoreRank => rotisserieRankings['social_score'] ?? 0.0;

  double get totalRotisseriePoints {
    return priceChangeRank + volumeChangeRank + holderGrowthRank + socialScoreRank;
  }

  @override
  String toString() {
    return 'AssetScore{assetId: $assetId, symbol: $assetSymbol, '
           'return: ${returnPercent.toStringAsFixed(2)}%, '
           'points: ${points.toStringAsFixed(2)}, isCaptain: $isCaptain}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetScore &&
          runtimeType == other.runtimeType &&
          assetId == other.assetId &&
          calculatedAt == other.calculatedAt;

  @override
  int get hashCode =>
      assetId.hashCode ^
      calculatedAt.hashCode;
}

@JsonSerializable()
class LeagueStandings {
  final String leagueId;
  final int week;
  final List<TeamStanding> standings;
  
  @JsonKey(name: 'updated_at')
  @TimestampConverter()
  final DateTime updatedAt;

  const LeagueStandings({
    required this.leagueId,
    required this.week,
    required this.standings,
    required this.updatedAt,
  });

  factory LeagueStandings.fromJson(Map<String, dynamic> json) => 
      _$LeagueStandingsFromJson(json);

  Map<String, dynamic> toJson() => _$LeagueStandingsToJson(this);

  factory LeagueStandings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeagueStandings.fromJson(data);
  }

  Map<String, dynamic> toFirestore() => toJson();

  LeagueStandings copyWith({
    String? leagueId,
    int? week,
    List<TeamStanding>? standings,
    DateTime? updatedAt,
  }) {
    return LeagueStandings(
      leagueId: leagueId ?? this.leagueId,
      week: week ?? this.week,
      standings: standings ?? List.from(this.standings),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  TeamStanding? getTeamStanding(String teamId) {
    try {
      return standings.firstWhere((standing) => standing.teamId == teamId);
    } catch (e) {
      return null;
    }
  }

  List<TeamStanding> getTopTeams(int count) {
    final sortedStandings = List<TeamStanding>.from(standings)
      ..sort((a, b) => a.rank.compareTo(b.rank));
    return sortedStandings.take(count).toList();
  }

  @override
  String toString() {
    return 'LeagueStandings{leagueId: $leagueId, week: $week, '
           'teams: ${standings.length}}';
  }
}

@JsonSerializable()
class TeamStanding {
  final String teamId;
  final String teamName;
  final int rank;
  final double weeklyScore;
  final double totalScore;
  final int wins;
  final int losses;
  final int streak;

  const TeamStanding({
    required this.teamId,
    required this.teamName,
    required this.rank,
    required this.weeklyScore,
    required this.totalScore,
    required this.wins,
    required this.losses,
    required this.streak,
  });

  factory TeamStanding.fromJson(Map<String, dynamic> json) => 
      _$TeamStandingFromJson(json);

  Map<String, dynamic> toJson() => _$TeamStandingToJson(this);

  double get winPercentage {
    final totalGames = wins + losses;
    return totalGames > 0 ? wins / totalGames : 0.0;
  }

  bool get isOnWinStreak => streak > 0;

  @override
  String toString() {
    return 'TeamStanding{teamId: $teamId, rank: $rank, '
           'totalScore: ${totalScore.toStringAsFixed(2)}, '
           'record: $wins-$losses}';
  }
}

// Extension to help with null safety
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}