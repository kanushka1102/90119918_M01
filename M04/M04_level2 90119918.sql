---M04 level2 
--Name-Anushka Kadam                  Emp_id-90119918
---------------------------------------
--Q11)
SELECT branch_code,count(Distinct(branch_ifsc)) as distinct_IFSC
FROM branch_customer_flat
GROUP BY branch_code
HAVING COUNT(DISTINCT branch_ifsc) > 1;

SELECT branch_code, COUNT(DISTINCT branch_name) AS name_count
FROM branch_customer_flat
GROUP BY branch_code
HAVING COUNT(DISTINCT branch_name) > 1;
----------------------------

--Q12)
SELECT
    branch_code,
    COUNT(*) AS repeated_rows,
    SUM(LENGTH(branch_name)) AS total_name_bytes,
    MAX(LENGTH(branch_name)) AS one_name_bytes
FROM branch_customer_flat
GROUP BY branch_code
ORDER BY branch_code;

SELECT SUM(LENGTH(branch_name)) AS bytes_now FROM branch_customer_flat;
SELECT SUM(LENGTH(branch_name)) AS bytes_normalized
FROM (SELECT DISTINCT branch_code, branch_name FROM branch_customer_flat) d;
------------------------------

--Q13)
SELECT cust_phone, COUNT(*)
FROM branch_customer_flat
GROUP BY cust_phone
HAVING COUNT(*) > 1;

SELECT COUNT(*) AS null_phone_count
FROM branch_customer_flat
WHERE cust_phone IS NULL;
-------------------------
--Q14)
CREATE TABLE ex4_customer_account AS
SELECT cust_id, acct_no_1 AS acct_no, acct_type_1 AS acct_type, balance_1 AS balance
FROM   branch_customer_flat WHERE acct_no_1 IS NOT NULL
UNION ALL
SELECT cust_id, acct_no_2, acct_type_2, balance_2
FROM   branch_customer_flat WHERE acct_no_2 IS NOT NULL;

CREATE TABLE ex4_customer_product AS
SELECT f.cust_id, TRIM(s.product_code) AS product_code
FROM   branch_customer_flat f
       CROSS JOIN LATERAL UNNEST(STRING_TO_ARRAY(f.products, ',')) AS s(product_code)
WHERE  f.products <> 'NONE';

SELECT (SELECT COUNT(*) FROM ex4_customer_account) AS accounts,
       (SELECT COUNT(*) FROM ex4_customer_product) AS product_holdings;

-------------------------------------
--15)
-- Branch identity and the columns that are consistent
CREATE TABLE ex4_branch AS
SELECT DISTINCT branch_code, branch_ifsc, branch_city
FROM   branch_customer_flat;
-- 8 rows

-- The name needs a decision, because BR03 has four
ALTER TABLE ex4_branch ADD COLUMN branch_name VARCHAR(60);

UPDATE ex4_branch b
SET    branch_name = (SELECT f.branch_name
                      FROM   branch_customer_flat f
                      WHERE  f.branch_code = b.branch_code
                      GROUP  BY f.branch_name
                      ORDER  BY COUNT(*) DESC, f.branch_name
                      LIMIT  1);

ALTER TABLE ex4_branch ALTER COLUMN branch_name SET NOT NULL;
ALTER TABLE ex4_branch ADD CONSTRAINT pk_ex4_branch PRIMARY KEY (branch_code);

CREATE TABLE ex4_customer AS
SELECT cust_id, cust_name, cust_phone, cust_city, branch_code
FROM   branch_customer_flat;

ALTER TABLE ex4_customer ADD CONSTRAINT pk_ex4_customer PRIMARY KEY (cust_id);
ALTER TABLE ex4_customer ADD CONSTRAINT fk_ex4_customer_branch
    FOREIGN KEY (branch_code) REFERENCES ex4_branch(branch_code);
-------------------------
--16)
BEGIN;
INSERT INTO ex4_branch (branch_code, branch_ifsc, branch_city, branch_name)
VALUES ('BR09', 'ICIC0000709', 'Jaipur', 'Malviya Nagar');
SELECT COUNT(*) FROM ex4_branch; 
ROLLBACK;

BEGIN;
UPDATE ex4_branch SET branch_name = 'Koramangala Main' WHERE branch_code = 'BR03';
SELECT branch_code, branch_name FROM ex4_branch WHERE branch_code = 'BR03';
ROLLBACK;

BEGIN;
DELETE FROM ex4_customer_account WHERE acct_no = 'ICIC0000009032';
SELECT cust_id, cust_name, cust_phone FROM ex4_customer WHERE cust_id = 1027;
ROLLBACK;
-----------------------------
--Q17)
CREATE TABLE ex4_locker (
    locker_id INTEGER NOT NULL,
    branch_id INTEGER NOT NULL,
    locker_number VARCHAR(10) NOT NULL,
    locker_size VARCHAR(10) NOT NULL,
    annual_rent NUMERIC(10,2) NOT NULL,
    status VARCHAR(12) DEFAULT 'Available' NOT NULL,
    CONSTRAINT pk_ex4_locker PRIMARY KEY (locker_id),
    CONSTRAINT uq_ex4_locker UNIQUE (branch_id, locker_number),
    CONSTRAINT fk_ex4_locker_branch FOREIGN KEY (branch_id)
    REFERENCES branch(branch_id) ON DELETE RESTRICT,
    CONSTRAINT ck_ex4_locker_size CHECK (locker_size IN ('SMALL', 'MEDIUM', 'LARGE')),
    CONSTRAINT ck_ex4_locker_rent CHECK (annual_rent > 0),
    CONSTRAINT ck_ex4_locker_status CHECK (status IN ('AVAILABLE', 'ALLOTTED', 'SURRENDERED'))
);

CREATE TABLE ex4_locker_agreement (
    agreement_id INTEGER NOT NULL,
    locker_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NULL,
    status VARCHAR(12) DEFAULT 'ACTIVE' NOT NULL,
    CONSTRAINT pk_ex4_locker_agreement PRIMARY KEY (agreement_id),
    CONSTRAINT fk_ex4_la_locker FOREIGN KEY (locker_id)
    REFERENCES ex4_locker(locker_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ex4_la_customer FOREIGN KEY (customer_id)
    REFERENCES customer(customer_id) ON DELETE RESTRICT,
    CONSTRAINT ck_ex4_la_dates CHECK (end_date IS NULL OR end_date > start_date),
    CONSTRAINT ck_ex4_la_status CHECK (status IN ('ACTIVE', 'CLOSED', 'SURRENDERED'))
);

CREATE TABLE ex4_locker_visit (
    visit_id BIGINT NOT NULL,
    agreement_id INTEGER NOT NULL,
    visited_at TIMESTAMP NOT NULL,
    supervised_by INTEGER NOT NULL,
    CONSTRAINT pk_ex4_locker_visit PRIMARY KEY (visit_id),
    CONSTRAINT fk_ex4_lv_agreement FOREIGN KEY (agreement_id)
    REFERENCES ex4_locker_agreement(agreement_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ex4_lv_employee FOREIGN KEY (supervised_by)
    REFERENCES employee(employee_id) ON DELETE RESTRICT
);
-----------------------
--18)
Which entity is weak 		ex4_locker_visit. A visit has no meaning without the agreement it occurred under, and would be identified as "visit n of agreement x" 
Which relationship is many-to-many, and how resolved 			Customer to locker, over time. Resolved by ex4_locker_agreement, which carries the relationship's own attributes: start date, end date and status 
Which foreign key is nullable and why 		None of the foreign keys. The nullable column is end_date, because an active agreement genuinely has no end date yet, and NULL is the correct representation of a fact that does not exist 
Two business rules as CHECK con	straints end_date IS NULL OR end_date > start_date, and annual_rent > 0. 
Also acceptable: the locker size and status domains
The rule that cannot be a CHECK: "a locker may be allotted to only one customer at a time". That is a constraint across several rows of ex4_locker_agreement, and CHECK sees only one row. It needs either a unique index on the active rows, or a trigger.

----------------------------
--19)
INSERT INTO ex4_locker_agreement
(agreement_id, locker_id, customer_id, start_date, end_date, status)
VALUES (9001, 1, 1001, DATE '2026-04-01', DATE '2026-03-01', 'ACTIVE');

INSERT INTO ex4_locker_agreement
(agreement_id, locker_id, customer_id, start_date, end_date, status)
VALUES (9002, 1, 1001, DATE '2026-04-01', NULL, 'ACTIVE');
-- INSERT 0 1

----
--20)
CREATE TABLE ex4_branch_daily_summary (
    branch_id     INTEGER        NOT NULL,
    summary_date  DATE           NOT NULL,
    txn_count     INTEGER        NOT NULL,
    total_credits NUMERIC(15,2)  NOT NULL,
    total_debits  NUMERIC(15,2)  NOT NULL,
    CONSTRAINT pk_ex4_bds PRIMARY KEY (branch_id, summary_date),
    CONSTRAINT fk_ex4_bds_branch FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

INSERT INTO ex4_branch_daily_summary
(branch_id, summary_date, txn_count, total_credits, total_debits)
SELECT a.branch_id,
       CAST(t.txn_date AS DATE),
       COUNT(*),
       SUM(CASE WHEN t.txn_type = 'CREDIT' THEN t.amount ELSE 0 END),
       SUM(CASE WHEN t.txn_type = 'DEBIT'  THEN t.amount ELSE 0 END)
FROM   account_txn t
       JOIN account a ON a.account_id = t.account_id
WHERE  t.status = 'SUCCESS'
       AND t.txn_date >= DATE '2026-01-01'
       AND t.txn_date <  DATE '2026-02-01'
GROUP  BY a.branch_id, CAST(t.txn_date AS DATE);
---------------------------------

--21)
SELECT s.branch_id, s.summary_date,
       s.txn_count     AS summary_count,
       t.txn_count     AS live_count,
       s.total_credits AS summary_credits,
       t.total_credits AS live_credits
FROM   ex4_branch_daily_summary s
       FULL OUTER JOIN (
           SELECT a.branch_id,
                  CAST(t.txn_date AS DATE) AS summary_date,
                  COUNT(*) AS txn_count,
                  SUM(CASE WHEN t.txn_type = 'CREDIT' THEN t.amount ELSE 0 END) AS total_credits
           FROM   account_txn t JOIN account a ON a.account_id = t.account_id
           WHERE  t.status = 'SUCCESS'
           AND    t.txn_date >= DATE '2026-01-01' AND t.txn_date < DATE '2026-02-01'
           GROUP  BY a.branch_id, CAST(t.txn_date AS DATE)
       ) t ON t.branch_id = s.branch_id AND t.summary_date = s.summary_date
WHERE  s.txn_count IS DISTINCT FROM t.txn_count
OR     ABS(COALESCE(s.total_credits, 0) - COALESCE(t.total_credits, 0)) > 0.01;

----A non-empty result means one of four things, and the shape of the row tells you which: a day present in the summary but not in the source, meaning the summary has rows it should not; a day in the source but not the summary, meaning the load missed it; matching days with different counts, meaning transactions arrived after the summary ran; or matching counts with different totals, meaning a rounding or type difference in the load. 
Two details worth teaching. FULL OUTER JOIN rather than an inner join, because an inner join can only find rows that exist on both sides and would silently miss an entirely absent day - the most likely failure. And IS DISTINCT FROM rather than <>, because <> returns NULL when one side is NULL, so a missing day would fail the comparison and be dropped from the exception report.
---------------------------------