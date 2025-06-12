// ABOUTME: Asset data model representing tradeable assets (wallets or tokens) in the fantasy league
// ABOUTME: Handles asset metadata, validation, and performance tracking

import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'league.dart'; // For TimestampConverter

part 'asset.g.dart';

enum AssetType { wallet, token }

@JsonSerializable()
class Asset {
  final String id;
  final String symbol;
  final AssetType type;
  final String address; // Wallet address or token contract address
  final String name;
  final String? description;
  final String? logoUrl;
  final Map<String, dynamic> metadata;
  final bool isActive;
  final bool isPopular;
  
  @JsonKey(name: 'created_at')
  @TimestampConverter()
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  @TimestampConverter()
  final DateTime updatedAt;

  const Asset({
    required this.id,
    required this.symbol,
    required this.type,
    required this.address,
    required this.name,
    required this.metadata,
    required this.isActive,
    required this.isPopular,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.logoUrl,
  });

  factory Asset.fromJson(Map<String, dynamic> json) => _$AssetFromJson(json);

  Map<String, dynamic> toJson() => _$AssetToJson(this);

  factory Asset.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Asset.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Don't store ID in document data
    return json;
  }

  Asset copyWith({
    String? id,
    String? symbol,
    AssetType? type,
    String? address,
    String? name,
    String? description,
    String? logoUrl,
    Map<String, dynamic>? metadata,
    bool? isActive,
    bool? isPopular,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Asset(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      address: address ?? this.address,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      metadata: metadata ?? Map.from(this.metadata),
      isActive: isActive ?? this.isActive,
      isPopular: isPopular ?? this.isPopular,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isValidAsset() {
    return symbol.trim().isNotEmpty &&
           address.trim().isNotEmpty &&
           name.trim().isNotEmpty &&
           _isValidAddress();
  }

  bool _isValidAddress() {
    switch (type) {
      case AssetType.wallet:
        return _isValidEthereumAddress(address);
      case AssetType.token:
        return _isValidTokenContract(address);
    }
  }

  bool _isValidEthereumAddress(String address) {
    // Basic Ethereum address validation
    final ethAddressRegex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return ethAddressRegex.hasMatch(address);
  }

  bool _isValidTokenContract(String address) {
    // Token contract addresses follow same format as wallet addresses
    return _isValidEthereumAddress(address);
  }

  String get displayName => name.isNotEmpty ? name : symbol;

  String get shortAddress {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  // Metadata helper methods
  String? get network => metadata['network'] as String?;
  double? get marketCap => (metadata['market_cap'] as num?)?.toDouble();
  double? get volume24h => (metadata['volume_24h'] as num?)?.toDouble();
  int? get holderCount => metadata['holder_count'] as int?;
  List<String>? get tags => (metadata['tags'] as List?)?.cast<String>();

  Asset updateMetadata(Map<String, dynamic> newMetadata) {
    return copyWith(
      metadata: {...metadata, ...newMetadata},
      updatedAt: DateTime.now(),
    );
  }

  Asset markAsPopular() {
    return copyWith(
      isPopular: true,
      updatedAt: DateTime.now(),
    );
  }

  Asset deactivate() {
    return copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Asset{id: $id, symbol: $symbol, type: $type, address: $shortAddress, '
           'name: $name, isActive: $isActive, isPopular: $isPopular}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Asset &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          symbol == other.symbol &&
          type == other.type &&
          address == other.address;

  @override
  int get hashCode =>
      id.hashCode ^
      symbol.hashCode ^
      type.hashCode ^
      address.hashCode;
}

@JsonSerializable()
class DailyStats {
  final String assetId;
  final String date; // YYYY-MM-DD format
  final double? priceUsd;
  final double? volumeUsd;
  final int? holders;
  final double? socialScore;
  final double? changePercent24h;
  final double? marketCapUsd;
  
  @JsonKey(name: 'timestamp')
  @TimestampConverter()
  final DateTime timestamp;

  const DailyStats({
    required this.assetId,
    required this.date,
    required this.timestamp,
    this.priceUsd,
    this.volumeUsd,
    this.holders,
    this.socialScore,
    this.changePercent24h,
    this.marketCapUsd,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) => 
      _$DailyStatsFromJson(json);

  Map<String, dynamic> toJson() => _$DailyStatsToJson(this);

  factory DailyStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyStats.fromJson(data);
  }

  Map<String, dynamic> toFirestore() => toJson();

  DailyStats copyWith({
    String? assetId,
    String? date,
    double? priceUsd,
    double? volumeUsd,
    int? holders,
    double? socialScore,
    double? changePercent24h,
    double? marketCapUsd,
    DateTime? timestamp,
  }) {
    return DailyStats(
      assetId: assetId ?? this.assetId,
      date: date ?? this.date,
      priceUsd: priceUsd ?? this.priceUsd,
      volumeUsd: volumeUsd ?? this.volumeUsd,
      holders: holders ?? this.holders,
      socialScore: socialScore ?? this.socialScore,
      changePercent24h: changePercent24h ?? this.changePercent24h,
      marketCapUsd: marketCapUsd ?? this.marketCapUsd,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool hasValidPriceData() {
    return priceUsd != null && priceUsd! > 0;
  }

  bool hasValidVolumeData() {
    return volumeUsd != null && volumeUsd! >= 0;
  }

  bool hasValidSocialData() {
    return socialScore != null && socialScore! >= 0 && socialScore! <= 100;
  }

  bool isComplete() {
    return hasValidPriceData() && hasValidVolumeData();
  }

  // Calculate rotisserie scoring metrics
  double get volumeChangePercent => changePercent24h ?? 0.0;
  
  double get holderGrowth {
    // This would typically be calculated against previous day
    // For now, return holders count as a proxy
    return (holders ?? 0).toDouble();
  }

  @override
  String toString() {
    return 'DailyStats{assetId: $assetId, date: $date, '
           'priceUsd: $priceUsd, volumeUsd: $volumeUsd, '
           'holders: $holders, socialScore: $socialScore}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStats &&
          runtimeType == other.runtimeType &&
          assetId == other.assetId &&
          date == other.date;

  @override
  int get hashCode =>
      assetId.hashCode ^
      date.hashCode;
}