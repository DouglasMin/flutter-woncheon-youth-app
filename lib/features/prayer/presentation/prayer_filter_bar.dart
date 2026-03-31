import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:woncheon_youth/core/theme/app_theme.dart';
import 'package:woncheon_youth/features/prayer/domain/prayer_filter.dart';
import 'package:woncheon_youth/features/prayer/presentation/prayer_providers.dart';
import 'package:woncheon_youth/shared/widgets/adaptive.dart';

class PrayerFilterBar extends ConsumerWidget {
  const PrayerFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(prayerFilterProvider);

    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final preset in PrayerFilterPreset.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: preset.label,
                selected: filter.preset == preset,
                onTap: () => _onPresetTap(context, ref, preset, filter),
              ),
            ),
          // Show date range if custom is selected
          if (filter.preset == PrayerFilterPreset.custom &&
              filter.customStart != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Center(
                child: Text(
                  _formatRange(filter.customStart!, filter.customEnd),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onPresetTap(
    BuildContext context,
    WidgetRef ref,
    PrayerFilterPreset preset,
    PrayerFilter current,
  ) {
    Haptic.selection();

    if (preset == PrayerFilterPreset.custom) {
      _showDateRangePicker(context, ref, current);
      return;
    }

    ref.read(prayerFilterProvider.notifier).state = PrayerFilter(
      preset: preset,
    );
  }

  Future<void> _showDateRangePicker(
    BuildContext context,
    WidgetRef ref,
    PrayerFilter current,
  ) async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: current.customStart ?? now.subtract(const Duration(days: 7)),
      end: current.customEnd ?? now,
    );

    if (isIOS) {
      await _showCupertinoDatePicker(context, ref, initialRange, now);
    } else {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: now,
        initialDateRange: initialRange,
        locale: const Locale('ko'),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primaryDark,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        ref.read(prayerFilterProvider.notifier).state = PrayerFilter(
          preset: PrayerFilterPreset.custom,
          customStart: picked.start,
          customEnd: picked.end,
        );
      }
    }
  }

  Future<void> _showCupertinoDatePicker(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange initial,
    DateTime now,
  ) async {
    var start = initial.start;
    var end = initial.end;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        var pickedStart = start;
        var pickedEnd = end;
        return StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            height: 420,
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('취소'),
                        ),
                        const Text(
                          '기간 선택',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        CupertinoButton(
                          onPressed: () {
                            ref.read(prayerFilterProvider.notifier).state =
                                PrayerFilter(
                              preset: PrayerFilterPreset.custom,
                              customStart: pickedStart,
                              customEnd: pickedEnd,
                            );
                            Navigator.of(ctx).pop();
                          },
                          child: const Text(
                            '확인',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Tab: Start date
                  Expanded(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          '시작일',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        Expanded(
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime: pickedStart,
                            maximumDate: now,
                            onDateTimeChanged: (d) => pickedStart = d,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Tab: End date
                  Expanded(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          '종료일',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        Expanded(
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime: pickedEnd,
                            maximumDate: now,
                            onDateTimeChanged: (d) => pickedEnd = d,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatRange(DateTime start, DateTime? end) {
    final fmt = DateFormat('M/d');
    if (end != null) {
      return '${fmt.format(start)} - ${fmt.format(end)}';
    }
    return '${fmt.format(start)} ~';
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
