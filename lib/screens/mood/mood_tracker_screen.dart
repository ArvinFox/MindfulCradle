import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../models/mood_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/app_background.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _headerAnim.forward();
    });
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  void _load() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId != null) {
      Provider.of<MoodProvider>(context, listen: false).load(userId);
    }
  }

  Future<void> _showCheckIn() async {
    await showMoodCheckInDialog(context);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  int _calcStreak(List<MoodEntry> entries) {
    if (entries.isEmpty) return 0;
    final today = DateUtils.dateOnly(DateTime.now());
    final entryDates = entries
        .map((e) => DateUtils.dateOnly(e.createdAt))
        .toSet();
    DateTime check = entryDates.contains(today)
        ? today
        : today.subtract(const Duration(days: 1));
    int streak = 0;
    while (entryDates.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double _weeklyAvg(List<MoodEntry> entries) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final week = entries.where((e) => e.createdAt.isAfter(weekAgo)).toList();
    if (week.isEmpty) return -1;
    return week.map((e) => e.moodIndex).reduce((a, b) => a + b) / week.length;
  }

  Color _moodColor(int index) {
    const colors = [
      Color(0xFFE53935),
      Color(0xFFFF7043),
      Color(0xFF546E7A),
      Color(0xFF2D9D78),
      Color(0xFF1F6F78),
    ];
    return colors[index.clamp(0, 4)];
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isSinhala =
        Provider.of<LanguageProvider>(context).currentLang == 'si';
    final moodProvider = Provider.of<MoodProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isSinhala ? 'මනෝ තත්ත්ව සටහන' : 'Mood Tracker',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppColors.text,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          if (!moodProvider.hasCheckedInToday)
            IconButton(
              icon: const Icon(Icons.add_rounded, color: AppColors.primary),
              tooltip: isSinhala ? 'නව සටහන' : 'Log Mood',
              onPressed: _showCheckIn,
            ),
        ],
      ),
      body: AppBackground(
        useGradient: true,
        child: moodProvider.loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Today card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: FadeTransition(
                        opacity: _headerAnim,
                        child: SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: const Offset(0, -0.15),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _headerAnim,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: _buildTodayCard(
                            moodProvider.todayMood,
                            isSinhala,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (moodProvider.entries.isNotEmpty) ...[
                    // Stats row
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _buildStatsRow(moodProvider.entries, isSinhala),
                      ),
                    ),
                    // Weekly chart
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: _buildWeeklyChart(
                          moodProvider.entries,
                          isSinhala,
                        ),
                      ),
                    ),
                    // History heading
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          isSinhala ? 'ගත දවස් 30' : 'Last 30 Days',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ),
                    // History list
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        32 + MediaQuery.of(context).padding.bottom,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => _buildHistoryItem(
                            moodProvider.entries[i],
                            isSinhala,
                            i,
                          ),
                          childCount: moodProvider.entries.length,
                        ),
                      ),
                    ),
                  ] else
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(isSinhala),
                    ),
                ],
              ),
      ),
    );
  }

  // ── Today card ────────────────────────────────────────────────────────────

  Widget _buildTodayCard(MoodEntry? todayMood, bool isSinhala) {
    if (todayMood == null) {
      return GestureDetector(
        onTap: _showCheckIn,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.heroGradientStart, AppColors.heroGradientMid],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🌸', style: TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSinhala
                          ? 'අද ඔබ කෙසේ ද?'
                          : 'How are you feeling today?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSinhala
                          ? 'ස්පර්ශ කර සටහන් කරන්න'
                          : 'Tap to log your mood',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isSinhala ? 'ආරම්භ' : 'Log Now',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final color = _moodColor(todayMood.moodIndex);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.14),
            color.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.30), width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                todayMood.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSinhala ? 'අද ඔබ දැනෙනවා' : "Today you're feeling",
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  isSinhala ? todayMood.labelSi() : todayMood.labelEn(),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (todayMood.note != null && todayMood.note!.isNotEmpty)
                  Text(
                    todayMood.note!,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isSinhala ? '✓ සටහන්' : '✓ Logged',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow(List<MoodEntry> entries, bool isSinhala) {
    final streak = _calcStreak(entries);
    final avg = _weeklyAvg(entries);
    final avgEmoji = avg < 0
        ? '—'
        : MoodEntry.emojis[(avg.round()).clamp(0, 4)];

    return Row(
      children: [
        Expanded(
          child: _statCard(
            top: '🔥 $streak',
            bottom: isSinhala ? 'දාමය' : 'Streak',
            color: const Color(0xFFFF7043),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            top: '${entries.length}',
            bottom: isSinhala ? 'සම්පූර්ණ' : 'Total',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            top: avgEmoji,
            bottom: isSinhala ? 'සතිය' : 'This Week',
            color: const Color(0xFF2D9D78),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String top,
    required String bottom,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Text(
            top,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            bottom,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: AppColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Weekly chart ──────────────────────────────────────────────────────────

  Widget _buildWeeklyChart(List<MoodEntry> entries, bool isSinhala) {
    final today = DateUtils.dateOnly(DateTime.now());
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final moodByDate = <DateTime, int>{};
    for (final e in entries) {
      moodByDate.putIfAbsent(
        DateUtils.dateOnly(e.createdAt),
        () => e.moodIndex,
      );
    }
    final labelsEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final labelsSi = ['සඳු', 'අඟ', 'බදා', 'බ්‍ර', 'සිකු', 'සෙන', 'ඉරු'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSinhala ? 'සතිය දළ විශ්ලේෂණය' : 'Weekly Overview',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 108,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final day = days[i];
                final idx = moodByDate[day];
                final isToday = day == today;
                final barH = idx != null ? 16.0 + (idx * 13.0) : 8.0;
                // moodIndex 4 → 16 + 52 = 68px bar
                // emoji ~14px + 3px gap + label ~11px + 5px gap = 33px overhead
                // total max = 68 + 33 = 101px  ✓ fits in 108px
                final color = idx != null ? _moodColor(idx) : AppColors.border;
                final label = (isSinhala
                    ? labelsSi
                    : labelsEn)[day.weekday - 1];

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (idx != null)
                        Text(
                          MoodEntry.emojis[idx],
                          style: const TextStyle(fontSize: 11),
                        ),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 450 + i * 60),
                        curve: Curves.easeOutBack,
                        height: barH,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(
                            alpha: idx != null ? 0.85 : 0.35,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isToday && idx != null
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        label,
                        style: GoogleFonts.roboto(
                          fontSize: 9,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── History item ──────────────────────────────────────────────────────────

  Widget _buildHistoryItem(MoodEntry entry, bool isSinhala, int index) {
    final color = _moodColor(entry.moodIndex);
    final months = isSinhala
        ? [
            'ජන',
            'පෙබ',
            'මාර්',
            'අප්‍ර',
            'මැයි',
            'ජූනි',
            'ජූලි',
            'අගෝ',
            'සැප්',
            'ඔක්',
            'නොව',
            'දෙස',
          ]
        : [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
    final dateStr =
        '${entry.createdAt.day} ${months[entry.createdAt.month - 1]}';
    final timeStr =
        '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';
    final isToday =
        DateUtils.dateOnly(entry.createdAt) ==
        DateUtils.dateOnly(DateTime.now());

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left accent bar
                Container(width: 4, color: color),
                const SizedBox(width: 14),
                // Emoji circle
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      entry.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Label + note
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              isSinhala ? entry.labelSi() : entry.labelEn(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isSinhala ? 'අද' : 'Today',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (entry.note != null && entry.note!.isNotEmpty)
                          Text(
                            entry.note!,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
                // Date + time
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dateStr,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          color: AppColors.textMuted.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.accent.withValues(alpha: 0.12),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🌸', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSinhala ? 'ඔබේ මනෝ ගමන ආරම්භ කරන්න' : 'Start your mood journey',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSinhala
                  ? 'සෑම දිනකම ඔබේ හැඟීම් සටහන් කර ඔබේ ගමන නිරීක්ෂණය කරන්න'
                  : 'Track how you feel each day and discover patterns in your wellbeing',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _showCheckIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.mood_rounded),
              label: Text(
                isSinhala ? 'ආරම්භ කරන්න' : 'Log First Mood',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the mood check-in bottom sheet dialog.
/// Can be called from anywhere (home page button, auto popup, screen).
/// Silently returns if the user has already checked in today.
Future<void> showMoodCheckInDialog(BuildContext context) async {
  final moodProvider = Provider.of<MoodProvider>(context, listen: false);
  if (moodProvider.hasCheckedInToday) {
    final isSinhalaGuard =
        Provider.of<LanguageProvider>(context, listen: false).currentLang ==
        'si';
    AppSnackBar.info(
      context,
      isSinhalaGuard
          ? 'ඔබ අද දිනට ඔබේ මනෝ තත්ත්වය සටහන් කර ඇත! 🌟'
          : 'You\'ve already logged your mood today! 🌟',
    );
    return;
  }

  final isSinhala =
      Provider.of<LanguageProvider>(context, listen: false).currentLang == 'si';
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final userId = authProvider.user?.id ?? '';

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MoodCheckInSheet(
      isSinhala: isSinhala,
      moodProvider: moodProvider,
      userId: userId,
    ),
  );
}

/// Extracted as a proper StatefulWidget so that InheritedWidget (MediaQuery)
/// subscriptions are correctly cleaned up when the sheet is dismissed/dragged away.
class _MoodCheckInSheet extends StatefulWidget {
  final bool isSinhala;
  final MoodProvider moodProvider;
  final String userId;

  const _MoodCheckInSheet({
    required this.isSinhala,
    required this.moodProvider,
    required this.userId,
  });

  @override
  State<_MoodCheckInSheet> createState() => _MoodCheckInSheetState();
}

class _MoodCheckInSheetState extends State<_MoodCheckInSheet> {
  int _selectedIndex = 2;
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSinhala = widget.isSinhala;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20, top: 6),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Text(
              isSinhala ? 'අද ඔබ කෙසේ ද?' : 'How are you feeling today?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 24),

            // Emoji row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (i) {
                final isSelected = _selectedIndex == i;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIndex = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isSelected ? 64 : 52,
                    height: isSelected ? 64 : 52,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _moodColorStatic(i).withValues(alpha: 0.15)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: _moodColorStatic(i), width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        MoodEntry.emojis[i],
                        style: TextStyle(fontSize: isSelected ? 32 : 26),
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),
            Text(
              isSinhala
                  ? MoodEntry.labelsSi[_selectedIndex]
                  : MoodEntry.labelsEn[_selectedIndex],
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _moodColorStatic(_selectedIndex),
              ),
            ),

            const SizedBox(height: 20),

            // Optional note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: isSinhala
                    ? 'සටහනක් (විකල්ප)...'
                    : 'Add a note (optional)...',
                hintStyle: GoogleFonts.roboto(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: GoogleFonts.roboto(fontSize: 14, color: AppColors.text),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _saving
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        setState(() => _saving = true);
                        await widget.moodProvider.addMood(
                          userId: widget.userId,
                          moodIndex: _selectedIndex,
                          note: _noteController.text.trim().isEmpty
                              ? null
                              : _noteController.text.trim(),
                        );
                        if (!mounted) return;
                        final achievementProvider =
                            Provider.of<AchievementProvider>(
                              context,
                              listen: false,
                            );
                        final entryCount = widget.moodProvider.entries.length;
                        if (entryCount >= 1) {
                          await achievementProvider.unlockAchievement(
                            context,
                            'mood_check_in',
                            showUI: false,
                          );
                        }
                        if (entryCount >= 5) {
                          await achievementProvider.unlockAchievement(
                            context,
                            'mood_tracker',
                            showUI: false,
                          );
                        }
                        await achievementProvider.showPendingAchievements(
                          context,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isSinhala ? 'සුරකින්න' : 'Save',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _moodColorStatic(int index) {
  const colors = [
    Color(0xFFE53935),
    Color(0xFFFF7043),
    Color(0xFF546E7A),
    Color(0xFF2D9D78),
    Color(0xFF1F6F78),
  ];
  return colors[index.clamp(0, 4)];
}
