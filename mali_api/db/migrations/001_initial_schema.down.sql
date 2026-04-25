DROP INDEX IF EXISTS idx_rates_pair;
DROP INDEX IF EXISTS idx_contrib_goal;
DROP INDEX IF EXISTS idx_tx_sync_id;
DROP INDEX IF EXISTS idx_tx_category;
DROP INDEX IF EXISTS idx_tx_wallet;
DROP INDEX IF EXISTS idx_tx_user_date;

DROP TABLE IF EXISTS sync_log;
DROP TABLE IF EXISTS exchange_rates;
DROP TABLE IF EXISTS budgets;
DROP TABLE IF EXISTS goal_contributions;
DROP TABLE IF EXISTS savings_goals;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS wallets;
DROP TABLE IF EXISTS users;

