-- M03 level2
----Name- Anushka Kadam        Emp_id-90119918
----------------------------------------
--Q11)
select c.card_type,c.card_number_masked,c.status,
    a.account_number,cu.first_name || ' ' || cu.last_name AS customer_name,b.branch_name
from card c
join account a ON c.account_id = a.account_id
join customer cu ON a.customer_id = cu.customer_id
join branch b ON a.branch_id = b.branch_id
ORDER BY b.branch_name, customer_name;

---------------------------------------
--Q12)
select cu.first_name || ' ' || cu.last_name AS customer_name,
    a.account_number,round(a.balance,2) as The_balance,b.branch_name
from customer cu
join  branch b ON b.branch_id = cu.home_branch_id
left join  account a ON cu.customer_id = a.customer_id
where  b.branch_name IN ('Koramangala', 'Whitefield') OR a.account_id IS NULL
ORDER BY a.balance desc nulls last;

------------------------------
--Q13)
select a.account_number,a.account_type,
    a.status,cu.first_name || ' ' || cu.last_name AS customer_name
from account a
join customer cu ON a.customer_id = cu.customer_id
left join account_txn t
    ON a.account_id = t.account_id
where t.txn_id IS NULL;

-------------------------
--Q14)
select a.account_number,a.account_type,
    cu.first_name || ' ' || cu.last_name AS customer_name
from account a
join customer cu ON a.customer_id = cu.customer_id
left join card c ON a.account_id = c.account_id
where c.account_id IS NULL
order by a.account_number;

--to get count
select COUNT(*) AS account_without_card
from account a
left join card c ON a.account_id = c.account_id
where c.account_id IS NULL;

----------------------
--Q15)
select e.first_name || ' ' || e.last_name as employee_name,e.designation,
    b.branch_name,
    COALESCE(m.first_name || ' ' || m.last_name, '(no Manager)') AS reports_to
from employee e
join branch b ON e.branch_id = b.branch_id
left join employee m ON e.manager_id = m.employee_id
order by b.branch_name, e.employee_id;

----------------------------
--Q16)
select  m.first_name || ' ' || m.last_name AS manager_name,
    b.branch_name,COUNT(e.employee_id) AS team_size,
    COALESCE(SUM(e.salary), 0) AS total_team_salary
from employee m
join branch b ON m.branch_id = b.branch_id
left join employee e ON e.manager_id = m.employee_id
WHERE m.designation = 'Branch Manager'
group by m.employee_id,m.employee_name,b.branch_name
order by b.branch_name;
--------------------------
--Q17)
--create table
CREATE TABLE loan_risk_band (
    band_code VARCHAR(4) not null PRIMARY KEY,
    band_name VARCHAR(20) not null,
    min_outstanding numeric(15,2) not null,
    max_outstanding numeric(15,2) not null
);
--insert the bands
insert into loan_risk_band
(band_code, band_name, min_outstanding, max_outstanding)
VALUES ('L1', 'Small', 0, 500000);

insert into loan_risk_band
(band_code, band_name, min_outstanding, max_outstanding)
VALUES ('L2', 'Medium', 500000, 2000000);

insert into loan_risk_band
(band_code, band_name, min_outstanding, max_outstanding)
VALUES ('L3', 'Large', 2000000, 5000000);
insert into loan_risk_band
(band_code, band_name, min_outstanding, max_outstanding)
VALUES ('L4', 'Very Large', 5000000, 99999999);

--final step
select r.band_code,r.band_name,
    COUNT(l.loan_id) AS loan_count,
    COALESCE(SUM(l.outstanding_amount), 0) AS total_outstanding
FROM loan_risk_band r
left join loan l ON l.outstanding_amount >= r.min_outstanding
   AND l.outstanding_amount <= r.max_outstanding
group by r.band_code,r.band_name
ORDER BY r.band_code;

--------------------
--Q18)
select b.branch_name,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    COUNT(DISTINCT a.account_id) AS account_count,
    ROUND(SUM(a.balance), 2) AS total_balance,
    ROUND(AVG(a.balance), 2) AS average_balance
from branch b
left join customer c ON b.branch_id = c.home_branch_id
left join account a ON c.customer_id = a.customer_id
group by  b.branch_name
ORDER BY total_balance DESC;

--------------------------------
--Q19)
select l.loan_type,
    COUNT(l.loan_id) AS loan_count,
    round(SUM(l.principal_amount),2) AS total_principal,
    round(SUM(l.outstanding_amount),2) AS total_outstanding,
    ROUND(
        SUM(l.outstanding_amount) / (SUM(l.principal_amount), 1) * 100,
        1
    ) AS outstanding_percentage
from loan l
group by l.loan_type
ORDER BY outstanding desc;

----------------------
--Q20)
select
    channel,
    SUM(CASE
            WHEN status = 'SUCCESS' THEN 1
            ELSE 0
        END) AS successful_transactions,

    SUM(CASE
            WHEN status = 'FAILED' THEN 1
            ELSE 0
        END) AS failed_transactions,

    SUM(CASE
            WHEN status = 'SUCCESS' THEN amount
            ELSE 0
        END) AS total_successful_value,

    ROUND(
        SUM(CASE
                WHEN status = 'FAILED' THEN 1
                ELSE 0
            END)
        / NULLIF(COUNT(*), 2) * 100,
        2
    ) AS failure_rate
FROM account_txn 
GROUP BY channel
ORDER BY failure_rate DESC;

--------------------
--Q21)
select b.branch_name,
    COUNT(l.loan_id) AS loan_count,
    SUM(l.outstanding_amount) AS total_outstanding
from branch b
join loan l ON b.branch_id = l.branch_id
GROUP By b.branch_name
having sum(l.outstanding_amount) > 2000000
order by total_outstanding DESC;


------------------------
--Q22)
select
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(a.account_id) AS account_count,
    SUM(a.balance) AS combined_balance
from customer c
join account a ON c.customer_id = a.customer_id
group by  c.customer_id,c.first_name,
    c.last_name
HAVING COUNT(a.account_id) >= 2
order by combined_balance DESC;


--------------------
--Q23)
select
    to_char(txn_date, 'YYYY-MM') AS month,
    COUNT(*) AS transaction_count,
    SUM(CASE
            WHEN txn_type = 'CREDIT' THEN amount
            ELSE 0
        END) AS total_credits,

    SUM(CASE
            WHEN txn_type = 'DEBIT' THEN amount
            ELSE 0
        END) AS total_debits,

    SUM(CASE
            WHEN txn_type = 'CREDIT' THEN amount
            WHEN txn_type = 'DEBIT' THEN -amount
            ELSE 0
        END) AS net_movement

from account_txn
group by to_char(txn_date, 'YYYY-MM')
ORDER BY month;
--------------------------
--Q24)
select account_number,round(balance,2) as balance
from account
where balance > 2*(
   select  AVG(balance)
    from account
)
order by balance DESC;

-----------------------------------
--Q25)
select b.branch_name,
    a.balance AS largest_account_balance
from branch b
join account a ON a.branch_id = b.branch_id
where  a.balance = (
    SELECT MAX(a2.balance)
    FROM account a2
    WHERE a2.branch_id = b.branch_id
)
ORDER BY largest_account_balance desc;
-----------------
--Q26)
select
    c.customer_id,c.first_name || ' ' || c.last_name AS customer_name
from customer c
JOIN loan l ON l.customer_id = c.customer_id
left join fixed_deposit fd
    ON fd.customer_id = c.customer_id
where fd.customer_id IS NULL
ORDER BY c.customer_id;

-----------------------------
--Q27)
SELECT ct.customer_id, ct.customer_name, ct.total_value
FROM (SELECT c.customer_id,
             c. first name || || c.last_name AS customer_name,
             SUM(t.amount) AS total_value
       FROM customer c
            JOIN account a ON a.customer_id = c.customer_id
            JOIN account_txn t ON t.account_id a.account_id 
	   WHERE t.status = 'SUCCESS'
       GROUP BY c.customer_id, c.first_name, c.alast_name) AS ct

WHERE ct.total_value> (SELECT AVG(total_value)
                       FROM (SELECT SUM(t.amount) AS total value,
                              FROM account_txn t
                                   join account a ON a.account_id=t.account_id
                              WHERE t.status SUCCESS
                               Group by a.customer_id) as per_customer)
ORDER BY ct.total_value DESC;

------------------------------
--Q28)
select customer_id, product_type,
    round(amount,2) AS amount
FROM (SELECT
    customer_id,
    'DEPOSIT' AS product_type,
    principal AS amount
    FROM fixed_deposit
     UNION ALL
    SELECT
    customer_id,
    'LOAN' AS product_type,
    principal_amount AS amount
     FROM loan
     UNION ALL
     select customer_id,'ACCOUNT',balance from
     account)
ORDER BY customer_id, product_type

------------------------
--Q29)
select customer_id from fixed_deposit
intersect
select customer_id from loan;

select customer_id from fixed_deposit
except
select customer_id from loan;

select customer_id from loan
except 
select customer_id from fixed_deposit;

select customer_id from loan
union 
select customer_id from fixed_deposit;
