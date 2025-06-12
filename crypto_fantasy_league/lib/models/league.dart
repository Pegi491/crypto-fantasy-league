// ABOUTME: League data model representing a fantasy league with settings and configuration
// ABOUTME: Handles league creation, settings, and member management with Firestore integration

import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'league.g.dart';

enum LeagueMode { walletLeague, memeCoinLeague }

enum ScoringType { raw, riskAdjusted, par }

@JsonSerializable()
class League {
  final String id;
  final String name;
  final String commissionerId;
  final LeagueMode mode;
  final ScoringType scoringType;
  final int seasonWeek;
  final int maxTeams;
  final bool isPublic;
  final String? description;
  final String? inviteCode;
  
  @JsonKey(name: 'created_at')
  @TimestampConverter()
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  @TimestampConverter()
  final DateTime updatedAt;

  const League({
    required this.id,
    required this.name,
    required this.commissionerId,
    required this.mode,
    required this.scoringType,
    required this.seasonWeek,
    required this.maxTeams,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.inviteCode,
  });

  factory League.fromJson(Map<String, dynamic> json) => _$LeagueFromJson(json);

  Map<String, dynamic> toJson() => _$LeagueToJson(this);

  factory League.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return League.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Don't store ID in document data
    return json;
  }

  League copyWith({
    String? id,
    String? name,
    String? commissionerId,
    LeagueMode? mode,
    ScoringType? scoringType,
    int? seasonWeek,
    int? maxTeams,
    bool? isPublic,
    String? description,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return League(
      id: id ?? this.id,
      name: name ?? this.name,
      commissionerId: commissionerId ?? this.commissionerId,
      mode: mode ?? this.mode,
      scoringType: scoringType ?? this.scoringType,
      seasonWeek: seasonWeek ?? this.seasonWeek,
      maxTeams: maxTeams ?? this.maxTeams,
      isPublic: isPublic ?? this.isPublic,
      description: description ?? this.description,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isValidLeague() {
    return name.trim().isNotEmpty &&
           commissionerId.trim().isNotEmpty &&
           seasonWeek >= 0 &&
           maxTeams > 0 &&
           maxTeams <= 20; // Reasonable upper limit
  }

  bool canAddTeam(int currentTeamCount) {
    return currentTeamCount < maxTeams;
  }

  bool isCommissioner(String userId) {
    return commissionerId == userId;
  }

  @override
  String toString() {
    return 'League{id: $id, name: $name, mode: $mode, scoringType: $scoringType, '
           'seasonWeek: $seasonWeek, maxTeams: $maxTeams, isPublic: $isPublic}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is League &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          commissionerId == other.commissionerId &&
          mode == other.mode &&
          scoringType == other.scoringType &&
          seasonWeek == other.seasonWeek &&
          maxTeams == other.maxTeams &&
          isPublic == other.isPublic;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      commissionerId.hashCode ^
      mode.hashCode ^
      scoringType.hashCode ^
      seasonWeek.hashCode ^
      maxTeams.hashCode ^
      isPublic.hashCode;
}

// Custom converter for Firestore Timestamps
class TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const TimestampConverter();

  @override
  DateTime fromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    throw ArgumentError('Cannot convert $timestamp to DateTime');
  }

  @override
  dynamic toJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}