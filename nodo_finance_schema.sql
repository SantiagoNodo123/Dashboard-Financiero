CREATE TABLE companies (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  legal_name TEXT,
  base_currency CHAR(3) NOT NULL DEFAULT 'COP',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE fiscal_periods (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('open', 'closed')),
  UNIQUE (company_id, period_start, period_end)
);

CREATE TABLE clients (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  industry TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sales_contracts (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),
  client_id BIGINT NOT NULL REFERENCES clients(id),
  contract_name TEXT NOT NULL,
  revenue_type TEXT NOT NULL CHECK (revenue_type IN ('one_time', 'recurring')),
  monthly_recurring_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_contract_value NUMERIC(14,2) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE,
  status TEXT NOT NULL CHECK (status IN ('active', 'paused', 'closed', 'cancelled'))
);

CREATE TABLE invoices (
  id BIGSERIAL PRIMARY KEY,
  sales_contract_id BIGINT NOT NULL REFERENCES sales_contracts(id),
  fiscal_period_id BIGINT NOT NULL REFERENCES fiscal_periods(id),
  invoice_number TEXT NOT NULL,
  issued_at DATE NOT NULL,
  due_at DATE NOT NULL,
  paid_at DATE,
  amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
  status TEXT NOT NULL CHECK (status IN ('draft', 'issued', 'paid', 'void', 'overdue')),
  UNIQUE (invoice_number)
);

CREATE TABLE opex_categories (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  is_marketing_spend BOOLEAN NOT NULL DEFAULT false,
  UNIQUE (company_id, name)
);

CREATE TABLE opex_expenses (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),
  fiscal_period_id BIGINT NOT NULL REFERENCES fiscal_periods(id),
  category_id BIGINT NOT NULL REFERENCES opex_categories(id),
  description TEXT NOT NULL,
  vendor TEXT,
  expense_date DATE NOT NULL,
  amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
  payment_method TEXT,
  source TEXT NOT NULL DEFAULT 'manual'
);

CREATE TABLE fixed_assets (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),
  asset_name TEXT NOT NULL,
  asset_type TEXT NOT NULL CHECK (asset_type IN ('laptop', 'screen', 'audio', 'camera', 'network', 'furniture', 'other')),
  purchase_date DATE NOT NULL,
  purchase_value NUMERIC(14,2) NOT NULL CHECK (purchase_value >= 0),
  useful_life_months INTEGER NOT NULL CHECK (useful_life_months > 0),
  financed BOOLEAN NOT NULL DEFAULT false,
  status TEXT NOT NULL CHECK (status IN ('active', 'sold', 'retired'))
);

CREATE TABLE liabilities (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),
  fixed_asset_id BIGINT REFERENCES fixed_assets(id),
  lender_name TEXT NOT NULL,
  liability_type TEXT NOT NULL CHECK (liability_type IN ('credit_card', 'personal_loan', 'vendor_financing', 'bank_loan')),
  principal_amount NUMERIC(14,2) NOT NULL CHECK (principal_amount >= 0),
  outstanding_balance NUMERIC(14,2) NOT NULL CHECK (outstanding_balance >= 0),
  annual_interest_rate NUMERIC(6,3) NOT NULL DEFAULT 0,
  opened_at DATE NOT NULL,
  maturity_date DATE,
  status TEXT NOT NULL CHECK (status IN ('active', 'paid', 'defaulted'))
);

CREATE TABLE liability_payments (
  id BIGSERIAL PRIMARY KEY,
  liability_id BIGINT NOT NULL REFERENCES liabilities(id),
  fiscal_period_id BIGINT NOT NULL REFERENCES fiscal_periods(id),
  payment_date DATE NOT NULL,
  total_payment NUMERIC(14,2) NOT NULL CHECK (total_payment >= 0),
  principal_component NUMERIC(14,2) NOT NULL CHECK (principal_component >= 0),
  interest_component NUMERIC(14,2) NOT NULL CHECK (interest_component >= 0),
  CHECK (total_payment = principal_component + interest_component)
);

CREATE TABLE capital_fund_transactions (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),
  fiscal_period_id BIGINT REFERENCES fiscal_periods(id),
  investor_name TEXT NOT NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('founder_contribution', 'angel_round', 'venture_capital', 'withdrawal')),
  amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
  transaction_date DATE NOT NULL,
  notes TEXT
);

CREATE TABLE cash_movements (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),
  fiscal_period_id BIGINT NOT NULL REFERENCES fiscal_periods(id),
  movement_date DATE NOT NULL,
  movement_type TEXT NOT NULL CHECK (movement_type IN ('operating_inflow', 'operating_outflow', 'debt_payment', 'capital_inflow', 'capital_outflow')),
  source_table TEXT NOT NULL,
  source_id BIGINT NOT NULL,
  amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0)
);

CREATE TABLE marketing_campaigns (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),
  fiscal_period_id BIGINT NOT NULL REFERENCES fiscal_periods(id),
  campaign_name TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('Meta Ads', 'Google Ads', 'LinkedIn', 'TikTok', 'Orgánico')),
  investment_amount NUMERIC(14,2) NOT NULL CHECK (investment_amount >= 0),
  leads_count INTEGER NOT NULL CHECK (leads_count >= 0),
  conversions_count INTEGER NOT NULL CHECK (conversions_count >= 0),
  attributed_revenue NUMERIC(14,2) NOT NULL CHECK (attributed_revenue >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE social_metrics (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),
  fiscal_period_id BIGINT NOT NULL REFERENCES fiscal_periods(id),
  network TEXT NOT NULL,
  followers_start INTEGER NOT NULL CHECK (followers_start >= 0),
  followers_end INTEGER NOT NULL CHECK (followers_end >= 0),
  engagement_rate NUMERIC(6,3) NOT NULL CHECK (engagement_rate >= 0),
  leads_attributed INTEGER NOT NULL DEFAULT 0 CHECK (leads_attributed >= 0)
);

CREATE VIEW monthly_financial_summary AS
WITH paid_invoices AS (
  SELECT fiscal_period_id, SUM(amount) AS total_sales
  FROM invoices
  WHERE status = 'paid'
  GROUP BY fiscal_period_id
),
period_opex AS (
  SELECT fiscal_period_id, SUM(amount) AS opex_amount
  FROM opex_expenses
  GROUP BY fiscal_period_id
),
period_debt AS (
  SELECT
    fiscal_period_id,
    SUM(total_payment) AS monthly_debt_payment,
    SUM(interest_component) AS debt_interest_opex
  FROM liability_payments
  GROUP BY fiscal_period_id
),
asset_totals AS (
  SELECT company_id, SUM(purchase_value) AS total_tech_assets
  FROM fixed_assets
  WHERE status = 'active'
  GROUP BY company_id
),
liability_totals AS (
  SELECT company_id, SUM(outstanding_balance) AS debt_balance
  FROM liabilities
  WHERE status = 'active'
  GROUP BY company_id
),
capital_totals AS (
  SELECT
    company_id,
    SUM(
      CASE
        WHEN transaction_type IN ('founder_contribution', 'angel_round', 'venture_capital') THEN amount
        ELSE -amount
      END
    ) AS capital_fund_available
  FROM capital_fund_transactions
  GROUP BY company_id
)
SELECT
  fp.id AS fiscal_period_id,
  fp.company_id,
  COALESCE(pi.total_sales, 0) AS total_sales,
  COALESCE(po.opex_amount, 0) + COALESCE(pd.debt_interest_opex, 0) AS operating_opex,
  COALESCE(pi.total_sales, 0) - (COALESCE(po.opex_amount, 0) + COALESCE(pd.debt_interest_opex, 0)) AS operating_profit,
  COALESCE(pd.monthly_debt_payment, 0) AS monthly_debt_payment,
  COALESCE(pi.total_sales, 0) - (COALESCE(po.opex_amount, 0) + COALESCE(pd.debt_interest_opex, 0)) - COALESCE(pd.monthly_debt_payment, 0) AS free_cash_flow,
  COALESCE(at.total_tech_assets, 0) AS total_tech_assets,
  COALESCE(lt.debt_balance, 0) AS debt_balance,
  COALESCE(ct.capital_fund_available, 0) AS capital_fund_available,
  CASE
    WHEN COALESCE(pi.total_sales, 0) - (COALESCE(po.opex_amount, 0) + COALESCE(pd.debt_interest_opex, 0)) - COALESCE(pd.monthly_debt_payment, 0) < 0
      THEN COALESCE(ct.capital_fund_available, 0) / ABS(COALESCE(pi.total_sales, 0) - (COALESCE(po.opex_amount, 0) + COALESCE(pd.debt_interest_opex, 0)) - COALESCE(pd.monthly_debt_payment, 0))
    ELSE NULL
  END AS runway_months
FROM fiscal_periods fp
LEFT JOIN paid_invoices pi ON pi.fiscal_period_id = fp.id
LEFT JOIN period_opex po ON po.fiscal_period_id = fp.id
LEFT JOIN period_debt pd ON pd.fiscal_period_id = fp.id
LEFT JOIN asset_totals at ON at.company_id = fp.company_id
LEFT JOIN liability_totals lt ON lt.company_id = fp.company_id
LEFT JOIN capital_totals ct ON ct.company_id = fp.company_id;

CREATE VIEW marketing_campaign_roi AS
SELECT
  id,
  company_id,
  fiscal_period_id,
  campaign_name,
  platform,
  investment_amount,
  leads_count,
  conversions_count,
  attributed_revenue,
  CASE WHEN leads_count = 0 THEN 0 ELSE investment_amount / leads_count END AS cost_per_lead,
  CASE WHEN leads_count = 0 THEN 0 ELSE (conversions_count::NUMERIC / leads_count) * 100 END AS conversion_rate,
  CASE WHEN investment_amount = 0 THEN 0 ELSE attributed_revenue / investment_amount END AS roas
FROM marketing_campaigns;

-- Critical accounting rules implemented by design:
-- 1. Financed CAPEX is recorded in fixed_assets and opens a liability in liabilities.
--    Monthly payments reduce principal through liability_payments.principal_component.
--    Only liability_payments.interest_component is included in operating OPEX.
-- 2. Capital injections live in capital_fund_transactions and never join sales_contracts
--    or invoices, preserving true operating revenue metrics.
