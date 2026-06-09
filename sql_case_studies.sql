-- ============================================================
-- SQL CASE STUDIES — Real Business Problems
-- Author: Tanushree Mishra
-- Description: 10 real-world SQL problems with solutions
-- Database: E-commerce + HR + Sales scenarios
-- ============================================================


-- ============================================================
-- SETUP — Sample Tables
-- ============================================================

-- Employees Table
CREATE TABLE employees (
    id          INT PRIMARY KEY,
    name        VARCHAR(100),
    department  VARCHAR(50),
    salary      DECIMAL(10,2),
    manager_id  INT,
    city        VARCHAR(50),
    join_date   DATE
);

-- Orders Table
CREATE TABLE orders (
    order_id    INT PRIMARY KEY,
    customer_id INT,
    product     VARCHAR(100),
    amount      DECIMAL(10,2),
    order_date  DATE,
    status      VARCHAR(20)
);

-- Customers Table
CREATE TABLE customers (
    id      INT PRIMARY KEY,
    name    VARCHAR(100),
    city    VARCHAR(50),
    email   VARCHAR(100)
);

-- Monthly Sales Table
CREATE TABLE monthly_sales (
    month       VARCHAR(10),
    product     VARCHAR(100),
    sales       DECIMAL(10,2)
);


-- ============================================================
-- CASE STUDY 1: Second Highest Salary
-- Problem: Company wants to give bonus to 2nd highest paid employee
-- ============================================================

-- Method 1: Subquery (Simple)
SELECT MAX(salary) AS second_highest_salary
FROM employees
WHERE salary < (SELECT MAX(salary) FROM employees);

-- Method 2: DENSE_RANK (Better — handles ties)
WITH ranked AS (
    SELECT name, salary,
        DENSE_RANK() OVER (ORDER BY salary DESC) AS rnk
    FROM employees
)
SELECT name, salary
FROM ranked
WHERE rnk = 2;

-- WHY THIS MATTERS: Very common interview question.
-- DENSE_RANK handles ties better than subquery method.


-- ============================================================
-- CASE STUDY 2: Customers With No Orders
-- Problem: Marketing team wants to target customers who never ordered
-- ============================================================

-- Method 1: LEFT JOIN + NULL (Preferred)
SELECT c.name, c.email, c.city
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
WHERE o.order_id IS NULL;

-- Method 2: NOT EXISTS
SELECT name, email
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.id
);

-- WHY THIS MATTERS: Real marketing use case.
-- LEFT JOIN + NULL is faster than NOT IN on large datasets.


-- ============================================================
-- CASE STUDY 3: Top 3 Employees Per Department
-- Problem: HR wants top 3 earners from each department for review
-- ============================================================

WITH dept_ranked AS (
    SELECT
        name,
        department,
        salary,
        DENSE_RANK() OVER (
            PARTITION BY department
            ORDER BY salary DESC
        ) AS dept_rank
    FROM employees
)
SELECT name, department, salary, dept_rank
FROM dept_ranked
WHERE dept_rank <= 3
ORDER BY department, dept_rank;

-- WHY THIS MATTERS: PARTITION BY + DENSE_RANK combo.
-- Most asked window function question in product companies.


-- ============================================================
-- CASE STUDY 4: Month Over Month Revenue Growth
-- Problem: Finance team wants to track revenue growth each month
-- ============================================================

WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(amount) AS total_revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
    month,
    total_revenue,
    LAG(total_revenue, 1) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue, 1) OVER (ORDER BY month))
        / LAG(total_revenue, 1) OVER (ORDER BY month) * 100,
        2
    ) AS growth_percentage
FROM monthly_revenue
ORDER BY month;

-- WHY THIS MATTERS: LAG function for time series analysis.
-- Common in fintech — Razorpay, Groww, CRED interviews.


-- ============================================================
-- CASE STUDY 5: Running Total (Cumulative Sales)
-- Problem: Dashboard needs to show cumulative revenue over time
-- ============================================================

SELECT
    order_date,
    amount,
    SUM(amount) OVER (
        ORDER BY order_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM orders
WHERE status = 'completed'
ORDER BY order_date;

-- WHY THIS MATTERS: SUM() OVER = running total.
-- Used in every analytics dashboard.


-- ============================================================
-- CASE STUDY 6: Find Duplicate Records
-- Problem: Data quality team wants to find duplicate customer emails
-- ============================================================

-- Find duplicates
SELECT email, COUNT(*) AS count
FROM customers
GROUP BY email
HAVING COUNT(*) > 1;

-- Show full duplicate records
SELECT *
FROM customers
WHERE email IN (
    SELECT email
    FROM customers
    GROUP BY email
    HAVING COUNT(*) > 1
)
ORDER BY email;

-- Delete duplicates, keep first record
DELETE FROM customers
WHERE id NOT IN (
    SELECT MIN(id)
    FROM customers
    GROUP BY email
);

-- WHY THIS MATTERS: Data quality is core DE responsibility.
-- Asked in almost every Data Engineer interview.


-- ============================================================
-- CASE STUDY 7: Employee Manager Hierarchy
-- Problem: Show each employee with their manager's name
-- ============================================================

SELECT
    e.name        AS employee,
    e.department,
    e.salary,
    m.name        AS manager,
    m.salary      AS manager_salary
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id
ORDER BY e.department, e.salary DESC;

-- WHY THIS MATTERS: Self JOIN concept.
-- Tests understanding of recursive relationships.


-- ============================================================
-- CASE STUDY 8: Products Never Ordered
-- Problem: Inventory team wants to remove products with no orders
-- ============================================================

SELECT p.product_name, p.category, p.price
FROM products p
LEFT JOIN orders o ON p.id = o.product_id
WHERE o.order_id IS NULL;

-- WHY THIS MATTERS: Same LEFT JOIN + NULL pattern.
-- Different business context — shows versatility.


-- ============================================================
-- CASE STUDY 9: Department Salary vs Company Average
-- Problem: Show each employee salary vs their dept avg vs company avg
-- ============================================================

SELECT
    name,
    department,
    salary,
    ROUND(AVG(salary) OVER (PARTITION BY department), 2) AS dept_avg_salary,
    ROUND(AVG(salary) OVER (), 2)                        AS company_avg_salary,
    CASE
        WHEN salary > AVG(salary) OVER (PARTITION BY department)
        THEN 'Above Dept Avg'
        ELSE 'Below Dept Avg'
    END AS salary_status
FROM employees
ORDER BY department, salary DESC;

-- WHY THIS MATTERS: Multiple window functions in one query.
-- Shows advanced SQL knowledge.


-- ============================================================
-- CASE STUDY 10: Cohort Analysis — Monthly Active Users
-- Problem: Product team wants retention analysis
-- ============================================================

WITH first_order AS (
    SELECT
        customer_id,
        MIN(DATE_FORMAT(order_date, '%Y-%m')) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
monthly_activity AS (
    SELECT
        o.customer_id,
        DATE_FORMAT(o.order_date, '%Y-%m') AS activity_month,
        f.cohort_month
    FROM orders o
    JOIN first_order f ON o.customer_id = f.customer_id
)
SELECT
    cohort_month,
    activity_month,
    COUNT(DISTINCT customer_id) AS active_users
FROM monthly_activity
GROUP BY cohort_month, activity_month
ORDER BY cohort_month, activity_month;

-- WHY THIS MATTERS: Cohort analysis — asked in Swiggy, Zomato,
-- PhonePe, Razorpay. Shows product analytics thinking.

