import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/export/export_request.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/application/providers/export_controller.dart';
import 'package:mali_app/application/providers/export_preview_providers.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/category.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';
import 'package:mali_app/domain/value_objects/export_filters.dart';
import 'package:mali_app/domain/value_objects/export_format.dart';
import 'package:mali_app/presentation/theme/app_colors.dart';
import 'package:mali_app/presentation/theme/app_typography.dart';
import 'package:mali_app/presentation/utils/export_date_range.dart';

enum ExportPeriodPreset {
  thisMonth,
  lastMonth,
  lastThreeMonths,
  custom,
}

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({
    this.clock = DateTime.now,
    super.key,
  });

  static const String location = '/settings/export';
  static const Key screenKey = Key('export-screen');
  static const Key dateRangeKey = Key('export-date-range');
  static const Key formatKey = Key('export-format');
  static const Key walletFilterKey = Key('export-wallet-filter');
  static const Key categoryFilterKey = Key('export-category-filter');
  static const Key submitKey = Key('export-submit');
  static const Key periodGroupKey = Key('export-period-group');
  static const Key previewKey = Key('export-document-preview');

  /// Injectable so widget tests can pin "today" without depending on the
  /// calendar.
  final DateTime Function() clock;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  late DateRange _range;
  ExportPeriodPreset _period = ExportPeriodPreset.thisMonth;
  ExportFormat _format = ExportFormat.pdf;
  String? _walletId;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    _range = ExportDateRange.currentMonth(widget.clock());
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportControllerProvider);
    final isExporting = exportState.isLoading;
    final wallets = ref.watch(activeWalletsProvider).value ?? const <Wallet>[];
    final countAsync = ref.watch(
      exportTransactionCountProvider(
        ExportCountQuery(
          range: _range,
          walletId: _walletId,
          categoryId: _categoryId,
        ),
      ),
    );

    ref.listen(exportControllerProvider, (previous, next) {
      next.when(
        data: (file) {
          if (file != null && (previous?.isLoading ?? false)) {
            _showMessage('Saved ${file.fileName}');
          }
        },
        error: (error, _) => _showMessage(exportErrorMessage(error)),
        loading: () {},
      );
    });

    return Scaffold(
      key: ExportScreen.screenKey,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                children: [
                  _DocumentPreview(format: _format),
                  const SizedBox(height: 28),
                  Text(
                    'PERIOD',
                    style: AppTypography.sectionLabel(context).copyWith(
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _PeriodGrid(
                    selected: _period,
                    enabled: !isExporting,
                    onSelected: _onPeriodSelected,
                  ),
                  if (_period == ExportPeriodPreset.custom) ...[
                    const SizedBox(height: 10),
                    Text(
                      ExportDateRange.label(_range),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    'FORMAT',
                    style: AppTypography.sectionLabel(context).copyWith(
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FormatSelector(
                    format: _format,
                    enabled: !isExporting,
                    onChanged: (format) => setState(() => _format = format),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _format == ExportFormat.pdf
                        ? 'A tidy summary with totals by category and wallet — '
                            'good for sharing.'
                        : 'A spreadsheet of every transaction — good for Excel '
                            'or Sheets.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'FILTERS',
                    style: AppTypography.sectionLabel(context).copyWith(
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _WalletFilterTile(
                    walletId: _walletId,
                    enabled: !isExporting,
                    onTap: () => _pickWallet(context, wallets),
                  ),
                  _CategoryFilterTile(
                    categoryId: _categoryId,
                    enabled: !isExporting,
                    onTap: () => _pickCategory(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  key: ExportScreen.submitKey,
                  onPressed: isExporting ? null : _export,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.silver,
                    disabledBackgroundColor: AppColors.navy.withValues(
                      alpha: 0.55,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: isExporting
                      ? const Text('Exporting…')
                      : Text(_exportLabel(countAsync)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _exportLabel(AsyncValue<int> countAsync) {
    return countAsync.maybeWhen(
      data: (count) => 'Export $count transactions',
      orElse: () => 'Export transactions',
    );
  }

  void _onPeriodSelected(ExportPeriodPreset period) {
    final now = widget.clock();
    if (period == ExportPeriodPreset.custom) {
      _pickDateRange(context);
      return;
    }

    setState(() {
      _period = period;
      _range = switch (period) {
        ExportPeriodPreset.thisMonth => ExportDateRange.currentMonth(now),
        ExportPeriodPreset.lastMonth => ExportDateRange.lastMonth(now),
        ExportPeriodPreset.lastThreeMonths =>
          ExportDateRange.lastThreeMonths(now),
        ExportPeriodPreset.custom => _range,
      };
    });
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = widget.clock();
    final current = ExportDateRange.toPicker(_range);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: ExportDateRange.firstPickerDate(now),
      lastDate: ExportDateRange.lastPickerDate(now),
      initialDateRange: current,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _period = ExportPeriodPreset.custom;
      _range = ExportDateRange.fromPicker(picked);
    });
  }

  Future<void> _pickWallet(BuildContext context, List<Wallet> wallets) async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      useSafeArea: true,
      builder: (context) => _WalletFilterSheet(
        wallets: wallets,
        selectedWalletId: _walletId,
      ),
    );
    if (!mounted || !_sheetReturned(selected)) {
      return;
    }
    setState(() => _walletId = _normalizeFilter(selected));
  }

  Future<void> _pickCategory(BuildContext context) async {
    final categories = ref.read(allCategoriesProvider);
    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CategoryFilterSheet(
        categories: categories,
        selectedCategoryId: _categoryId,
      ),
    );
    if (!mounted || !_sheetReturned(selected)) {
      return;
    }
    setState(() => _categoryId = _normalizeFilter(selected));
  }

  /// [showModalBottomSheet] returns null both when dismissed and when the
  /// user picks "All". The sheets therefore pop a sentinel empty string for
  /// "All", which this maps back to a null filter.
  bool _sheetReturned(String? selected) => selected != null;

  String? _normalizeFilter(String? selected) {
    if (selected == _allFilterValue) {
      return null;
    }
    return selected;
  }

  Future<void> _export() {
    return ref.read(exportControllerProvider.notifier).submit(
          ExportRequest(
            range: _range,
            format: _format,
            filters: ExportFilters(
              walletId: _walletId,
              categoryId: _categoryId,
            ),
          ),
        );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

const String _allFilterValue = '';

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Material(
            color: AppColors.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE1E5EE), width: 0.8),
            ),
            child: InkWell(
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.chevron_left,
                  size: 20,
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Export',
              style: AppTypography.money(
                fontSize: 26,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.format});

  final ExportFormat format;

  @override
  Widget build(BuildContext context) {
    final isPdf = format == ExportFormat.pdf;
    return Center(
      child: Container(
        key: ExportScreen.previewKey,
        width: 140,
        height: 182,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(8, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isPdf
                    ? AppColors.errorContainer
                    : AppColors.successContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPdf ? 'PDF' : 'CSV',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isPdf ? AppColors.error : AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 78,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFC8CFDD),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 10),
            for (final width in [1.0, 1.0, 0.8, 1.0, 0.6]) ...[
              FractionallySizedBox(
                widthFactor: width,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE1EC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeriodGrid extends StatelessWidget {
  const _PeriodGrid({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final ExportPeriodPreset selected;
  final bool enabled;
  final ValueChanged<ExportPeriodPreset> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      (ExportPeriodPreset.thisMonth, 'This month'),
      (ExportPeriodPreset.lastMonth, 'Last month'),
      (ExportPeriodPreset.lastThreeMonths, 'Last 3 months'),
      (ExportPeriodPreset.custom, 'Custom range'),
    ];

    return Column(
      key: ExportScreen.periodGroupKey,
      children: [
        Row(
          children: [
            Expanded(
              child: _PeriodChip(
                label: items[0].$2,
                selected: selected == items[0].$1,
                enabled: enabled,
                onTap: () => onSelected(items[0].$1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PeriodChip(
                label: items[1].$2,
                selected: selected == items[1].$1,
                enabled: enabled,
                onTap: () => onSelected(items[1].$1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _PeriodChip(
                label: items[2].$2,
                selected: selected == items[2].$1,
                enabled: enabled,
                onTap: () => onSelected(items[2].$1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PeriodChip(
                key: ExportScreen.dateRangeKey,
                label: items[3].$2,
                selected: selected == items[3].$1,
                enabled: enabled,
                onTap: () => onSelected(items[3].$1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy : AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.navy : const Color(0xFFE1E5EE),
          width: 0.8,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 46,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.silver : AppColors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatSelector extends StatelessWidget {
  const _FormatSelector({
    required this.format,
    required this.enabled,
    required this.onChanged,
  });

  final ExportFormat format;
  final bool enabled;
  final ValueChanged<ExportFormat> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ExportScreen.formatKey,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FormatChip(
              label: 'PDF report',
              selected: format == ExportFormat.pdf,
              enabled: enabled,
              onTap: () => onChanged(ExportFormat.pdf),
            ),
          ),
          Expanded(
            child: _FormatChip(
              label: 'CSV spreadsheet',
              selected: format == ExportFormat.csv,
              enabled: enabled,
              onTap: () => onChanged(ExportFormat.csv),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  const _FormatChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceContainerLowest : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      elevation: selected ? 1.5 : 0,
      shadowColor: AppColors.navy.withValues(alpha: 0.18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(11),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.navy : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletFilterTile extends ConsumerWidget {
  const _WalletFilterTile({
    required this.walletId,
    required this.enabled,
    required this.onTap,
  });

  final String? walletId;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = walletId == null
        ? 'All wallets'
        : ref.watch(walletByIdProvider(walletId!)).when(
              data: (wallet) => wallet?.name ?? 'All wallets',
              loading: () => 'Loading…',
              error: (_, _) => 'All wallets',
            );

    return ListTile(
      key: ExportScreen.walletFilterKey,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.account_balance_wallet_outlined),
      title: const Text('Wallet'),
      subtitle: Text(label),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }
}

class _CategoryFilterTile extends ConsumerWidget {
  const _CategoryFilterTile({
    required this.categoryId,
    required this.enabled,
    required this.onTap,
  });

  final String? categoryId;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = categoryId == null
        ? null
        : ref.watch(categoryByIdProvider(categoryId!));

    return ListTile(
      key: ExportScreen.categoryFilterKey,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.category_outlined),
      title: const Text('Category'),
      subtitle: Text(category?.name ?? 'All categories'),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }
}

class _WalletFilterSheet extends StatelessWidget {
  const _WalletFilterSheet({
    required this.wallets,
    required this.selectedWalletId,
  });

  final List<Wallet> wallets;
  final String? selectedWalletId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Filter by wallet', style: theme.textTheme.titleMedium),
          ),
          ListTile(
            title: const Text('All wallets'),
            trailing: selectedWalletId == null
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            onTap: () => Navigator.of(context).pop(_allFilterValue),
          ),
          ...wallets.map(
            (wallet) => ListTile(
              title: Text(wallet.name),
              subtitle: Text(wallet.currencyCode),
              trailing: selectedWalletId == wallet.id
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(wallet.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilterSheet extends StatelessWidget {
  const _CategoryFilterSheet({
    required this.categories,
    required this.selectedCategoryId,
  });

  final List<Category> categories;
  final String? selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Filter by category',
              style: theme.textTheme.titleMedium,
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: const Text('All categories'),
                  trailing: selectedCategoryId == null
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () => Navigator.of(context).pop(_allFilterValue),
                ),
                for (final category in categories)
                  ListTile(
                    title: Text(category.name),
                    trailing: selectedCategoryId == category.id
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(category.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
