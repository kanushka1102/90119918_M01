--Level 2)      Employee_Id=90119918     Name- Anushka Kadam
--Q11)
 select current_database(), current_user;
 show port;

 --Q12)
 select column_name, data_type, is_nullable 
 from information_schema.columns 
 where table_name='loan'
 order by ordinal_position;
 select count(*) as degree from loan;

 --Q13)
 SELECT 'account' AS table_name, COUNT(*) AS row_count FROM account
UNION ALL SELECT 'account_txn', COUNT(*) FROM account_txn
UNION ALL SELECT 'beneficiary',COUNT(*) FROM beneficiary
UNION ALL SELECT 'branch',COUNT(*) FROM branch
UNION ALL SELECT 'card',COUNT(*) FROM card
UNION ALL SELECT 'customer', COUNT(*) FROM customer
UNION ALL SELECT 'employee', COUNT(*) FROM employee
UNION ALL SELECT 'loan', COUNT(*) FROM loan
UNION ALL SELECT 'loan_payment', COUNT(*) FROM loan_payment
ORDER BY table_name;

--q14
SELECT tc.table_name AS child_table,kcu.column_name AS child_column,
    ccu.table_name AS parent_table
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON tc.constraint_name = ccu.constraint_name
    AND tc.table_schema = ccu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.table_name, kcu.column_name;

--Q15
select relname AS table_name,
 pg_size_pretty(pg_total_relation_size(relid)) AS size
 from pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 3;

--16)
insert into customer
(customer_id, first_name, last_name, date_of_birth, email, phone, city, kyc_status, risk_rating, customer_since, home_branch_id)
VALUES
(1032, 'Latha', 'Krishnan', DATE '1985-09-23', 'latha.krishnan@example.com', '9845099887', 'Chennai', 'VERIFIED', 'MEDIUM', DATE '2026-03-01', 5);
INSERT INTO account
(account_id, account_number, customer_id, branch_id, account_type, balance, currency, status, opened_date, interest_rate)
VALUES
(9047, 'ICIC0000009047', 1032, 5, 'CURRENT', 500000.00, 'INR', 'ACTIVE', date '2026-03-01', 0.00);

SELECT c.customer_id, c.first_name, c.last_name, a.account_number,
a.account_type, a.balance
FROM customer c JOIN account a ON a.customer_id = c.customer_id
WHERE c.customer_id=1032;

--17

UPDATE account
SET balance = balance + 75000
WHERE customer_id = 9047;

UPDATE account
SET balance = balance - 20000
WHERE customer_id = 9047;

SELECT customer_id, balance
FROM account
WHERE customer_id = 9047;

--18)

DELETE FROM customer
WHERE customer_id = 1032;


DELETE FROM account
WHERE customer_id = 1032;

DELETE FROM customer
WHERE customer_id = 1032;

SELECT COUNT(*) AS customer_count
FROM customer;

SELECT COUNT(*) AS account_count
FROM account;

--19
--invalid acc. type
INSERT INTO account
(account_id, account_number, customer_id, branch_id, account_type, balance, currency, status, opened_date, interest_rate)
VALUES
(9099, 'ICIC0000009099', 1001, 1, 'FIXED', 1000, 'INR', 'ACTIVE', DATE '2026-03-01', 0);
--neg. txn amt
INSERT INTO account_txn
(txn_id, account_id, txn_date, txn_type, amount, channel, narration, status, reference_no)
VALUES
(999998, 9001, TIMESTAMP '2026-03-01 10:00:00', 'DEBIT', -5000, 'ATM', 'test', 'SUCCESS', 'REF999998');
--kyc status
INSERT INTO Customer
(customer_id, first_name last_name, date_of_birth, email, phone, city, kyc_status, risk_rating, customer_since, home_branch_id) 
VALUES (1033, 'Test', 'User', DATE '1990-01-01', 'test.user@example.com', '9800000000', 'Pune', 'IN_PROGRESS', 'LOW', DATE '2026-03-01', 7);

--20)
--session A
BEGIN;

UPDATE account
SET balance = balance + 5000
WHERE account_no = 9002;

SELECT account_no, balance
FROM account
WHERE account_no = 9002;
--sesssion B at the same time
SELECT account_no, balance
FROM account
WHERE account_no = 9002;

--session A
rollback;
--session B
SELECT account_no, balance
FROM account
WHERE account_no = 9002;

--21)
SELECT account_no, balance
FROM account
WHERE account_no IN (9004, 9010)
ORDER BY account_no;

BEGIN;

UPDATE account
SET balance = balance - 12000
WHERE account_no = 9004;

UPDATE account
SET balance = balance + 12000
WHERE account_no = 9010;

ROLLBACK;

--after rollback
SELECT account_no, balance
FROM account
WHERE account_no IN (9004, 9010)
ORDER BY account_no;

--22)

SHOW shared_buffers;
SHOW work_mem;
SHOW wal_level;
SHOW fsync;