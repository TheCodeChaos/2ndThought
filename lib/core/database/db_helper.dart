import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'migrations/v1_schema.dart';

// Data models
class BlockedApp {
  final int? id;
  final String packageName;
  final String appName;
  final String? iconB64;
  final bool isActive;
  final int addedAt;

  const BlockedApp({
    this.id,
    required this.packageName,
    required this.appName,
    this.iconB64,
    this.isActive = true,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() => {
        'package_name': packageName,
        'app_name': appName,
        'icon_b64': iconB64,
        'is_active': isActive ? 1 : 0,
        'added_at': addedAt,
      };

  factory BlockedApp.fromMap(Map<String, dynamic> map) => BlockedApp(
        id: map['id'] as int?,
        packageName: map['package_name'] as String,
        appName: map['app_name'] as String,
        iconB64: map['icon_b64'] as String?,
        isActive: (map['is_active'] as int) == 1,
        addedAt: map['added_at'] as int,
      );
}

class ActiveSession {
  final int? id;
  final String packageName;
  final int grantedAt;
  final int expiresAt;
  final String gameType;

  const ActiveSession({
    this.id,
    required this.packageName,
    required this.grantedAt,
    required this.expiresAt,
    required this.gameType,
  });

  Map<String, dynamic> toMap() => {
        'package_name': packageName,
        'granted_at': grantedAt,
        'expires_at': expiresAt,
        'game_type': gameType,
      };

  factory ActiveSession.fromMap(Map<String, dynamic> map) => ActiveSession(
        id: map['id'] as int?,
        packageName: map['package_name'] as String,
        grantedAt: map['granted_at'] as int,
        expiresAt: map['expires_at'] as int,
        gameType: map['game_type'] as String,
      );
}

class ChallengeHistoryEntry {
  final int? id;
  final String packageName;
  final String appName;
  final String gameType;
  final String outcome;
  final int durationMs;
  final int focusPoints;
  final int playedAt;

  const ChallengeHistoryEntry({
    this.id,
    required this.packageName,
    required this.appName,
    required this.gameType,
    required this.outcome,
    required this.durationMs,
    required this.focusPoints,
    required this.playedAt,
  });

  Map<String, dynamic> toMap() => {
        'package_name': packageName,
        'app_name': appName,
        'game_type': gameType,
        'outcome': outcome,
        'duration_ms': durationMs,
        'focus_points': focusPoints,
        'played_at': playedAt,
      };

  factory ChallengeHistoryEntry.fromMap(Map<String, dynamic> map) =>
      ChallengeHistoryEntry(
        id: map['id'] as int?,
        packageName: map['package_name'] as String,
        appName: map['app_name'] as String,
        gameType: map['game_type'] as String,
        outcome: map['outcome'] as String,
        durationMs: map['duration_ms'] as int,
        focusPoints: map['focus_points'] as int,
        playedAt: map['played_at'] as int,
      );
}

class DbHelper {
  static DbHelper? _instance;
  static Database? _database;

  DbHelper._();

  static DbHelper get instance {
    _instance ??= DbHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'neurogate.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Execute each statement separately
        final statements = v1Schema
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty);

        for (final statement in statements) {
          await db.execute('$statement;');
        }

        // Insert default settings
        for (final setting in defaultSettings) {
          await db.insert('settings', {
            'key': setting['key'],
            'value': setting['value'],
          });
        }
      },
    );
  }

  // --- Blocked Apps ---

  Future<void> insertBlockedApp(BlockedApp app) async {
    try {
      final db = await database;
      await db.insert('blocked_apps', app.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Error inserting blocked app: $e');
    }
  }

  Future<List<BlockedApp>> getBlockedApps() async {
    try {
      final db = await database;
      final maps = await db.query('blocked_apps', orderBy: 'added_at DESC');
      return maps.map((m) => BlockedApp.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error getting blocked apps: $e');
      return [];
    }
  }

  Future<void> removeBlockedApp(String packageName) async {
    try {
      final db = await database;
      await db.delete('blocked_apps',
          where: 'package_name = ?', whereArgs: [packageName]);
    } catch (e) {
      debugPrint('Error removing blocked app: $e');
    }
  }

  Future<void> toggleAppActive(String packageName, bool active) async {
    try {
      final db = await database;
      await db.update(
        'blocked_apps',
        {'is_active': active ? 1 : 0},
        where: 'package_name = ?',
        whereArgs: [packageName],
      );
    } catch (e) {
      debugPrint('Error toggling app active: $e');
    }
  }

  // --- Sessions ---

  Future<void> insertSession(ActiveSession session) async {
    try {
      final db = await database;
      await db.insert('active_sessions', session.toMap());
    } catch (e) {
      debugPrint('Error inserting session: $e');
    }
  }

  Future<ActiveSession?> getActiveSession(String packageName) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final maps = await db.query(
        'active_sessions',
        where: 'package_name = ? AND expires_at > ?',
        whereArgs: [packageName, now],
        orderBy: 'expires_at DESC',
        limit: 1,
      );
      if (maps.isNotEmpty) {
        return ActiveSession.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting active session: $e');
      return null;
    }
  }

  Future<void> deleteExpiredSessions() async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.delete('active_sessions',
          where: 'expires_at <= ?', whereArgs: [now]);
    } catch (e) {
      debugPrint('Error deleting expired sessions: $e');
    }
  }

  // --- Challenge History ---

  Future<void> insertChallengeHistory(ChallengeHistoryEntry entry) async {
    try {
      final db = await database;
      await db.insert('challenge_history', entry.toMap());
    } catch (e) {
      debugPrint('Error inserting challenge history: $e');
    }
  }

  Future<List<ChallengeHistoryEntry>> getChallengeHistory(
      {int limit = 50, int offset = 0, String? gameTypeFilter}) async {
    try {
      final db = await database;
      String? where;
      List<dynamic>? whereArgs;
      if (gameTypeFilter != null) {
        where = 'game_type = ?';
        whereArgs = [gameTypeFilter];
      }
      final maps = await db.query(
        'challenge_history',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'played_at DESC',
        limit: limit,
        offset: offset,
      );
      return maps.map((m) => ChallengeHistoryEntry.fromMap(m)).toList();
    } catch (e) {
      debugPrint('Error getting challenge history: $e');
      return [];
    }
  }

  Future<int> getTotalFocusPoints() async {
    try {
      final db = await database;
      final result =
          await db.rawQuery('SELECT SUM(focus_points) as total FROM challenge_history');
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      debugPrint('Error getting total focus points: $e');
      return 0;
    }
  }

  Future<int> getTotalWins() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
          "SELECT COUNT(*) as total FROM challenge_history WHERE outcome = 'success'");
      return (result.first['total'] as int?) ?? 0;
    } catch (e) {
      debugPrint('Error getting total wins: $e');
      return 0;
    }
  }

  Future<int> getCurrentStreak() async {
    try {
      final db = await database;
      final results = await db.rawQuery(
        "SELECT DISTINCT date(played_at / 1000, 'unixepoch', 'localtime') as day "
        "FROM challenge_history WHERE outcome = 'success' "
        "ORDER BY day DESC",
      );

      if (results.isEmpty) return 0;

      int streak = 0;
      DateTime? prevDay;

      for (final row in results) {
        final dayStr = row['day'] as String;
        final day = DateTime.parse(dayStr);

        if (prevDay == null) {
          final today = DateTime.now();
          final todayOnly = DateTime(today.year, today.month, today.day);
          final diff = todayOnly.difference(day).inDays;
          if (diff > 1) return 0;
          streak = 1;
          prevDay = day;
        } else {
          final diff = prevDay.difference(day).inDays;
          if (diff == 1) {
            streak++;
            prevDay = day;
          } else {
            break;
          }
        }
      }

      return streak;
    } catch (e) {
      debugPrint('Error getting current streak: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getWeeklyFocusPoints() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final weekAgoMs = weekAgo.millisecondsSinceEpoch;

      final results = await db.rawQuery(
        "SELECT date(played_at / 1000, 'unixepoch', 'localtime') as day, "
        "SUM(focus_points) as points "
        "FROM challenge_history "
        "WHERE played_at >= ? "
        "GROUP BY day "
        "ORDER BY day ASC",
        [weekAgoMs],
      );

      final map = <String, int>{};
      for (final row in results) {
        map[row['day'] as String] = (row['points'] as int?) ?? 0;
      }
      return map;
    } catch (e) {
      debugPrint('Error getting weekly focus points: $e');
      return {};
    }
  }

  // --- Settings ---

  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      final maps =
          await db.query('settings', where: 'key = ?', whereArgs: [key]);
      if (maps.isNotEmpty) {
        return maps.first['value'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting setting: $e');
      return null;
    }
  }

  Future<void> setSetting(String key, String value) async {
    try {
      final db = await database;
      await db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error setting setting: $e');
    }
  }

  Future<void> resetAllData() async {
    try {
      final db = await database;
      await db.delete('blocked_apps');
      await db.delete('active_sessions');
      await db.delete('challenge_history');
      await db.delete('settings');

      for (final setting in defaultSettings) {
        await db.insert('settings', {
          'key': setting['key'],
          'value': setting['value'],
        });
      }
    } catch (e) {
      debugPrint('Error resetting all data: $e');
    }
  }
}
