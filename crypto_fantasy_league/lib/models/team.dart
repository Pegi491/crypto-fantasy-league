// ABOUTME: Team data model representing a user's team in a fantasy league
// ABOUTME: Manages team roster, statistics, and weekly performance data

import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'league.dart'; // For TimestampConverter

part 'team.g.dart';

@JsonSerializable()
class Team {
  final String id;
  final String leagueId;
  final String userId;
  final String name;
  final String? avatar;
  final List<String> draft;
  final List<String> bench;
  final int wins;
  final int losses;
  final int streak; // Positive for win streak, negative for loss streak
  final double totalPoints;
  
  @JsonKey(name: 'created_at')
  @TimestampConverter()
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  @TimestampConverter()
  final DateTime updatedAt;

  const Team({
    required this.id,
    required this.leagueId,
    required this.userId,
    required this.name,
    required this.draft,
    required this.bench,
    required this.wins,
    required this.losses,
    required this.streak,
    required this.totalPoints,
    required this.createdAt,
    required this.updatedAt,
    this.avatar,
  });

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);

  Map<String, dynamic> toJson() => _$TeamToJson(this);

  factory Team.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Team.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Don't store ID in document data
    return json;
  }

  Team copyWith({
    String? id,
    String? leagueId,
    String? userId,
    String? name,
    String? avatar,
    List<String>? draft,
    List<String>? bench,
    int? wins,
    int? losses,
    int? streak,
    double? totalPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id ?? this.id,
      leagueId: leagueId ?? this.leagueId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      draft: draft ?? List.from(this.draft),
      bench: bench ?? List.from(this.bench),
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      streak: streak ?? this.streak,
      totalPoints: totalPoints ?? this.totalPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isValidTeam() {
    return name.trim().isNotEmpty &&
           userId.trim().isNotEmpty &&
           leagueId.trim().isNotEmpty &&
           draft.length <= 7 && // Maximum roster size
           bench.length <= 3 && // Maximum bench size
           wins >= 0 &&
           losses >= 0;
  }

  bool canAddToDraft() {
    return draft.length < 7;
  }

  bool canAddToBench() {
    return bench.length < 3;
  }

  bool hasAsset(String assetId) {
    return draft.contains(assetId) || bench.contains(assetId);
  }

  double get winPercentage {
    final totalGames = wins + losses;
    return totalGames > 0 ? wins / totalGames : 0.0;
  }

  int get totalGames => wins + losses;

  bool get isOnWinStreak => streak > 0;

  bool get isOnLossStreak => streak < 0;

  int get streakLength => streak.abs();

  Team addWin() {
    return copyWith(
      wins: wins + 1,
      streak: streak >= 0 ? streak + 1 : 1,
      updatedAt: DateTime.now(),
    );
  }

  Team addLoss() {
    return copyWith(
      losses: losses + 1,
      streak: streak <= 0 ? streak - 1 : -1,
      updatedAt: DateTime.now(),
    );
  }

  Team updatePoints(double points) {
    return copyWith(
      totalPoints: totalPoints + points,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Team{id: $id, name: $name, wins: $wins, losses: $losses, '
           'streak: $streak, totalPoints: $totalPoints, draft: ${draft.length}, '
           'bench: ${bench.length}}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          leagueId == other.leagueId &&
          userId == other.userId &&
          name == other.name;

  @override
  int get hashCode =>
      id.hashCode ^
      leagueId.hashCode ^
      userId.hashCode ^
      name.hashCode;
}

@JsonSerializable()
class TeamWeeklyData {
  final String teamId;
  final int week;
  final String? captainAssetId;
  final ShieldStatus shield;
  final int faMovesRemaining;
  
  @JsonKey(name: 'created_at')
  @TimestampConverter()
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  @TimestampConverter()
  final DateTime updatedAt;

  const TeamWeeklyData({
    required this.teamId,
    required this.week,
    required this.shield,
    required this.faMovesRemaining,
    required this.createdAt,
    required this.updatedAt,
    this.captainAssetId,
  });

  factory TeamWeeklyData.fromJson(Map<String, dynamic> json) => 
      _$TeamWeeklyDataFromJson(json);

  Map<String, dynamic> toJson() => _$TeamWeeklyDataToJson(this);

  factory TeamWeeklyData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamWeeklyData.fromJson(data);
  }

  Map<String, dynamic> toFirestore() => toJson();

  TeamWeeklyData copyWith({
    String? teamId,
    int? week,
    String? captainAssetId,
    ShieldStatus? shield,
    int? faMovesRemaining,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamWeeklyData(
      teamId: teamId ?? this.teamId,
      week: week ?? this.week,
      captainAssetId: captainAssetId ?? this.captainAssetId,
      shield: shield ?? this.shield,
      faMovesRemaining: faMovesRemaining ?? this.faMovesRemaining,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool canUseFreeAgent() {
    return faMovesRemaining > 0;
  }

  bool canActivateShield() {
    return shield.status == ShieldStatusType.available;
  }

  TeamWeeklyData useFreeAgent() {
    return copyWith(
      faMovesRemaining: faMovesRemaining - 1,
      updatedAt: DateTime.now(),
    );
  }

  TeamWeeklyData activateShield(String assetId) {
    return copyWith(
      shield: shield.activate(assetId),
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'TeamWeeklyData{teamId: $teamId, week: $week, '
           'captainAssetId: $captainAssetId, shield: $shield, '
           'faMovesRemaining: $faMovesRemaining}';
  }
}

enum ShieldStatusType { available, activated, consumed }

@JsonSerializable()
class ShieldStatus {
  final ShieldStatusType status;
  final String? assetId;
  final String? day;

  const ShieldStatus({
    required this.status,
    this.assetId,
    this.day,
  });

  factory ShieldStatus.available() {
    return const ShieldStatus(status: ShieldStatusType.available);
  }

  factory ShieldStatus.fromJson(Map<String, dynamic> json) => 
      _$ShieldStatusFromJson(json);

  Map<String, dynamic> toJson() => _$ShieldStatusToJson(this);

  ShieldStatus activate(String assetId) {
    return ShieldStatus(
      status: ShieldStatusType.activated,
      assetId: assetId,
    );
  }

  ShieldStatus consume(String day) {
    return ShieldStatus(
      status: ShieldStatusType.consumed,
      assetId: assetId,
      day: day,
    );
  }

  @override
  String toString() {
    return 'ShieldStatus{status: $status, assetId: $assetId, day: $day}';
  }
}

@JsonSerializable()
class FreeAgentMove {
  final String id;
  final String teamId;
  final String addAssetId;
  final String dropAssetId;
  
  @JsonKey(name: 'timestamp')
  @TimestampConverter()
  final DateTime timestamp;

  const FreeAgentMove({
    required this.id,
    required this.teamId,
    required this.addAssetId,
    required this.dropAssetId,
    required this.timestamp,
  });

  factory FreeAgentMove.fromJson(Map<String, dynamic> json) => 
      _$FreeAgentMoveFromJson(json);

  Map<String, dynamic> toJson() => _$FreeAgentMoveToJson(this);

  factory FreeAgentMove.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FreeAgentMove.fromJson({
      'id': doc.id,
      ...data,
    });
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Don't store ID in document data
    return json;
  }

  @override
  String toString() {
    return 'FreeAgentMove{id: $id, teamId: $teamId, '
           'addAssetId: $addAssetId, dropAssetId: $dropAssetId, '
           'timestamp: $timestamp}';
  }
}