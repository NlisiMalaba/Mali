CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  phone TEXT UNIQUE,
  name TEXT NOT NULL,
  password_hash TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  currency TEXT NOT NULL,
  wallet_type TEXT NOT NULL,
  balance DECIMAL(18,4) NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  icon TEXT NOT NULL,
  color_hex TEXT NOT NULL,
  type TEXT NOT NULL
);

CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  wallet_id UUID NOT NULL REFERENCES wallets(id),
  category_id UUID REFERENCES categories(id),
  type TEXT NOT NULL,
  amount DECIMAL(18,4) NOT NULL,
  currency TEXT NOT NULL,
  notes TEXT,
  source TEXT NOT NULL,
  transacted_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_deleted BOOLEAN DEFAULT FALSE,
  sync_id UUID UNIQUE,
  transfer_to_wallet_id UUID REFERENCES wallets(id),
  exchange_rate DECIMAL(18,8)
);

CREATE TABLE savings_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  emoji TEXT,
  goal_type TEXT,
  target_amount DECIMAL(18,4) NOT NULL,
  currency TEXT NOT NULL,
  saved_amount DECIMAL(18,4) DEFAULT 0,
  deadline DATE,
  priority INT DEFAULT 0,
  is_completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE goal_contributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id UUID NOT NULL REFERENCES savings_goals(id) ON DELETE CASCADE,
  amount DECIMAL(18,4) NOT NULL,
  currency TEXT NOT NULL,
  notes TEXT,
  contributed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES categories(id),
  currency TEXT NOT NULL,
  amount DECIMAL(18,4) NOT NULL,
  month INT NOT NULL,
  year INT NOT NULL,
  rollover BOOLEAN DEFAULT FALSE,
  UNIQUE(user_id, category_id, month, year)
);

CREATE TABLE exchange_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  from_currency TEXT NOT NULL,
  to_currency TEXT NOT NULL,
  rate DECIMAL(18,8) NOT NULL,
  source TEXT NOT NULL,
  valid_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE sync_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  operation TEXT NOT NULL,
  payload JSONB NOT NULL,
  synced_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tx_user_date ON transactions(user_id, transacted_at DESC);
CREATE INDEX idx_tx_wallet ON transactions(wallet_id, transacted_at DESC);
CREATE INDEX idx_tx_category ON transactions(category_id, transacted_at DESC);
CREATE INDEX idx_tx_sync_id ON transactions(sync_id);
CREATE INDEX idx_contrib_goal ON goal_contributions(goal_id, contributed_at DESC);
CREATE INDEX idx_rates_pair ON exchange_rates(user_id, from_currency, to_currency, valid_at DESC);

