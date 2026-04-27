import 'package:flutter/material.dart';
import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../utils/journal_analysis.dart';

class JournalProvider extends ChangeNotifier {
  final JournalService _service = JournalService();

  List<JournalEntry> _entries = [];
  bool _loading = false;

  List<JournalEntry> get entries => List.unmodifiable(_entries);
  bool get loading => _loading;

  Future<void> load(String userId) async {
    _loading = true;
    notifyListeners();
    _entries = await _service.fetchEntries(userId: userId);
    _loading = false;
    notifyListeners();
  }

  Future<JournalEntry> add({
    required String userId,
    required String title,
    required String content,
    required String language,
  }) async {
    final analysis = JournalAnalysis.analyze(content, language);
    final entry = JournalEntry(
      id: '',
      title: title,
      content: content,
      sentiment: analysis.sentiment,
      sentimentScore: analysis.score,
      semanticTags: analysis.tags,
      createdAt: DateTime.now(),
      language: language,
    );
    final saved = await _service.addEntry(userId: userId, entry: entry);
    _entries.insert(0, saved);
    notifyListeners();
    return saved;
  }

  Future<void> delete({required String userId, required String entryId}) async {
    await _service.deleteEntry(userId: userId, entryId: entryId);
    _entries.removeWhere((e) => e.id == entryId);
    notifyListeners();
  }
}
