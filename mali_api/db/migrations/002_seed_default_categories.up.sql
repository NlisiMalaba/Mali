INSERT INTO categories (user_id, name, icon, color_hex, type)
VALUES
  (NULL, 'Food', 'restaurant', '#FF6B6B', 'expense'),
  (NULL, 'Transport', 'directions_bus', '#4ECDC4', 'expense'),
  (NULL, 'Airtime/Data', 'signal_cellular_alt', '#45B7D1', 'expense'),
  (NULL, 'Utilities', 'bolt', '#F7B731', 'expense'),
  (NULL, 'School/Education', 'school', '#5F27CD', 'expense'),
  (NULL, 'Medical', 'local_hospital', '#EE5253', 'expense'),
  (NULL, 'Clothing', 'checkroom', '#10AC84', 'expense'),
  (NULL, 'Entertainment', 'movie', '#FF9FF3', 'expense'),
  (NULL, 'Groceries', 'shopping_cart', '#00D2D3', 'expense'),
  (NULL, 'Rent/Housing', 'home', '#576574', 'expense'),
  (NULL, 'Salary', 'payments', '#1DD1A1', 'income'),
  (NULL, 'Freelance', 'work', '#54A0FF', 'income'),
  (NULL, 'Remittance', 'send', '#5F9EA0', 'income'),
  (NULL, 'Other Income', 'account_balance_wallet', '#2ECC71', 'income'),
  (NULL, 'Other Expense', 'receipt_long', '#8395A7', 'expense')
ON CONFLICT DO NOTHING;

