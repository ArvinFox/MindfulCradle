import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../models/journal_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/app_background.dart';
import '../../widgets/journal/journal_date_filter_bar.dart';
import '../../widgets/journal/journal_entry_card.dart';
import 'journal_write_screen.dart';
import 'journal_detail_screen.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  JournalFilterPreset _preset = JournalFilterPreset.all;
  DateTimeRange? _customRange;

  // ── Select mode ─────────────────────────────────────────────────────────
  bool _selectMode = false;
  final Set<String> _selected = {};

  void _enterSelectMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectMode = true;
      _selected.clear();
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
  }

  void _toggleSelect(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _selectAll(List<JournalEntry> entries) {
    setState(() => _selected.addAll(entries.map((e) => e.id)));
  }

  Future<void> _deleteSelected(
    String userId,
    JournalProvider provider,
    bool isSinhala,
  ) async {
    if (_selected.isEmpty) return;
    final count = _selected.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isSinhala
              ? 'ලිපි මකන්නද?'
              : 'Delete $count ${count == 1 ? 'entry' : 'entries'}?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        content: Text(
          isSinhala
              ? 'තෝරාගත් ලිපි $count ස්ථිරව ඉවත් කෙරේ.'
              : 'The selected ${count == 1 ? 'entry' : 'entries'} will be permanently removed.',
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              isSinhala ? 'අවලංගු' : 'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isSinhala ? 'මකන්න' : 'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    HapticFeedback.heavyImpact();
    // Snapshot selected IDs before exiting select mode so the set isn't
    // cleared before deleteMultiple receives it.
    final ids = Set<String>.from(_selected);
    _exitSelectMode(); // clears _selected & _selectMode immediately → UI updates
    provider.deleteMultiple(userId: userId, entryIds: ids);
    if (mounted) {
      AppSnackBar.success(
        context,
        isSinhala
            ? (count == 1 ? 'ලිපිය මකා දමන ලදී' : 'ලිපි $count මකා දමන ලදී')
            : (count == 1 ? 'Entry deleted' : '$count entries deleted'),
      );
    }
  }

  // Google Keep-inspired pastel palette — cycles by entry id hash so the
  // same entry always gets the same colour even after re-filtering.
  static const _palette = [
    Color(0xFFF3E5F5), // soft lavender (brand)
    Color(0xFFE8F5E9), // mint
    Color(0xFFFFF8E1), // warm yellow
    Color(0xFFE3F2FD), // sky blue
    Color(0xFFFCE4EC), // rose pink
    Color(0xFFE0F7FA), // teal
    Color(0xFFF1F8E9), // lime
    Color(0xFFFFF3E0), // peach
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user?.id != null) {
      Provider.of<JournalProvider>(context, listen: false).load(auth.user!.id);
    }
  }

  Color _colorFor(JournalEntry e) =>
      _palette[e.id.hashCode.abs() % _palette.length];

  DateTimeRange? _effectiveRange() {
    final now = DateTime.now();
    switch (_preset) {
      case JournalFilterPreset.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
      case JournalFilterPreset.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(start.year, start.month, start.day),
          end: now,
        );
      case JournalFilterPreset.thisMonth:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case JournalFilterPreset.custom:
        return _customRange;
      case JournalFilterPreset.all:
        return null;
    }
  }

  List<JournalEntry> _filtered(List<JournalEntry> all) {
    final range = _effectiveRange();
    final q = _searchQuery.trim().toLowerCase();
    return all.where((e) {
      if (range != null) {
        final start = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        final end = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
          23,
          59,
          59,
        );
        if (e.createdAt.isBefore(start) || e.createdAt.isAfter(end)) {
          return false;
        }
      }
      if (q.isNotEmpty) {
        return e.title.toLowerCase().contains(q) ||
            e.content.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isSinhala =
        Provider.of<LanguageProvider>(context).currentLang == 'si';
    final provider = Provider.of<JournalProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userId = auth.user?.id ?? '';
    final filtered = _filtered(provider.entries.toList());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _selectMode
          ? AppBar(
              backgroundColor: AppColors.primary,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: _exitSelectMode,
              ),
              title: Text(
                _selected.isEmpty
                    ? (isSinhala ? 'ලිපි තෝරාගත කරන්න' : 'Select entries')
                    : '${_selected.length} ${isSinhala ? 'තෝරාගත් විය' : 'selected'}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (_selected.length == filtered.length) {
                      setState(() => _selected.clear());
                    } else {
                      _selectAll(filtered);
                    }
                  },
                  child: Text(
                    _selected.length == filtered.length
                        ? (isSinhala ? 'උලරදසික කරන්න' : 'Deselect all')
                        : (isSinhala ? 'සෙල්ල තෝරාගත්' : 'Select all'),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              systemOverlayStyle: SystemUiOverlayStyle.light,
            )
          : AppBar(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                isSinhala ? 'මගේ ජර්නලය' : 'My Journal',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.text,
                ),
              ),
              centerTitle: true,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.primary,
                  ),
                  color: AppColors.background,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onSelected: (value) {
                    if (value == 'select') _enterSelectMode();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'select',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.checklist_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isSinhala ? 'තෝරාගත කරන්න' : 'Select',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: _selectMode
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onPressed: () async {
                HapticFeedback.lightImpact();
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JournalWriteScreen()),
                );
              },
              child: const Icon(Icons.edit_rounded, size: 22),
            ),
      body: AppBackground(
        overlayOpacity: 0.78,
        child: Column(
          children: [
            // ── Search bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (q) => setState(() => _searchQuery = q),
                style: GoogleFonts.roboto(fontSize: 14, color: AppColors.text),
                decoration: InputDecoration(
                  hintText: isSinhala ? 'ලිපි සොයන්න...' : 'Search entries...',
                  hintStyle: GoogleFonts.roboto(
                    fontSize: 14,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // ── Date filter chips ────────────────────────────────────────────
            JournalDateFilterBar(
              preset: _preset,
              customRange: _customRange,
              isSinhala: isSinhala,
              onPresetChanged: (p) => setState(() => _preset = p),
              onCustomRange: (r) => setState(() => _customRange = r),
            ),

            const SizedBox(height: 6),

            // ── Content ──────────────────────────────────────────────────────
            Expanded(
              child: provider.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : provider.entries.isEmpty
                  ? _buildEmptyState(isSinhala)
                  : filtered.isEmpty
                  ? _buildNoResults(isSinhala)
                  : SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        2,
                        12,
                        _selectMode ? 120 : 100,
                      ),
                      child: _buildMasonryGrid(
                        filtered,
                        isSinhala,
                        userId,
                        provider,
                      ),
                    ),
            ),

            // ── Delete bar (select mode) ──────────────────────────────────────
            if (_selectMode)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => _deleteSelected(userId, provider, isSinhala),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      disabledBackgroundColor: AppColors.error.withValues(
                        alpha: 0.35,
                      ),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.delete_rounded, size: 20),
                    label: Text(
                      _selected.isEmpty
                          ? (isSinhala
                                ? 'ලිපි තෝරාගත කරන්න'
                                : 'Select entries to delete')
                          : isSinhala
                          ? 'තෝරාගත් ලිපි ${_selected.length}ක මකන්න'
                          : 'Delete ${_selected.length} ${_selected.length == 1 ? 'entry' : 'entries'}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasonryGrid(
    List<JournalEntry> entries,
    bool isSinhala,
    String userId,
    JournalProvider provider,
  ) {
    final left = <JournalEntry>[];
    final right = <JournalEntry>[];
    for (var i = 0; i < entries.length; i++) {
      if (i.isEven) {
        left.add(entries[i]);
      } else {
        right.add(entries[i]);
      }
    }

    JournalEntryCard card(JournalEntry e) => JournalEntryCard(
      key: ValueKey('${e.id}_${_selectMode}_${_selected.contains(e.id)}'),
      entry: e,
      cardColor: _colorFor(e),
      isSinhala: isSinhala,
      selectMode: _selectMode,
      isSelected: _selected.contains(e.id),
      onTap: _selectMode ? () => _toggleSelect(e.id) : () => _openDetail(e),
      onDelete: () => _confirmDelete(context, e, userId, provider, isSinhala),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: left.map(card).toList())),
        const SizedBox(width: 10),
        Expanded(child: Column(children: right.map(card).toList())),
      ],
    );
  }

  void _openDetail(JournalEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JournalDetailScreen(entry: entry)),
    );
  }

  void _confirmDelete(
    BuildContext context,
    JournalEntry entry,
    String userId,
    JournalProvider provider,
    bool isSinhala,
  ) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isSinhala ? 'ලිපිය මකන්නද?' : 'Delete Entry?',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        content: Text(
          isSinhala
              ? 'මෙම ලිපිය ස්ථිරව ඉවත් කෙරේ.'
              : 'This entry will be permanently removed.',
          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              isSinhala ? 'අවලංගු' : 'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.delete(userId: userId, entryId: entry.id);
              AppSnackBar.success(
                context,
                isSinhala ? 'ලිපිය මකා දමන ලදී' : 'Entry deleted',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isSinhala ? 'මකන්න' : 'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty / no-results states ─────────────────────────────────────────────

  Widget _buildEmptyState(bool isSinhala) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSinhala ? 'ඔබේ ජර්නලය ආරම්භ කරන්න' : 'Start Your Journal',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isSinhala
                  ? 'ගැබ් ගැනීමේ ගමනේ ඔබේ හැඟීම් ජර්නලයේ සටහන් කරන්න'
                  : 'Capture your thoughts and feelings throughout your pregnancy journey',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(bool isSinhala) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 52,
            color: AppColors.textMuted.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            isSinhala ? 'ලිපි හමු නොවිය' : 'No entries found',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSinhala
                ? 'වෙනත් දිනයක් හෝ වෙනත් වචනයක් උත්සාහ කරන්න'
                : 'Try a different date or keyword',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: AppColors.textMuted.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
