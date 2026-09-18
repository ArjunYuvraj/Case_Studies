# Training Wheels — Session 1 Log

**Scenario:** Willow & Co (online home-goods retailer)
**Stakeholder ask (Meera, Customer Growth Lead):** "It feels like fewer customers are coming back to buy again. I want to know if that's really happening, and why."
**Data:** `customers.csv` (150 rows), `orders.csv` (301 rows)
**Tool:** SQL
**Difficulty:** Easy | **Mode:** Guided Learning

---

## 1. Import problems and how they were solved

### 1.1 Silent row loss on import
- **Symptom:** CSV had 301 rows, but the SQL table only had 291 after import — no error was thrown.
- **Root cause:** `order_amount` is a `FLOAT` column, and 10 rows had a blank cell in that column. When the import tool tried to cast an empty string to a float, it failed — and instead of raising a visible error, it silently dropped the entire row rather than just that cell.
- **Fix:** Re-imported using pandas: `pd.read_csv()` (which correctly reads blank cells as `NaN`) followed by `DataFrame.to_sql()` to load into the table. This preserved all 301 rows, with the 10 problem rows correctly holding SQL `NULL` in `order_amount` instead of vanishing.
- **Key lesson:** "The import completed without errors" does **not** mean all rows made it in. Always compare `len(csv)` against `SELECT COUNT(*) FROM table` after any import.

### 1.2 Judging whether to drop rows with missing data
- **Initial (incorrect) instinct:** Since `order_amount` is "important," rows missing it should just be dropped.
- **Correction:** Relevance of a missing value depends on what question you're answering, not on whether *any* column has a gap.
  - For a **repeat-customer / behavior** question: `order_amount` is irrelevant. A NULL there doesn't make the order any less real — dropping the row would have wrongly erased 10 legitimate purchases (and could have wrongly removed a customer's second order from the repeat-customer count).
  - For a **revenue** question: `order_amount` matters directly. Even then, SQL aggregates like `SUM()`/`AVG()` ignore NULLs automatically — you still wouldn't delete the row, since it likely still counts toward *order count*, just not the dollar total.
- **Key lesson:** Decide row relevance column-by-column, based on the actual question — not "does this row have any blanks anywhere."

---

## 2. Data-quality issues found in the underlying tables

### 2.1 Duplicate order rows
- **Finding:** 11 exact duplicate rows existed for 14 order_ids — same customer, same date, same status, everything identical (aside from a couple of copies missing the amount). Root cause: a logging/system glitch, not real repeat behavior.
- **Fix:** Used `COUNT(DISTINCT order_id)` instead of `COUNT(order_id)` wherever counting orders per customer, so a duplicated order counts once, not twice.
- **Why it mattered:** Without this fix, a customer who placed exactly **one** real order, logged twice, would have been wrongly counted as a repeat customer.

### 2.2 Inconsistent category labels (status and channel)
- **Finding:** Both `status` (`Completed` / `completed` / `COMPLETE` / `Complete`, `Cancelled` / `cancelled` / `CANCELED` / `Canceled`) and `acquisition_channel` (`Paid Social` / `paid social` / `PAID SOCIAL` / `Paid social `, etc.) had inconsistent casing and stray whitespace, effectively splitting single real categories into several fake ones.
- **Fix:** Standardized both columns (trim + normalize casing) before any grouping or aggregation.
- **Why it mattered:** Grouping by a messy `acquisition_channel` initially produced two separate, misleadingly small rows for "Paid Social" and "Paid social " instead of one accurate group — this would have hidden the channel's real repeat-rate pattern.

### 2.3 Order status as a metric-definition judgment call
- **Question:** Should `Cancelled` and `Refunded` orders count as evidence a customer "came back to buy"?
- **Decision made:** `Refunded` counts (the purchase was completed — money changed hands before the refund). `Cancelled` does not (the transaction never completed).
- **Effect:** Excluding `Cancelled` orders moved the overall repeat rate from 60.40% (all orders) to 55.70% (non-cancelled only) — a meaningful, defensible shift.

---

## 3. Findings

| Metric | Value |
|---|---|
| Overall repeat rate (all orders, deduped) | 60.40% |
| Overall repeat rate (non-cancelled, deduped) | **55.70%** ← trusted number |
| Direct — repeat rate | 66.67% |
| Email — repeat rate | 70.83% |
| Organic Search — repeat rate | 75.00% |
| Referral — repeat rate | 52.38% |
| **Paid Social — repeat rate** | **20.51%** ← standout finding |
| Paid Social share of signups, 2025 | 27.59% |
| Paid Social share of signups, 2026 | 25.40% (essentially unchanged) |

**Bottom line for Meera:** Overall repeat purchasing (55.70%) looks fine on average, but that average hides a large gap — every channel except Paid Social repeats between 52-75% of the time, while Paid Social sits at ~20%, roughly a third of its nearest neighbor. Paid Social's share of new signups hasn't grown, so a shifting channel mix isn't the explanation either — this is a standing, structural weakness in that one channel, not a business-wide decline. Recommended next step: investigate why Paid Social customers don't come back (e.g., product-market fit of what that channel attracts, post-purchase follow-up, discount-driven one-time buyers).

---

## 4. Mistakes made along the way (and the correction)

1. **Wanted to drop all rows with any missing value**, regardless of whether the missing column was relevant to the question being asked. *Corrected by:* separating "does this row exist" from "does this specific column have what I need."
2. **Proposed "region" as a driver of repeat behavior**, reasoning about physical distance to a store — for a business that has no physical store. *Corrected by:* checking the hypothesis against the actual business model before testing it, not just because a column existed.
3. **Built a year-over-year (2025 vs 2026) repeat-rate comparison** without accounting for the fact that customer signups are staggered across ~15 months — so 2025 and 2026 cohorts hadn't had equal time to place a second order. This made the comparison invalid (16.11% → 35.57% looked like a dramatic decline, but was largely a cohort-age artifact). *Corrected by:* recognizing that a fair time comparison needs comparable "opportunity windows," not just comparable calendar years, and discarding the invalid numbers rather than reporting them.
4. **After finding new signups had dropped in 2026 vs 2025**, briefly concluded this meant repeat purchasing itself was declining store-wide. This conflated an **acquisition** fact (how many new customers joined) with a **behavior** fact (what existing customers do after their first purchase) — two unrelated things. *Corrected by:* explicitly separating "how many new people are joining" from "what already-acquired customers do."

---

## 5. Things to keep in mind next time

- **After every import**, check row counts match the source file before trusting anything downstream.
- **Before counting anything "per entity,"** check whether the grain assumption holds — is one row really one real event, or could there be duplicates/logging errors?
- **Standardize categorical columns** (trim + case-normalize) before grouping by them — messy labels silently split real categories.
- **A missing value doesn't automatically disqualify a row** — check relevance to the specific question, not just "does this row have a gap somewhere."
- **When defining a metric on ambiguous categories** (like order status), make and state an explicit, reasoned rule — don't leave it implicit.
- **Before proposing a hypothesis (e.g., "region matters"),** sanity-check it against how the business actually works, not just against which columns happen to be available.
- **Before trusting any time-based comparison** (year-over-year, month-over-month), check whether every group being compared had an equal "opportunity window" to produce the outcome — staggered start dates (signups, cohorts) can make a comparison look meaningful when it's really just an artifact of timing.
- **Keep acquisition metrics and behavior metrics separate.** "How many new customers joined" and "what existing customers do after their first purchase" can move independently — don't let a change in one explain a change in the other without checking.
- **Practice going from clean numbers to a plain-language stakeholder sentence** — this was the hardest part of the session and the main thing to keep deliberately practicing.
