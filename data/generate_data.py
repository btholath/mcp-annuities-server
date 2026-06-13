"""
Synthetic Retirement / Annuities Dataset Generator
Run once:  python data/generate_data.py
Produces:  data/annuities.csv  (500 rows, no PII)
"""
import csv, random, math
from datetime import date, timedelta

random.seed(42)

PRODUCT_TYPES  = ["Fixed", "Variable", "Indexed", "Immediate", "Deferred Income"]
RIDERS         = ["Death Benefit", "GLWB", "GMIB", "LTC", "None"]
PAY_FREQ       = ["Monthly", "Quarterly", "Annual"]
RISK_PROFILES  = ["Conservative", "Moderate", "Aggressive"]
STATES         = ["CA","TX","FL","NY","IL","OH","PA","AZ","WA","CO"]

def rand_date(start_year=1955, end_year=1975):
    start = date(start_year, 1, 1)
    end   = date(end_year, 12, 31)
    return start + timedelta(days=random.randint(0,(end-start).days))

rows = []
for i in range(1, 501):
    dob          = rand_date()
    age          = (date.today() - dob).days // 365
    premium      = round(random.uniform(25_000, 500_000), 2)
    rate         = round(random.uniform(2.5, 6.5), 2)
    term_yrs     = random.choice([5,7,10,15,20])
    monthly_pay  = round(premium * (rate/100/12) / (1-(1+rate/100/12)**(-term_yrs*12)), 2)
    surrender_pct= round(random.uniform(0,10), 2)
    product      = random.choice(PRODUCT_TYPES)
    rider        = random.choice(RIDERS)
    risk         = random.choice(RISK_PROFILES)
    state        = random.choice(STATES)
    freq         = random.choice(PAY_FREQ)
    start_date   = rand_date(2010, 2023)
    balance      = round(premium * (1 + rate/100) ** random.uniform(1,12), 2)
    rows.append([
        f"CLIENT_{i:04d}", dob.isoformat(), age,
        product, premium, rate, term_yrs,
        monthly_pay, surrender_pct, rider, risk,
        state, freq, start_date.isoformat(), balance
    ])

headers = [
    "client_id","date_of_birth","age",
    "product_type","premium_amount","crediting_rate_pct","term_years",
    "monthly_payment","surrender_charge_pct","rider","risk_profile",
    "state","payment_frequency","contract_start_date","current_account_value"
]

import os
os.makedirs(os.path.dirname(__file__), exist_ok=True)
with open(os.path.join(os.path.dirname(__file__), "annuities.csv"), "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(headers)
    w.writerows(rows)

print(f"✅ Generated {len(rows)} rows → data/annuities.csv")
