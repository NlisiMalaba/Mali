import 'package:mali_app/application/digest/digest_notification_service.dart';
import 'package:mali_app/application/reminders/contribution_reminder_service.dart';
import 'package:mali_app/core/logging/dev_app_logger.dart';
import 'package:mali_app/core/notifications/local_notification_service.dart';
import 'package:mali_app/core/storage/app_preferences_store.dart';
import 'package:mali_app/data/local/app_database.dart';
import 'package:mali_app/data/repositories/local_exchange_rate_repository.dart';
import 'package:mali_app/data/repositories/local_goal_repository.dart';
import 'package:mali_app/data/repositories/local_transaction_repository.dart';
import 'package:mali_app/domain/usecases/build_contribution_reminder_usecase.dart';
import 'package:mali_app/domain/usecases/build_weekly_digest_usecase.dart';
import 'package:mali_app/domain/usecases/convert_money_usecase.dart';
import 'package:mali_app/domain/usecases/get_monthly_summary_usecase.dart';
import 'package:mali_app/domain/entities/app_preferences.dart';

/// Wiring for the scheduled notification tasks.
class NotificationBootstrap {
  NotificationBootstrap({
    required this.database,
    required this.digestNotificationService,
    required this.contributionReminderService,
    required this.preferences,
  });

  final AppDatabase database;
  final DigestNotificationService digestNotificationService;
  final ContributionReminderService contributionReminderService;

  /// The user's saved settings, so tasks can respect notification toggles.
  final AppPreferences preferences;

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
    final preferences = await const AppPreferencesStore().read();
    final displayCurrency = preferences.displayCurrency;

    return NotificationBootstrap(
      database: database,
      preferences: preferences,
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
