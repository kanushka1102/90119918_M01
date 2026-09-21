
-- M02 LEvel 2 Answers----
--NAme- Anushka KAdam    Emp_ID=90119918

--Q11)
create table recurring_deposit(
rd_id int primary key,
customer_id int not null,
branch_id int not null,
rd_number varchar(20) unique not null,
monthly_amount Numeric(12,2) check(monthly_amount>=500),
interest_rate numeric(5,2) check(interest_rate>0 And interest_rate<=12),
tenure_months smallint check(tenure_months between 6 and 120),
start_date date default current_date Not null,
maturity_date date not null,
installments_paid int default 0 check(installments_paid >=0),
status varchar(10) not null default 'Active' not null check (status in('Active','matured','defaulted','closed'))
);
------------------------

--Q12)
--1)Monthly amount = 100 → rejected by CHECK (monthly_amount >= 500)
INSERT INTO recurring_deposit
VALUES
(1001, 1001, 1, 'RD0001001', 100, 7.5, 12, CURRENT_DATE + INTERVAL '12 months');

--2)Customer ID = 5555 -> rejected by foreign key
INSERT INTO recurring_deposit
VALUES
(1002, 5555, 1, 'RD0001002', 5000, 7.5, 12, CURRENT_DATE + INTERVAL '12 months');

--3)Maturity date before start date -> rejected by date CHECK
INSERT INTO recurring_deposit
VALUES
(1003, 1001, 1, 'RD0001003', 5000, 7.5, 12,'2026-09-18', '2026-09-17');

--4)Duplicate RD number -> rejected by UNIQUE
INSERT INTO recurring_deposit
VALUES
(1004, 1001, 1, 'RD0001004', 5000, 7.5, 12, CURRENT_DATE + INTERVAL '12 months');

--5)Status = PAUSED -> rejected by status CHECK
INSERT INTO recurring_deposit
VALUES
(1006, 1001, 1, 'RD0001006', 5000, 7.5, 12,CURRENT_DATE + INTERVAL '12 months', 'PAUSED');

 --6)Installments paid = -3 -> rejected by CHECK
 INSERT INTO recurring_deposit
VALUES
(1007, 1001, 1, 'RD0001007', 5000, 7.5, 12,CURRENT_DATE + INTERVAL '12 months', -3);

-----------------
--Q13)

INSERT INTO recurring_deposit
(rd_id, customer_id, branch_id, rd_number, monthly_amount,
 interest_rate, tenure_months, start_date, maturity_date)
VALUES
(8001, 1001, 1, 'RD2026000001', 5000, 7.10, 24, '2026-03-01', '2028-03-01'),
(8002, 1005, 5, 'RD2026000002', 2500, 6.85, 12, '2026-03-05', '2027-03-05'),
(8003, 1012, 4, 'RD2026000003', 10000, 7.35, 60, '2026-03-10', '2031-03-10');

----------------
--14)
Alter table recurring_deposit add column nominee_name varchar(60); 
Update recurring_deposit set nominee_name='Meera Reddy' where rd_id=8001; 
SELECT rd_id, nominee_name
FROM recurring_deposit
WHERE rd_id = 8001;

-------------------
--15)
SELECT *FROM recurring_deposit
WHERE monthly_amount < 1000;

-- to ckeck the existing constraint
SELECT conname
FROM pg_constraint
WHERE conrelid = 'recurring_deposit'::regclass
  AND contype = 'c';
--drop the contraint
ALTER TABLE recurring_deposit
DROP CONSTRAINT recurring_deposit_monthly_amount_check;
--add new constraint
ALTER TABLE recurring_deposit
ADD CONSTRAINT recurring_deposit_monthly_amount_check
CHECK (monthly_amount >= 1000);
--final check
SELECT *
FROM recurring_deposit
WHERE monthly_amount < 1000;

--------------------
--Q16)
alter table recurring_deposit 
add column scheme_code varchar(8) not null ;  --get error ERROR: column "scheme_code" of relation "recurring_deposit" contains null values

ALTER TABLE recurring_deposit
ADD COLUMN scheme_code VARCHAR(8) not null defult 'RDSTD';  --succeed

--------------
--17)
select receipt_number,principal_amount,interest_rate,maturity_date
from fixed_deposit 
where principal_amount>=500000
order by principal_amount desc;

------------------
--18)
select  receipt_number, booked_date, principal_amount 
from fixed_deposit
where booked_date>='2026-03-01' and booked_date<='2026-03-10'
order by booked_date, principal_amount desc;
------------
--19)
select nominee_name,receipt_number from fixed_deposit
where nominee_name is null
order by receipt_number;

select nominee_name,receipt_number from fixed_deposit
where nominee_name is null or nominee_name<> 'Priya Verma'
order by receipt_number;

--A simple <> 'Priya Verma' does not return NULL values 
--because comparisons with NULL produce UNKNOWN, so IS NULL must be added explicitly.
------------
--20)
select receipt_number,principal_amount,round(principal_amount*interest_rate /100 ,2 ) as annual_interest
from fixed_deposit
order by annual_interest desc
limit 5;

--------------
--21
select fd.receipt_number 
c.first_name ||' 'c.last_name as full_name
fd.principal_amount, 
case when fd.principal_amount>=1000000 then 'HIGH VALUE'
     when fd.principal_amount>=100000 then 'STANDARD'
	 else 'SMALL'
END  as segment
from fixed_deposit fd join customer c on 
c.customer_id=fd.customer_id
order by fd.principal_amount desc;
--------------
--22)
--SQL and MySQL

SELECT txn id, account_id, amount, narration FROM account_txn
WHERE narration LIKE 'UPI/%'
AND amount > 50000
ORDER BY amount DESC
LIMIT 10;

--SQL Server

SELECT TOP 10 txn_id, account_id, amount, narration FROM account_txn
WHERE narration LIKE 'UPI/%' AND amount > 50000
ORDER BY amount DESC;

--Oracle 12c and later

SELECT txn id, account_id, amount, narration FROM account_txn
WHERE narration LIKE 'UPI/%' AND amount > 50000
ORDER BY amount DESC
FETCH FIRST 10 ROWS ONly;

--------------
--23)
BEGIN;
SELECT deposit_id, receipt_number, status, auto_renew
FROM
fixed_deposit WHERE
deposit_id = 7009;

UPDATE fixed_deposit
SET status = 'BROKEN', auto_renew = 'N'
WHERE
deposit_id = 7009;

SELECT deposit_id, receipt_number, status, auto_renew
FROM
fixed_deposit WHERE deposit_id = 7009;

ROLLBACK;

---------------
--24)
SELECT deposit_id, receipt_number, maturity_date FROM fixed deposit
WHERE maturity_date <= DATE '2026-06-30' AND status = 'Active';

BEGIN;
UPDATE fixed_deposit
SET
status 'matured'
WHERE maturity_date <= DATE '2026-06-30' AND status 'Active';


ROLLBACK;

----------------------
--25)
update recurring_deposit set status='defaulted'
where rd_id= 8002;

update recurring_deposit set status='closed'
where rd_id= 8002;
--Reason-
--the regulator requires the bank to reproduce its own history, and the customer may dispute the delault years later. A closed row still answers those questions a deleted row cannot. Deleting also breaks any downstream report that already counted this deposit.

