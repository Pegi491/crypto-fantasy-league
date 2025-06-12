// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeamScore _$TeamScoreFromJson(Map<String, dynamic> json) => TeamScore(
      teamId: json['teamId'] as String,
      leagueId: json['leagueId'] as String,
      week: (json['week'] as num).toInt(),
      scoringType: $enumDecode(_$ScoringTypeEnumMap, json['scoringType']),
      rawReturn: (json['rawReturn'] as num).toDouble(),
      finalScore: (json['finalScore'] as num).toDouble(),
      ranking: (json['ranking'] as num).toInt(),
      assetScores: (json['assetScores'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, AssetScore.fromJson(e as Map<String, dynamic>)),
      ),
      calculatedAt: const TimestampConverter().fromJson(json['calculated_at']),
      riskScore: (json['riskScore'] as num?)?.toDouble(),
      rotisserieScore: (json['rotisserieScore'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TeamScoreToJson(TeamScore instance) => <String, dynamic>{
      'teamId': instance.teamId,
      'leagueId': instance.leagueId,
      'week': instance.week,
      'scoringType': _$ScoringTypeEnumMap[instance.scoringType]!,
      'rawReturn': instance.rawReturn,
      'riskScore': instance.riskScore,
      'rotisserieScore': instance.rotisserieScore,
      'finalScore': instance.finalScore,
      'ranking': instance.ranking,
      'assetScores': instance.assetScores,
      'calculated_at': const TimestampConverter().toJson(instance.calculatedAt),
    };

const _$ScoringTypeEnumMap = {
  ScoringType.raw: 'raw',
  ScoringType.riskAdjusted: 'riskAdjusted',
  ScoringType.par: 'par',
};

AssetScore _$AssetScoreFromJson(Map<String, dynamic> json) => AssetScore(
      assetId: json['assetId'] as String,
      assetSymbol: json['assetSymbol'] as String,
      startValue: (json['startValue'] as num).toDouble(),
      endValue: (json['endValue'] as num).toDouble(),
      returnPercent: (json['returnPercent'] as num).toDouble(),
      basePoints: (json['basePoints'] as num).toDouble(),
      points: (json['points'] as num).toDouble(),
      isCaptain: json['isCaptain'] as bool,
      shieldUsed: json['shieldUsed'] as bool,
      isFreeAgentPickup: json['isFreeAgentPickup'] as bool,
      rotisserieRankings:
          (json['rotisserieRankings'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      calculatedAt: const TimestampConverter().fromJson(json['calculated_at']),
    );

Map<String, dynamic> _$AssetScoreToJson(AssetScore instance) =>
    <String, dynamic>{
      'assetId': instance.assetId,
      'assetSymbol': instance.assetSymbol,
      'startValue': instance.startValue,
      'endValue': instance.endValue,
      'returnPercent': instance.returnPercent,
      'basePoints': instance.basePoints,
      'points': instance.points,
      'isCaptain': instance.isCaptain,
      'shieldUsed': instance.shieldUsed,
      'isFreeAgentPickup': instance.isFreeAgentPickup,
      'rotisserieRankings': instance.rotisserieRankings,
      'calculated_at': const TimestampConverter().toJson(instance.calculatedAt),
    };

LeagueStandings _$LeagueStandingsFromJson(Map<String, dynamic> json) =>
    LeagueStandings(
      leagueId: json['leagueId'] as String,
      week: (json['week'] as num).toInt(),
      standings: (json['standings'] as List<dynamic>)
          .map((e) => TeamStanding.fromJson(e as Map<String, dynamic>))
          .toList(),
      updatedAt: const TimestampConverter().fromJson(json['updated_at']),
    );

Map<String, dynamic> _$LeagueStandingsToJson(LeagueStandings instance) =>
    <String, dynamic>{
      'leagueId': instance.leagueId,
      'week': instance.week,
      'standings': instance.standings,
      'updated_at': const TimestampConverter().toJson(instance.updatedAt),
    };

TeamStanding _$TeamStandingFromJson(Map<String, dynamic> json) => TeamStanding(
      teamId: json['teamId'] as String,
      teamName: json['teamName'] as String,
      rank: (json['rank'] as num).toInt(),
      weeklyScore: (json['weeklyScore'] as num).toDouble(),
      totalScore: (json['totalScore'] as num).toDouble(),
      wins: (json['wins'] as num).toInt(),
      losses: (json['losses'] as num).toInt(),
      streak: (json['streak'] as num).toInt(),
    );

Map<String, dynamic> _$TeamStandingToJson(TeamStanding instance) =>
    <String, dynamic>{
      'teamId': instance.teamId,
      'teamName': instance.teamName,
      'rank': instance.rank,
      'weeklyScore': instance.weeklyScore,
      'totalScore': instance.totalScore,
      'wins': instance.wins,
      'losses': instance.losses,
      'streak': instance.streak,
    };
