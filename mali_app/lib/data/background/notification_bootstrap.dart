import 'package:mali_app/application/digest/digest_notification_service.dart';
import 'package:mali_app/application/reminders/contribution_reminder_service.dart';
import 'package:mali_app/core/logging/dev_app_logger.dart';
import 'package:mali_app/core/notifications/local_notification_service.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/data/repositories/local_exchange_rate_repository.dart';
import 'package:mali_app/data/repositories/local_goal_repository.dart';
import 'package:mali_app/data/repositories/local_transaction_repository.dart';
import 'package:mali_app/domain/usecases/build_contribution_reminder_usecase.dart';
import 'package:mali_app/domain/usecases/build_weekly_digest_usecase.dart';
import 'package:mali_app/domain/usecases/convert_money_usecase.dart';
import 'package:mali_app/domain/usecases/get_monthly_summary_usecase.dart';
import 'package:mali_app/domain/value_objects/currency_code.dart';

/// Wiring for the scheduled notification tasks.
class NotificationBootstrap {
  NotificationBootstrap({
    required this.database,
    required this.digestNotificationService,
    required this.contributionReminderService,
  });

  final AppDatabase database;
  final DigestNotificationService digestNotificationService;
  final ContributionReminderService contributionReminderService;

  /// Used by background isolates that cannot access a `ProviderContainer`.
  ///
  /// These notifications read only local data, so no remote client is wired
  /// here.
  static Future<NotificationBootstrap> createForBackgroundIsolate() async {
    final database = AppDatabase();

    final transactionRepository = LocalTransactionRepository(
      transactionDao: database.transactionDao,
    );
    final goalRepository = LocalGoalRepository(goalDao: database.goalDao);
    final convertMoney = ConvertMoneyUseCase(
      exchangeRateRepository: LocalExchangeRateRepository(
        exchangeRateDao: database.exchangeRateDao,
      ),
    );
    final notificationService = LocalNotificationService.instance;
    const logger = DevAppLogger();
    // TODO(settings-31): Read from persisted user preferences once stored
    // outside the Riverpod-only display currency provider.
    const displayCurrency = CurrencyCode.usd;

    return NotificationBootstrap(
      database: database,
      digestNotificationService: DigestNotificationService(
        buildWeeklyDigest: BuildWeeklyDigestUseCase(
          transactionRepository: transactionRepository,
          goalRepository: goalRepository,
          convertMoney: convertMoney,
        ),
        notificationService: notificationService,
        logger: logger,
        displayCurrency: displayCurrency,
      ),
      contributionReminderService: ContributionReminderService(
        buildContributionReminder: BuildContributionReminderUseCase(
          monthlySummary: GetMonthlySummaryUseCase(
            transactionRepository: transactionRepository,
          ),
          goalRepository: goalRepository,
          convertMoney: convertMoney,
        ),
        notificationService: notificationService,
        logger: logger,
        displayCurrency: displayCurrency,
      ),
    );
  }
}
