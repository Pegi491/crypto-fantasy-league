// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'league.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

League _$LeagueFromJson(Map<String, dynamic> json) => League(
      id: json['id'] as String,
      name: json['name'] as String,
      commissionerId: json['commissionerId'] as String,
      mode: $enumDecode(_$LeagueModeEnumMap, json['mode']),
      scoringType: $enumDecode(_$ScoringTypeEnumMap, json['scoringType']),
      seasonWeek: (json['seasonWeek'] as num).toInt(),
      maxTeams: (json['maxTeams'] as num).toInt(),
      isPublic: json['isPublic'] as bool,
      createdAt: const TimestampConverter().fromJson(json['created_at']),
      updatedAt: const TimestampConverter().fromJson(json['updated_at']),
      description: json['description'] as String?,
      inviteCode: json['inviteCode'] as String?,
    );

Map<String, dynamic> _$LeagueToJson(League instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'commissionerId': instance.commissionerId,
      'mode': _$LeagueModeEnumMap[instance.mode]!,
      'scoringType': _$ScoringTypeEnumMap[instance.scoringType]!,
      'seasonWeek': instance.seasonWeek,
      'maxTeams': instance.maxTeams,
      'isPublic': instance.isPublic,
      'description': instance.description,
      'inviteCode': instance.inviteCode,
      'created_at': const TimestampConverter().toJson(instance.createdAt),
      'updated_at': const TimestampConverter().toJson(instance.updatedAt),
    };

const _$LeagueModeEnumMap = {
  LeagueMode.walletLeague: 'walletLeague',
  LeagueMode.memeCoinLeague: 'memeCoinLeague',
};

const _$ScoringTypeEnumMap = {
  ScoringType.raw: 'raw',
  ScoringType.riskAdjusted: 'riskAdjusted',
  ScoringType.par: 'par',
};
