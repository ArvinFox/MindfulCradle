import 'package:flutter/material.dart';
import '../models/mood_entry.dart';
import '../services/mood_service.dart';

class MoodProvider extends ChangeNotifier {
  final MoodService _service = MoodService();

  List<MoodEntry> _entries = [];
  MoodEntry? _todayMood;
  bool _loading = false;
  bool _checkedToday = false;

  List<MoodEntry> get entries => List.unmodifiable(_entries);
  MoodEntry? get todayMood => _todayMood;
  bool get loading => _loading;
  bool get hasCheckedInToday => _todayMood != null;
  bool get checkedToday => _checkedToday;

  Future<void> load(String userId) async {
    _loading = true;
    notifyListeners();
    _entries = await _service.fetchEntries(userId: userId);
    _todayMood = await _service.fetchTodayMood(userId: userId);
    _checkedToday = _todayMood != null;
    _loading = false;
    notifyListeners();
  }

  Future<MoodEntry> addMood({
    required String userId,
    required int moodIndex,
    String? note,
  }) async {
    final entry = MoodEntry(
      id: '',
      moodIndex: moodIndex,
      note: note,
      createdAt: DateTime.now(),
    );
    final saved = await _service.addEntry(userId: userId, entry: entry);
    _todayMood = saved;
    _checkedToday = true;
    _entries.insert(0, saved);
    notifyListeners();
    return saved;
  }
}
