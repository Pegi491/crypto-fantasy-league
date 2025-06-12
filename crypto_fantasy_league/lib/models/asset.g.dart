// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Asset _$AssetFromJson(Map<String, dynamic> json) => Asset(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      type: $enumDecode(_$AssetTypeEnumMap, json['type']),
      address: json['address'] as String,
      name: json['name'] as String,
      metadata: json['metadata'] as Map<String, dynamic>,
      isActive: json['isActive'] as bool,
      isPopular: json['isPopular'] as bool,
      createdAt: const TimestampConverter().fromJson(json['created_at']),
      updatedAt: const TimestampConverter().fromJson(json['updated_at']),
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
    );

Map<String, dynamic> _$AssetToJson(Asset instance) => <String, dynamic>{
      'id': instance.id,
      'symbol': instance.symbol,
      'type': _$AssetTypeEnumMap[instance.type]!,
      'address': instance.address,
      'name': instance.name,
      'description': instance.description,
      'logoUrl': instance.logoUrl,
      'metadata': instance.metadata,
      'isActive': instance.isActive,
      'isPopular': instance.isPopular,
      'created_at': const TimestampConverter().toJson(instance.createdAt),
      'updated_at': const TimestampConverter().toJson(instance.updatedAt),
    };

const _$AssetTypeEnumMap = {
  AssetType.wallet: 'wallet',
  AssetType.token: 'token',
};

DailyStats _$DailyStatsFromJson(Map<String, dynamic> json) => DailyStats(
      assetId: json['assetId'] as String,
      date: json['date'] as String,
      timestamp: const TimestampConverter().fromJson(json['timestamp']),
      priceUsd: (json['priceUsd'] as num?)?.toDouble(),
      volumeUsd: (json['volumeUsd'] as num?)?.toDouble(),
      holders: (json['holders'] as num?)?.toInt(),
      socialScore: (json['socialScore'] as num?)?.toDouble(),
      changePercent24h: (json['changePercent24h'] as num?)?.toDouble(),
      marketCapUsd: (json['marketCapUsd'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$DailyStatsToJson(DailyStats instance) =>
    <String, dynamic>{
      'assetId': instance.assetId,
      'date': instance.date,
      'priceUsd': instance.priceUsd,
      'volumeUsd': instance.volumeUsd,
      'holders': instance.holders,
      'socialScore': instance.socialScore,
      'changePercent24h': instance.changePercent24h,
      'marketCapUsd': instance.marketCapUsd,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
    };
