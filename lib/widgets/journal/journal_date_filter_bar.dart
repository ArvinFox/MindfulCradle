import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/colors.dart';

/// Which preset date range to apply.
enum JournalFilterPreset { all, today, thisWeek, thisMonth, custom }

/// Horizontal scrollable filter chip bar for journal date filtering.
/// Triggers [onPresetChanged] and (for custom) [onCustomRange].
class JournalDateFilterBar extends StatelessWidget {
  final JournalFilterPreset preset;
  final DateTimeRange? customRange;
  final bool isSinhala;
  final ValueChanged<JournalFilterPreset> onPresetChanged;
  final ValueChanged<DateTimeRange?> onCustomRange;

  const JournalDateFilterBar({
    super.key,
    required this.preset,
    this.customRange,
    required this.isSinhala,
    required this.onPresetChanged,
    required this.onCustomRange,
  });

  @override
  Widget build(BuildContext context) {
    final chips = _chips(context);
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  List<Widget> _chips(BuildContext context) {
    return [
      _chip(
        context,
        label: isSinhala ? 'සියල්ල' : 'All',
        value: JournalFilterPreset.all,
      ),
      _chip(
        context,
        label: isSinhala ? 'අද' : 'Today',
        value: JournalFilterPreset.today,
      ),
      _chip(
        context,
        label: isSinhala ? 'සතිය' : 'This Week',
        value: JournalFilterPreset.thisWeek,
      ),
      _chip(
        context,
        label: isSinhala ? 'මාසය' : 'This Month',
        value: JournalFilterPreset.thisMonth,
      ),
      _chip(
        context,
        label: preset == JournalFilterPreset.custom && customRange != null
            ? '${_fmt(customRange!.start)} – ${_fmt(customRange!.end)}'
            : (isSinhala ? 'කාල පරාසය…' : 'Date Range…'),
        value: JournalFilterPreset.custom,
        isDatePicker: true,
      ),
    ];
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required JournalFilterPreset value,
    bool isDatePicker = false,
  }) {
    final isSelected = preset == value;
    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? Colors.white : AppColors.textMuted,
        ),
      ),
      selected: isSelected,
      onSelected: (bool _) async {
        if (isDatePicker) {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2023),
            lastDate: DateTime.now(),
            initialDateRange: customRange,
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: AppColors.background,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            onCustomRange(picked);
            onPresetChanged(JournalFilterPreset.custom);
          }
        } else {
          onPresetChanged(value);
          onCustomRange(null);
        }
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceVariant,
      shape: const StadiumBorder(),
      side: BorderSide.none,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year % 100}';
}
