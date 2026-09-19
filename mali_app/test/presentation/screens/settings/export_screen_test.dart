import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mali_app/application/export/export_request.dart';
import 'package:mali_app/application/providers/auth_provider.dart';
import 'package:mali_app/application/providers/export_controller.dart';
import 'package:mali_app/application/providers/wallet_providers.dart';
import 'package:mali_app/domain/entities/user.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/value_objects/export_format.dart';
import 'package:mali_app/domain/value_objects/exported_file.dart';
import 'package:mali_app/presentation/screens/settings/export_screen.dart';
import 'package:mali_app/presentation/screens/settings/settings_screen.dart';
import 'package:mali_app/presentation/utils/export_date_range.dart';

Wallet _cashWallet() {
  return Wallet(
    id: 'w-1',
    userId: 'u-1',
    name: 'Cash',
    currencyCode: 'USD',
    balance: '0',
    isArchived: false,
    isSynced: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

class _SignedInAuth extends Auth {
  @override
  Future<User?> build() async {
    return User(
      id: 'u-1',
      name: 'Tendai',
      createdAt: DateTime(2026, 1, 1),
    );
  }
}

const _exported = ExportedFile(
  path: '/downloads/out.pdf',
  fileName: 'mali-transactions_2026-09-01_2026-09-19.pdf',
  mimeType: 'application/pdf',
  byteCount: 8,
);

class _RecordingExportController extends ExportController {
  ExportRequest? lastRequest;
  Completer<void>? block;

  @override
  FutureOr<ExportedFile?> build() => null;

  @override
  Future<void> submit(ExportRequest request) async {
    lastRequest = request;
    state = const AsyncLoading();
    final gate = block;
    if (gate != null) {
      await gate.future;
    }
    state = const AsyncData(_exported);
  }
}

Future<void> _pumpExportScreen(
  WidgetTester tester, {
  required _RecordingExportController controller,
  List<Wallet>? wallets,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exportControllerProvider.overrideWith(() => controller),
        activeWalletsProvider.overrideWith(
          (ref) => Stream.value(wallets ?? [_cashWallet()]),
        ),
        walletByIdProvider.overrideWith(
          (ref, id) async => id == 'w-1' ? _cashWallet() : null,
        ),
      ],
      child: MaterialApp(
        home: ExportScreen(clock: () => DateTime(2026, 9, 19)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the current month, PDF, and unfiltered defaults',
      (tester) async {
    await _pumpExportScreen(tester, controller: _RecordingExportController());

    expect(find.byKey(ExportScreen.screenKey), findsOneWidget);
    expect(
      find.text(ExportDateRange.label(
        ExportDateRange.currentMonth(DateTime(2026, 9, 19)),
      )),
      findsOneWidget,
    );
    expect(find.text('All wallets'), findsOneWidget);
    expect(find.text('All categories'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
  });

  testWidgets('exports CSV when that format is selected', (tester) async {
    final controller = _RecordingExportController();
    await _pumpExportScreen(tester, controller: controller);

    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ExportScreen.submitKey));
    await tester.pumpAndSettle();

    expect(controller.lastRequest, isNotNull);
    expect(controller.lastRequest!.format, ExportFormat.csv);
    expect(controller.lastRequest!.filters.isEmpty, isTrue);
    expect(
      controller.lastRequest!.range,
      ExportDateRange.currentMonth(DateTime(2026, 9, 19)),
    );
  });

  testWidgets('forwards a wallet filter to the export request', (tester) async {
    final controller = _RecordingExportController();
    await _pumpExportScreen(tester, controller: controller);

    await tester.tap(find.byKey(ExportScreen.walletFilterKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cash'));
    await tester.pumpAndSettle();

    expect(find.text('Cash'), findsWidgets);

    await tester.tap(find.byKey(ExportScreen.submitKey));
    await tester.pumpAndSettle();

    expect(controller.lastRequest!.filters.walletId, 'w-1');
  });

  testWidgets('forwards a category filter to the export request',
      (tester) async {
    final controller = _RecordingExportController();
    await _pumpExportScreen(tester, controller: controller);

    await tester.tap(find.byKey(ExportScreen.categoryFilterKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(ExportScreen.submitKey));
    await tester.pumpAndSettle();

    expect(controller.lastRequest!.filters.categoryId, 'cat-food');
  });

  testWidgets('disables Export while a run is in progress', (tester) async {
    final controller = _RecordingExportController()..block = Completer<void>();
    await _pumpExportScreen(tester, controller: controller);

    await tester.tap(find.byKey(ExportScreen.submitKey));
    await tester.pump();

    expect(find.text('Exporting…'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(ExportScreen.submitKey)).onPressed,
      isNull,
    );

    controller.block!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('announces the saved file after a successful export',
      (tester) async {
    await _pumpExportScreen(tester, controller: _RecordingExportController());

    await tester.tap(find.byKey(ExportScreen.submitKey));
    await tester.pumpAndSettle();

    expect(find.text('Saved ${_exported.fileName}'), findsOneWidget);
  });

  testWidgets('opens the material date range picker', (tester) async {
    await _pumpExportScreen(tester, controller: _RecordingExportController());

    await tester.tap(find.byKey(ExportScreen.dateRangeKey));
    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsOneWidget);
  });

  testWidgets('Settings Export data opens ExportScreen', (tester) async {
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
          routes: [
            GoRoute(
              path: 'export',
              builder: (context, state) =>
                  ExportScreen(clock: () => DateTime(2026, 9, 19)),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(_SignedInAuth.new),
          exportControllerProvider.overrideWith(_RecordingExportController.new),
          activeWalletsProvider.overrideWith(
            (ref) => Stream.value([_cashWallet()]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(SettingsScreen.screenKey), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Export data'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('Export data'));
    await tester.pumpAndSettle();

    expect(find.byKey(ExportScreen.screenKey), findsOneWidget);
  });
}
