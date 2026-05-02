# 📚 Library Management System — SQL Project

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=flat-square&logo=postgresql&logoColor=white)
![PL/pgSQL](https://img.shields.io/badge/PL%2FpgSQL-Stored%20Procedures-4A90D9?style=flat-square)
![CTAS](https://img.shields.io/badge/CTAS-Derived%20Tables-8E44AD?style=flat-square)
![Tables](https://img.shields.io/badge/Tables-6-E67E22?style=flat-square)
![Tasks](https://img.shields.io/badge/Tasks-18-27AE60?style=flat-square)
![Status](https://img.shields.io/badge/Status-Complete-14B8A6?style=flat-square)

> A fully functional **relational database system** for a library — built from schema design through stored procedures — demonstrating end-to-end SQL from CRUD to advanced PL/pgSQL automation.

---

## ❯ What Makes This Different

Most SQL projects query an existing dataset.

This project **builds the system from scratch** — database, schema, relationships, data, queries, and automated procedures — the way a real backend database is actually constructed and maintained.

```
Phase 1 → Database & Schema Design     (6 tables, FK constraints)
Phase 2 → CRUD Operations              (INSERT, SELECT, UPDATE, DELETE)
Phase 3 → CTAS Derived Tables          (materialized summary tables)
Phase 4 → Analytical Queries           (joins, aggregations, date logic)
Phase 5 → Advanced SQL                 (overdue detection, branch reports)
Phase 6 → Stored Procedures            (PL/pgSQL automation with IF logic)
```

---

## ❯ Entity Relationship Diagram

![ERD](https://github.com/najirh/Library-System-Management---P2/blob/main/library_erd.png)

---

## ❯ Database Schema — 6 Tables

```sql
CREATE DATABASE library_db;

-- Branch locations
CREATE TABLE branch (
    branch_id      VARCHAR(10) PRIMARY KEY,
    manager_id     VARCHAR(10),
    branch_address VARCHAR(30),
    contact_no     VARCHAR(15)
);

-- Staff / employees
CREATE TABLE employees (
    emp_id    VARCHAR(10) PRIMARY KEY,
    emp_name  VARCHAR(30),
    position  VARCHAR(30),
    salary    DECIMAL(10,2),
    branch_id VARCHAR(10),
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

-- Library members
CREATE TABLE members (
    member_id      VARCHAR(10) PRIMARY KEY,
    member_name    VARCHAR(30),
    member_address VARCHAR(30),
    reg_date       DATE
);

-- Book catalogue
CREATE TABLE books (
    isbn         VARCHAR(50) PRIMARY KEY,
    book_title   VARCHAR(80),
    category     VARCHAR(30),
    rental_price DECIMAL(10,2),
    status       VARCHAR(10),   -- 'yes' = available, 'no' = issued
    author       VARCHAR(30),
    publisher    VARCHAR(30)
);

-- Book issuance records
CREATE TABLE issued_status (
    issued_id        VARCHAR(10) PRIMARY KEY,
    issued_member_id VARCHAR(30),
    issued_book_name VARCHAR(80),
    issued_date      DATE,
    issued_book_isbn VARCHAR(50),
    issued_emp_id    VARCHAR(10),
    FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
    FOREIGN KEY (issued_emp_id)    REFERENCES employees(emp_id),
    FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn)
);

-- Book return records
CREATE TABLE return_status (
    return_id        VARCHAR(10) PRIMARY KEY,
    issued_id        VARCHAR(30),
    return_book_name VARCHAR(80),
    return_date      DATE,
    return_book_isbn VARCHAR(50),
    FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);
```

---

## ❯ Phase 1 — CRUD Operations (Tasks 1–5)

---

**Task 1 · Insert a new book record**

```sql
INSERT INTO books (isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic',
        6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
```

---

**Task 2 · Update a member's address**

```sql
UPDATE members
SET    member_address = '125 Oak St'
WHERE  member_id = 'C103';
```

---

**Task 3 · Delete a record from issued status**

```sql
DELETE FROM issued_status
WHERE issued_id = 'IS121';
```

---

**Task 4 · Retrieve all books issued by a specific employee**

```sql
SELECT *
FROM issued_status
WHERE issued_emp_id = 'E101';
```

---

**Task 5 · Members who issued more than one book**

```sql
SELECT
    issued_emp_id,
    COUNT(*) AS books_issued
FROM issued_status
GROUP BY 1
HAVING COUNT(*) > 1;
```

---

## ❯ Phase 2 — CTAS Derived Tables (Tasks 6, 11, 15, 16)

> **CTAS (Create Table As Select)** materializes query results into a new table — useful for performance optimization and pre-computed summaries.

---

**Task 6 · Book issue count summary table**

```sql
CREATE TABLE book_issued_cnt AS
SELECT
    b.isbn,
    b.book_title,
    COUNT(ist.issued_id) AS issue_count
FROM issued_status AS ist
JOIN books AS b ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;
```

---

**Task 11 · Premium books table (rental > $7.00)**

```sql
CREATE TABLE expensive_books AS
SELECT *
FROM books
WHERE rental_price > 7.00;
```

---

**Task 15 · Branch performance report table**

```sql
CREATE TABLE branch_reports AS
SELECT
    b.branch_id,
    b.manager_id,
    COUNT(ist.issued_id)  AS books_issued,
    COUNT(rs.return_id)   AS books_returned,
    SUM(bk.rental_price)  AS total_revenue
FROM issued_status AS ist
JOIN employees    AS e  ON e.emp_id      = ist.issued_emp_id
JOIN branch       AS b  ON e.branch_id   = b.branch_id
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
JOIN books        AS bk ON ist.issued_book_isbn = bk.isbn
GROUP BY 1, 2;
```

---

**Task 16 · Active members table (issued in last 2 months)**

```sql
CREATE TABLE active_members AS
SELECT *
FROM members
WHERE member_id IN (
    SELECT DISTINCT issued_member_id
    FROM issued_status
    WHERE issued_date >= CURRENT_DATE - INTERVAL '2 months'
);
```

---

## ❯ Phase 3 — Analytical Queries (Tasks 7–12, 17)

---

**Task 7 · All books in a specific category**

```sql
SELECT *
FROM books
WHERE category = 'Classic';
```

---

**Task 8 · Total rental income by category**

```sql
SELECT
    b.category,
    SUM(b.rental_price) AS total_revenue,
    COUNT(*)            AS total_issues
FROM issued_status AS ist
JOIN books AS b ON b.isbn = ist.issued_book_isbn
GROUP BY 1
ORDER BY 2 DESC;
```

---

**Task 9 · Members registered in the last 180 days**

```sql
SELECT *
FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';
```

---

**Task 10 · Employees with their branch manager's name**

```sql
SELECT
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.branch_id,
    b.branch_address,
    e2.emp_name AS manager_name
FROM employees AS e1
JOIN branch     AS b  ON e1.branch_id = b.branch_id
JOIN employees  AS e2 ON e2.emp_id    = b.manager_id;
```

> Self-join on `employees` — `e1` is the staff member, `e2` is the manager referenced in `branch.manager_id`.

---

**Task 12 · Books not yet returned**

```sql
SELECT ist.*
FROM issued_status AS ist
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;
```

> `LEFT JOIN` keeps all issued records. `WHERE rs.return_id IS NULL` isolates those with no matching return entry.

---

**Task 17 · Top 3 employees by books processed**

```sql
SELECT
    e.emp_name,
    b.branch_id,
    b.branch_address,
    COUNT(ist.issued_id) AS books_processed
FROM issued_status AS ist
JOIN employees AS e ON e.emp_id    = ist.issued_emp_id
JOIN branch    AS b ON e.branch_id = b.branch_id
GROUP BY 1, 2, 3
ORDER BY books_processed DESC
LIMIT 3;
```

---

## ❯ Phase 4 — Advanced SQL (Tasks 13–14, 18)

---

**Task 13 · Overdue books detection (30-day threshold)**

```sql
SELECT
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    ist.issued_date,
    CURRENT_DATE - ist.issued_date AS overdue_days
FROM issued_status AS ist
JOIN members        AS m  ON m.member_id  = ist.issued_member_id
JOIN books          AS bk ON bk.isbn      = ist.issued_book_isbn
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
  AND (CURRENT_DATE - ist.issued_date) > 30
ORDER BY overdue_days DESC;
```

> Four-table join combining member details, book info, and return status.
> `LEFT JOIN` on returns ensures unreturned books are included.
> `(CURRENT_DATE - ist.issued_date) > 30` calculates live overdue days.

---

**Task 14 · Stored Procedure — Book Return Handler**

Automates the return process: logs the return, updates book availability to `'yes'`, and notifies with the book name.

```sql
CREATE OR REPLACE PROCEDURE add_return_records(
    p_return_id    VARCHAR(10),
    p_issued_id    VARCHAR(10),
    p_book_quality VARCHAR(10)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_isbn      VARCHAR(50);
    v_book_name VARCHAR(80);
BEGIN
    -- Log the return
    INSERT INTO return_status (return_id, issued_id, return_date, book_quality)
    VALUES (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    -- Fetch book details from the issued record
    SELECT issued_book_isbn, issued_book_name
    INTO   v_isbn, v_book_name
    FROM   issued_status
    WHERE  issued_id = p_issued_id;

    -- Mark book as available again
    UPDATE books
    SET    status = 'yes'
    WHERE  isbn = v_isbn;

    RAISE NOTICE 'Thank you for returning: %', v_book_name;
END;
$$;

-- Test calls
CALL add_return_records('RS138', 'IS135', 'Good');
CALL add_return_records('RS148', 'IS140', 'Good');
```

---

**Task 18 · Stored Procedure — Book Issuance with Availability Check**

Checks availability before issuing. If available → issues and marks `'no'`. If unavailable → raises an informative notice.

```sql
CREATE OR REPLACE PROCEDURE issue_book(
    p_issued_id         VARCHAR(10),
    p_issued_member_id  VARCHAR(30),
    p_issued_book_isbn  VARCHAR(30),
    p_issued_emp_id     VARCHAR(10)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(10);
BEGIN
    -- Check current availability
    SELECT status INTO v_status
    FROM   books
    WHERE  isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN
        -- Issue the book
        INSERT INTO issued_status (
            issued_id, issued_member_id, issued_date,
            issued_book_isbn, issued_emp_id
        )
        VALUES (
            p_issued_id, p_issued_member_id, CURRENT_DATE,
            p_issued_book_isbn, p_issued_emp_id
        );

        -- Mark book as unavailable
        UPDATE books
        SET    status = 'no'
        WHERE  isbn = p_issued_book_isbn;

        RAISE NOTICE 'Book issued successfully — ISBN: %', p_issued_book_isbn;
    ELSE
        RAISE NOTICE 'Book unavailable — ISBN: %', p_issued_book_isbn;
    END IF;
END;
$$;

-- Test calls
CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');  -- available
CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');  -- unavailable
```

---

## ❯ Project Structure

```
Library-Management-System-SQL/
│
├── schema/
│   └── database_setup.sql        ← All CREATE TABLE statements
│
├── crud/
│   └── crud_operations.sql       ← Tasks 1–5
│
├── ctas/
│   └── derived_tables.sql        ← Tasks 6, 11, 15, 16
│
├── analysis/
│   └── analytical_queries.sql    ← Tasks 7–12, 17
│
├── advanced/
│   ├── overdue_detection.sql     ← Task 13
│   ├── return_procedure.sql      ← Task 14
│   └── issue_procedure.sql       ← Task 18
│
└── README.md
```

---

## ❯ Skills Demonstrated

```txt
✅  Relational database design — 6 tables with FK constraints
✅  Full CRUD operations — INSERT, SELECT, UPDATE, DELETE
✅  CTAS — materializing query results into reusable tables
✅  Multi-table JOINs — up to 4 tables in a single query
✅  Self-join — employees queried as both staff and managers
✅  Date arithmetic — overdue detection with CURRENT_DATE
✅  PL/pgSQL stored procedures — conditional logic with IF/ELSE
✅  RAISE NOTICE — runtime feedback inside procedures
✅  LEFT JOIN NULL pattern — identifying unreturned books
✅  Aggregations with HAVING — GROUP BY post-filtering
```

---

**Pournima Kamble** — MS Computer Science @ Cleveland State University (2026)
Seeking Data Analyst & Data Engineer roles · Available June 2026

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=flat-square&logo=linkedin&logoColor=white)](https://linkedin.com/in/pournimakamble)
[![GitHub](https://img.shields.io/badge/GitHub-pournima2413-333333?style=flat-square&logo=github&logoColor=white)](https://github.com/pournima2413)
[![Email](https://img.shields.io/badge/Email-pournima2413@gmail.com-EA4335?style=flat-square&logo=gmail&logoColor=white)](mailto:pournima2413@gmail.com)
