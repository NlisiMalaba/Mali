DELETE FROM categories
WHERE user_id IS NULL
  AND name IN (
    'Food',
    'Transport',
    'Airtime/Data',
    'Utilities',
    'School/Education',
    'Medical',
    'Clothing',
    'Entertainment',
    'Groceries',
    'Rent/Housing',
    'Salary',
    'Freelance',
    'Remittance',
    'Other Income',
    'Other Expense'
  );

