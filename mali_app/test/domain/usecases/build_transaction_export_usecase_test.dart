import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mali_app/domain/entities/transaction.dart';
import 'package:mali_app/domain/entities/wallet.dart';
import 'package:mali_app/domain/repositories/transaction_repository.dart';
import 'package:mali_app/domain/repositories/wallet_repository.dart';
import 'package:mali_app/domain/usecases/build_transaction_export_usecase.dart';
import 'package:mali_app/domain/value_objects/date_range.dart';
import 'package:mali_app/domain/value_objects/export_filters.dart';

class _FakeTransactionRepository implements ITransactionRepository {
  _FakeTransactionRepository(this._transactions);

  final List<Transaction> _transactions;
  TransactionQuery? lastQuery;
  Object? error;

  @override
  Future<List<Transaction>> list({required TransactionQuery query}) async {
    lastQuery = query;
    if (error != null) {
      throw error!;
    }
    return _transactions;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWalletRepository implements IWalletRepository {
  _FakeWalletRepository(this._wallets);

  final Map<String, String> _wallets;
  final lookups = <String>[];

  @override
  Future<Wallet?> findById(String id) async {
    lookups.add(id);
    final name = _wallets[id];
    if (name == null) {
      return null;
    }
    final timestamp = DateTime(2026, 1, 1);
    return Wallet(
      id: id,
      userId: 'u-1',
      name: name,
      currencyCode: 'USD',
      balance: '0',
      isArchived: false,
      isSynced: true,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Transaction _transaction({
  required String id,
  required String type,
  required String amount,
  required DateTime date,
  String walletId = 'w-1',
  String? categoryId = 'cat-food',
  String currencyCode = 'USD',
  String title = 'Lunch',
  String? notes,
}) {
  return Transaction(
    id: id,
    userId: 'u-1',
    walletId: walletId,
    categoryId: categoryId,
    type: type,
    amount: amount,
    currencyCode: currencyCode,
    title: title,
    notes: notes,
    transactionDate: date,
    isSynced: false,
    createdAt: date,
    updatedAt: date,
  );
}

BuildTransactionExportUseCase _useCase({
  List<Transaction> transactions = const [],
  Map<String, String> wallets = const {'w-1': 'Cash'},
  _FakeTransactionRepository? transactionRepository,
  _FakeWalletRepository? walletRepository,
}) {
  return BuildTransactionExportUseCase(
    transactionRepository:
        transactionRepository ?? _FakeTransactionRepository(transactions),
    walletRepository: walletRepository ?? _FakeWalletRepository(wallets),
    categoryNameLookup: (id) => switch (id) {
      'cat-food' => 'Food',
      'cat-salary' => 'Salary',
      _ => null,
    },
  );
}

void main() {
  final range = DateRange(
    start: DateTime(2026, 8, 1),
    end: DateTime(2026, 9, 30, 23, 59, 59),
  );
  final generatedAt = DateTime(2026, 10, 1, 8);

  group('BuildTransactionExportUseCase validation', () {
    test('rejects a blank user name', () async {
      final result = await _useCase()(
        range: range,
        userName: '   ',
        generatedAt: generatedAt,
      );

      expect(result.isLeft(), isTrue);
    });

    test('trims the user name', () async {
      final result = await _useCase()(
        range: range,
        userName: '  Tendai  ',
        generatedAt: generatedAt,
      );

      final export = result.getOrElse((_) => throw StateError('expected right'));
      expect(export.userName, 'Tendai');
    });

    test('queries the requested date range', () async {
      final repository = _FakeTransactionRepository(const []);

      await _useCase(transactionRepository: repository)(
        range: range,
        userName: 'Tendai',
        generatedAt: generatedAt,
      );

      expect(repository.lastQuery!.dateFrom, range.start);
      expect(repository.lastQuery!.dateTo, range.end);
    });

    test('forwards wallet and category filters to the transaction query',
        () async {
      final repository = _FakeTransactionRepository(const []);

      await _useCase(transactionRepository: repository)(
        range: range,
        userName: 'Tendai',
        generatedAt: generatedAt,
        filters: const ExportFilters(
          walletId: 'w-1',
          categoryId: 'cat-food',
        ),
      );

      expect(repository.lastQuery!.walletId, 'w-1');
      expect(repository.lastQuery!.categoryId, 'cat-food');
    });

    test('maps repository errors to a failure', () async {
      final repository = _FakeTransactionRepository(const [])
        ..error = StateError('db unavailable');

      final result = await _useCase(transactionRepository: repository)(
        range: range,
        userName: 'Tendai',
        generatedAt: generatedAt,
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('BuildTransactionExportUseCase rows', () {
    test('orders rows oldest first and resolves names', () async {
      final result = await _useCase(
        transactions: [
          _transaction(
            id: 't-2',
            type: 'expense',
            amount: '25',
            date: DateTime(2026, 9, 5),
          ),
          _transaction(
            id: 't-1',
            type: 'income',
            amount: '1000',
            date: DateTime(2026, 8, 1),
            categoryId: 'cat-salary',
            title: 'August pay',
          ),
        ],
      )(range: range, userName: 'Tendai', generatedAt: generatedAt);

      final export = result.getOrElse((_) => throw StateError('expected right'));
      expect(export.rows.map((row) => row.transactionId), ['t-1', 't-2']);
      expect(export.rows.first.categoryName, 'Salary');
      expect(export.rows.first.walletName, 'Cash');
      expect(export.rows.first.title, 'August pay');
    });

    test('keeps amounts as stored rather than converting them', () async {
      final result = await _useCase(
        transactions: [
          _transaction(
            id: 't-1',
            type: 'expense',
            amount: '1234.56',
            date: DateTime(2026, 9, 5),
            currencyCode: 'ZAR',
          ),
        ],
      )(range: range, userName: 'Tendai', generatedAt: generatedAt);

      final export = result.getOrElse((_) => throw StateError('expected right'));
      expect(export.rows.single.amount, '1234.56');
      expect(export.rows.single.currencyCode, 'ZAR');
    });

    test('labels unknown categories and missing wallets', () async {
      final result = await _useCase(
        transactions: [
          _transaction(
            id: 't-1',
            type: 'expense',
            amount: '10',
            date: DateTime(2026, 9, 5),
            categoryId: null,
            walletId: 'w-gone',
          ),
        ],
        wallets: const {},
      )(range: range, userName: 'Tendai', generatedAt: generatedAt);

      final export = result.getOrElse((_) => throw StateError('expected right'));
      expect(
        export.rows.single.categoryName,
        BuildTransactionExportUseCase.uncategorisedLabel,
      );
      expect(
        export.rows.single.walletName,
        BuildTransactionExportUseCase.unknownWalletLabel,
      );
    });

    test('looks each wallet up once regardless of row count', () async {
      final walletRepository = _FakeWalletRepository({'w-1': 'Cash'});

      await _useCase(
        transactions: [
          for (var i = 0; i < 5; i++)
            _transaction(
              id: 't-$i',
              type: 'expense',
              amount: '5',
              date: DateTime(2026, 9, 5),
            ),
        ],
        walletRepository: walletRepository,
      )(range: range, userName: 'Tendai', generatedAt: generatedAt);

      expect(walletRepository.lookups, ['w-1']);
    });

    test('reports an empty export when there are no transactions', () async {
      final result = await _useCase()(
        range: range,
        userName: 'Tendai',
        generatedAt: generatedAt,
      );

      final export = result.getOrElse((_) => throw StateError('expected right'));
      expect(export.isEmpty, isTrue);
      expect(export.monthlySummaries, isEmpty);
    });
  });

  group('BuildTransactionExportUseCase monthly summary', () {
    test('groups by month and currency, oldest first', () async {
      final result = await _useCase(
        transactions: [
          _transaction(
            id: 't-1',
            type: 'income',
            amount: '1000',
            date: DateTime(2026, 8, 1),
          ),
          _transaction(
            id: 't-2',
            type: 'expense',
            amount: '250.50',
            date: DateTime(2026, 8, 20),
          ),
          _transaction(
            id: 't-3',
            type: 'expense',
            amount: '400',
            date: DateTime(2026, 9, 3),
            currencyCode: 'ZAR',
          ),
        ],
      )(range: range, userName: 'Tendai', generatedAt: generatedAt);

      final export = result.getOrElse((_) => throw StateError('expected right'));
      expect(export.monthlySummaries, hasLength(2));

      final august = export.monthlySummaries.first;
      expect(august.month, DateTime(2026, 8));
      expect(august.currencyCode, 'USD');
      expect(august.income, Decimal.parse('1000'));
      expect(august.expenses, Decimal.parse('250.50'));
      expect(august.net, Decimal.parse('749.50'));

      final september = export.monthlySummaries.last;
      expect(september.month, DateTime(2026, 9));
      expect(september.currencyCode, 'ZAR');
      expect(september.net, Decimal.parse('-400'));
    });

    test('never mixes currencies into one total', () async {
      final result = await _useCase(
        transactions: [
          _transaction(
            id: 't-1',
            type: 'income',
            amount: '100',
            date: DateTime(2026, 9, 1),
          ),
          _transaction(
            id: 't-2',
            type: 'income',
            amount: '100',
            date: DateTime(2026, 9, 2),
            currencyCode: 'ZAR',
          ),
        ],
      )(range: range, userName: 'Tendai', generatedAt: generatedAt);

      final export = result.getOrElse((_) => throw StateError('expected right'));
      expect(
        export.monthlySummaries.map((s) => s.currencyCode),
        ['USD', 'ZAR'],
      );
    });

    test('ignores transfers, which are not income or expense', () async {
      final result = await _useCase(
        transactions: [
          _transaction(
            id: 't-1',
            type: 'transfer',
            amount: '500',
            date: DateTime(2026, 9, 1),
          ),
        ],
      )(range: range, userName: 'Tendai', generatedAt: generatedAt);

      final export = result.getOrElse((_) => throw StateError('expected right'));
      expect(export.rows, hasLength(1));
      expect(export.monthlySummaries, isEmpty);
    });
  });
}
