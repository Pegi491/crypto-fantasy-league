// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Team _$TeamFromJson(Map<String, dynamic> json) => Team(
      id: json['id'] as String,
      leagueId: json['leagueId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      draft: (json['draft'] as List<dynamic>).map((e) => e as String).toList(),
      bench: (json['bench'] as List<dynamic>).map((e) => e as String).toList(),
      wins: (json['wins'] as num).toInt(),
      losses: (json['losses'] as num).toInt(),
      streak: (json['streak'] as num).toInt(),
      totalPoints: (json['totalPoints'] as num).toDouble(),
      createdAt: const TimestampConverter().fromJson(json['created_at']),
      updatedAt: const TimestampConverter().fromJson(json['updated_at']),
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$TeamToJson(Team instance) => <String, dynamic>{
      'id': instance.id,
      'leagueId': instance.leagueId,
      'userId': instance.userId,
      'name': instance.name,
      'avatar': instance.avatar,
      'draft': instance.draft,
      'bench': instance.bench,
      'wins': instance.wins,
      'losses': instance.losses,
      'streak': instance.streak,
      'totalPoints': instance.totalPoints,
      'created_at': const TimestampConverter().toJson(instance.createdAt),
      'updated_at': const TimestampConverter().toJson(instance.updatedAt),
    };

TeamWeeklyData _$TeamWeeklyDataFromJson(Map<String, dynamic> json) =>
    TeamWeeklyData(
      teamId: json['teamId'] as String,
      week: (json['week'] as num).toInt(),
      shield: ShieldStatus.fromJson(json['shield'] as Map<String, dynamic>),
      faMovesRemaining: (json['faMovesRemaining'] as num).toInt(),
      createdAt: const TimestampConverter().fromJson(json['created_at']),
      updatedAt: const TimestampConverter().fromJson(json['updated_at']),
      captainAssetId: json['captainAssetId'] as String?,
    );

Map<String, dynamic> _$TeamWeeklyDataToJson(TeamWeeklyData instance) =>
    <String, dynamic>{
      'teamId': instance.teamId,
      'week': instance.week,
      'captainAssetId': instance.captainAssetId,
      'shield': instance.shield,
      'faMovesRemaining': instance.faMovesRemaining,
      'created_at': const TimestampConverter().toJson(instance.createdAt),
      'updated_at': const TimestampConverter().toJson(instance.updatedAt),
    };

ShieldStatus _$ShieldStatusFromJson(Map<String, dynamic> json) => ShieldStatus(
      status: $enumDecode(_$ShieldStatusTypeEnumMap, json['status']),
      assetId: json['assetId'] as String?,
      day: json['day'] as String?,
    );

Map<String, dynamic> _$ShieldStatusToJson(ShieldStatus instance) =>
    <String, dynamic>{
      'status': _$ShieldStatusTypeEnumMap[instance.status]!,
      'assetId': instance.assetId,
      'day': instance.day,
    };

const _$ShieldStatusTypeEnumMap = {
  ShieldStatusType.available: 'available',
  ShieldStatusType.activated: 'activated',
  ShieldStatusType.consumed: 'consumed',
};

FreeAgentMove _$FreeAgentMoveFromJson(Map<String, dynamic> json) =>
    FreeAgentMove(
      id: json['id'] as String,
      teamId: json['teamId'] as String,
      addAssetId: json['addAssetId'] as String,
      dropAssetId: json['dropAssetId'] as String,
      timestamp: const TimestampConverter().fromJson(json['timestamp']),
    );

Map<String, dynamic> _$FreeAgentMoveToJson(FreeAgentMove instance) =>
    <String, dynamic>{
      'id': instance.id,
      'teamId': instance.teamId,
      'addAssetId': instance.addAssetId,
      'dropAssetId': instance.dropAssetId,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
    };
