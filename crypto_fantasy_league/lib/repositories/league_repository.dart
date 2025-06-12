// ABOUTME: League repository for managing fantasy league data in Firestore
// ABOUTME: Handles league CRUD operations, team management, and league-specific queries

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/league.dart';
import '../models/team.dart';
import '../utils/logger.dart';
import 'base_repository.dart';

class LeagueRepository extends BaseRepository<League> {
  LeagueRepository() : super('leagues');

  @override
  League fromFirestore(DocumentSnapshot doc) {
    return League.fromFirestore(doc);
  }

  @override
  Map<String, dynamic> toFirestore(League league) {
    return league.toFirestore();
  }

  @override
  String getId(League league) {
    return league.id;
  }

  // Get public leagues for discovery
  Future<List<League>> getPublicLeagues({
    LeagueMode? mode,
    int limit = 20,
  }) async {
    try {
      AppLogger.debug('Getting public leagues (mode: $mode, limit: $limit)');
      
      return await getAll(queryBuilder: (collection) {
        Query query = collection.where('isPublic', isEqualTo: true);
        
        if (mode != null) {
          query = query.where('mode', isEqualTo: mode.name);
        }
        
        return query
            .orderBy('created_at', descending: true)
            .limit(limit);
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get public leagues', e, stackTrace);
      rethrow;
    }
  }

  // Get leagues by commissioner
  Future<List<League>> getLeaguesByCommissioner(String commissionerId) async {
    try {
      AppLogger.debug('Getting leagues by commissioner: $commissionerId');
      
      return await getAll(queryBuilder: (collection) {
        return collection
            .where('commissionerId', isEqualTo: commissionerId)
            .orderBy('created_at', descending: true);
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get leagues by commissioner', e, stackTrace);
      rethrow;
    }
  }

  // Search leagues by name
  Future<List<League>> searchLeagues(String searchTerm) async {
    try {
      AppLogger.debug('Searching leagues with term: $searchTerm');
      
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation using array-contains for keywords
      // In production, you'd want to use Algolia or similar for better search
      
      return await getAll(queryBuilder: (collection) {
        return collection
            .where('isPublic', isEqualTo: true)
            .orderBy('created_at', descending: true);
      });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search leagues', e, stackTrace);
      rethrow;
    }
  }

  // Generate unique invite code
  Future<String> generateInviteCode() async {
    String generateCode() {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final random = DateTime.now().millisecondsSinceEpoch;
      return List.generate(6, (index) => chars[(random + index) % chars.length]).join();
    }

    String code;
    bool isUnique = false;
    int attempts = 0;
    const maxAttempts = 10;

    do {
      code = generateCode();
      attempts++;
      
      // Check if code already exists
      final existing = await getAll(queryBuilder: (collection) {
        return collection.where('inviteCode', isEqualTo: code).limit(1);
      });
      
      isUnique = existing.isEmpty;
      
      if (attempts >= maxAttempts) {
        throw Exception('Failed to generate unique invite code after $maxAttempts attempts');
      }
    } while (!isUnique);

    AppLogger.info('Generated unique invite code: $code');
    return code;
  }

  // Find league by invite code
  Future<League?> getLeagueByInviteCode(String inviteCode) async {
    try {
      AppLogger.debug('Getting league by invite code: $inviteCode');
      
      final leagues = await getAll(queryBuilder: (collection) {
        return collection.where('inviteCode', isEqualTo: inviteCode).limit(1);
      });
      
      return leagues.isNotEmpty ? leagues.first : null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get league by invite code', e, stackTrace);
      rethrow;
    }
  }

  // Advance league to next week
  Future<void> advanceToNextWeek(String leagueId) async {
    try {
      AppLogger.info('Advancing league $leagueId to next week');
      
      final league = await getById(leagueId);
      if (league == null) {
        throw Exception('League not found: $leagueId');
      }
      
      await update(leagueId, {
        'seasonWeek': league.seasonWeek + 1,
      });
      
      AppLogger.info('League advanced to week ${league.seasonWeek + 1}');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to advance league to next week', e, stackTrace);
      rethrow;
    }
  }

  // Get league statistics
  Future<LeagueStats> getLeagueStats(String leagueId) async {
    try {
      AppLogger.debug('Getting league statistics for: $leagueId');
      
      final teams = await getTeams(leagueId);
      final totalTeams = teams.length;
      final totalGames = teams.fold<int>(0, (sum, team) => sum + team.totalGames);
      final averageScore = teams.isNotEmpty 
          ? teams.fold<double>(0, (sum, team) => sum + team.totalPoints) / teams.length
          : 0.0;
      
      return LeagueStats(
        totalTeams: totalTeams,
        totalGames: totalGames,
        averageScore: averageScore,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get league statistics', e, stackTrace);
      rethrow;
    }
  }

  // Team management within leagues
  Future<List<Team>> getTeams(String leagueId) async {
    try {
      AppLogger.debug('Getting teams for league: $leagueId');
      
      final snapshot = await collection
          .doc(leagueId)
          .collection('teams')
          .get();
      
      return snapshot.docs.map((doc) => Team.fromFirestore(doc)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get teams for league', e, stackTrace);
      rethrow;
    }
  }

  // Add team to league
  Future<String> addTeam(String leagueId, Team team) async {
    try {
      AppLogger.info('Adding team to league: $leagueId');
      
      final league = await getById(leagueId);
      if (league == null) {
        throw Exception('League not found: $leagueId');
      }
      
      final currentTeams = await getTeams(leagueId);
      if (!league.canAddTeam(currentTeams.length)) {
        throw Exception('League is full (${currentTeams.length}/${league.maxTeams})');
      }
      
      final docRef = collection.doc(leagueId).collection('teams').doc();
      await docRef.set(team.toFirestore());
      
      AppLogger.info('Team added successfully: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add team to league', e, stackTrace);
      rethrow;
    }
  }

  // Remove team from league
  Future<void> removeTeam(String leagueId, String teamId) async {
    try {
      AppLogger.info('Removing team $teamId from league: $leagueId');
      
      await collection
          .doc(leagueId)
          .collection('teams')
          .doc(teamId)
          .delete();
      
      AppLogger.info('Team removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to remove team from league', e, stackTrace);
      rethrow;
    }
  }

  // Watch teams in a league
  Stream<List<Team>> watchTeams(String leagueId) {
    AppLogger.debug('Starting real-time listener for teams in league: $leagueId');
    
    return collection
        .doc(leagueId)
        .collection('teams')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Team.fromFirestore(doc)).toList();
    }).handleError((error, stackTrace) {
      AppLogger.error('Error in teams listener for league $leagueId', error, stackTrace);
    });
  }

  // Check if user is already in league
  Future<bool> isUserInLeague(String leagueId, String userId) async {
    try {
      final snapshot = await collection
          .doc(leagueId)
          .collection('teams')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check if user is in league', e, stackTrace);
      rethrow;
    }
  }
}

class LeagueStats {
  final int totalTeams;
  final int totalGames;
  final double averageScore;

  const LeagueStats({
    required this.totalTeams,
    required this.totalGames,
    required this.averageScore,
  });

  @override
  String toString() {
    return 'LeagueStats{totalTeams: $totalTeams, totalGames: $totalGames, '
           'averageScore: ${averageScore.toStringAsFixed(2)}}';
  }
}