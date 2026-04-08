import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';

final challengeHistoryProvider =
    FutureProvider.family<List<ChallengeHistoryEntry>, String?>(
        (ref, gameTypeFilter) async {
  return DbHelper.instance.getChallengeHistory(
    gameTypeFilter: gameTypeFilter,
  );
});

final totalFocusPointsProvider = FutureProvider<int>((ref) async {
  return DbHelper.instance.getTotalFocusPoints();
});

final totalWinsProvider = FutureProvider<int>((ref) async {
  return DbHelper.instance.getTotalWins();
});

final streakProvider = FutureProvider<int>((ref) async {
  return DbHelper.instance.getCurrentStreak();
});

final weeklyFocusPointsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  return DbHelper.instance.getWeeklyFocusPoints();
});
