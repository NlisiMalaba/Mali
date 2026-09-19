import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mali_app/application/export/export_request.dart';
import 'package:mali_app/application/providers/category_providers.dart';
import 'package:mali_app/application/providers/export_controller.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/category.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';
import 'package:mali_app/domain/value_objects/export_filters.dart';
import 'package:mali_app/domain/value_objects/export_format.dart';
import 'package:mali_app/presentation/utils/export_date_range.dart';

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

  /// Injectable so widget tests can pin "today" without depending on the
  /// calendar.
  final DateTime Function() clock;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  late DateRange _range;
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
      appBar: AppBar(title: const Text('Export data')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _DateRangeTile(
            range: _range,
            enabled: !isExporting,
            onTap: () => _pickDateRange(context),
          ),
          const SizedBox(height: 20),
          _FormatSelector(
            format: _format,
            enabled: !isExporting,
            onChanged: (format) => setState(() => _format = format),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 24),
          FilledButton.icon(
            key: ExportScreen.submitKey,
            onPressed: isExporting ? null : _export,
            icon: isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_download_outlined),
            label: Text(isExporting ? 'Exporting…' : 'Export'),
          ),
        ],
      ),
    );
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
    setState(() => _range = ExportDateRange.fromPicker(picked));
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

class _DateRangeTile extends StatelessWidget {
  const _DateRangeTile({
    required this.range,
    required this.enabled,
    required this.onTap,
  });

  final DateRange range;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ExportScreen.dateRangeKey,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.date_range_outlined),
      title: const Text('Date range'),
      subtitle: Text(ExportDateRange.label(range)),
      enabled: enabled,
      onTap: enabled ? onTap : null,
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Format', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<ExportFormat>(
          key: ExportScreen.formatKey,
          segments: const [
            ButtonSegment(
              value: ExportFormat.pdf,
              label: Text('PDF'),
              icon: Icon(Icons.picture_as_pdf_outlined),
            ),
            ButtonSegment(
              value: ExportFormat.csv,
              label: Text('CSV'),
              icon: Icon(Icons.table_chart_outlined),
            ),
          ],
          selected: {format},
          onSelectionChanged: enabled
              ? (selected) => onChanged(selected.single)
              : null,
        ),
      ],
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
