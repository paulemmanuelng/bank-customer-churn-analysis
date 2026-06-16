-- schema.sql
-- Defines the "customers" table for the bank churn dataset, then we import
-- the CSV into it. Defining types up front (rather than letting everything
-- be text) means numbers behave like numbers when we do maths on them.
--
-- Data dictionary (what each column means):
--   credit_score      credit score (higher = better)
--   geography         country: France, Spain, or Germany
--   gender            Male / Female
--   age               age in years
--   tenure            number of years the person has been a customer
--   balance           money in their account
--   num_products      how many bank products they hold (1-4)
--   has_credit_card   1 = has a credit card, 0 = doesn't
--   is_active_member  1 = active user, 0 = inactive
--   estimated_salary  estimated annual salary
--   exited            1 = CHURNED (left the bank), 0 = stayed   <-- our target

DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    row_number       INTEGER,
    customer_id      INTEGER,
    surname          TEXT,
    credit_score     INTEGER,
    geography        TEXT,
    gender           TEXT,
    age              INTEGER,
    tenure           INTEGER,
    balance          REAL,
    num_products     INTEGER,
    has_credit_card  INTEGER,
    is_active_member INTEGER,
    estimated_salary REAL,
    exited           INTEGER
);
