SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM return_status;
SELECT * FROM members;


--  Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 
-- 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes','Harper Lee', 'J.B. Lippincott & Co.');

-- Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '125 Main st'
WHERE member_id = 'C101';

-- Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id = 'IS121';

-- Task 4: Retrieve All Books Issued by a Specific Employee 
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';

-- Task 5: List Members Who Have Issued More Than One Book 
-- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT issued_member_id, 
COUNT(issued_id)  AS book_issued FROM issued_status
GROUP BY 1
HAVING COUNT(*) > 1;

-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

CREATE TABLE book_issued_count AS
SELECT b.isbn, 
	b.book_title,
	COUNT(ist.issued_id) AS no_book_issued
	FROM books AS b
JOIN issued_status AS ist
ON ist.issued_book_isbn = b.isbn
GROUP BY 1, 2;

SELECT * FROM book_issued_count;

--- DATA ANALYSIS AND FINDINGS

-- Task 7. Retrieve All Books in a Specific Category
SELECT * FROM books
WHERE category = 'Classic';

-- Task 8: Find Total Rental Income by Category:

SELECT b.category,
	sum(b.rental_price),
	count(*)
FROM issued_status as ist
JOIN books as b
ON ist.issued_book_isbn = b.isbn
group by 1;

-- Task 9: List Members Who Registered in the Last 180 Days
SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';

INSERT INTO members(member_id, member_name, member_address, reg_date)
VALUES ('C120', 'Sam', '145 Main st', '2025-11-24'),
('C121', 'Jason', '1801 Main st', '2025-9-24');

-- Task 10. List Employees with Their Branch Manager's Name and their branch details

SELECT e.emp_id,
		e.emp_name, 
		b.manager_id,
		b.*,
		em.emp_name as manager
FROM branch as b
JOIN employees as e
ON b.branch_id = e.branch_id
join employees as em
on em.emp_id = b.manager_id
;

-- Task 11. Create a Table Expensive Books  with Rental Price Above a Certain Threshold:
CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price > 7.00;


-- Task 12: Retrieve the List of Books Not Yet Returned
SELECT * FROM issued_status as ist
LEFT JOIN return_status as rst
ON ist.issued_id = rst.issued_id
WHERE rst.return_id is null;


-- Task 13: Identify Members with Overdue Books
-- Write a query to identify members who have overdue books 
-- (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.

SELECT ist.issued_member_id,
	m.member_name,
	b.book_title,
	ist.issued_date,
	(CURRENT_DATE - ist.issued_date) AS overdue
FROM issued_status as ist
JOIN members as m
ON m.member_id = ist.issued_member_id
JOIN books as b
ON b.isbn = ist.issued_book_isbn
LEFT JOIN return_status as rst
ON rst.issued_id = ist.issued_id
WHERE rst.return_date IS NULL AND (CURRENT_DATE - ist.issued_date) > 640
ORDER BY 1;


-- Task 14: Update Book Status on Return
-- Write a query to update the status of books in the books table to "Yes" 
-- when they are returned (based on entries in the return_status table).

CREATE OR REPLACE PROCEDURE add_return_records(p_return_id VARCHAR(10), p_issued_id VARCHAR(10), p_book_quality VARCHAR(15))
LANGUAGE plpgsql
AS $$

DECLARE
	v_isbn VARCHAR(50);
	v_book_name VARCHAR(80);
BEGIN
	-- INSERTING INTO RETURN BASED ON USERS INPUT
	INSERT INTO return_status(return_id, issued_id, return_date, book_quality)
	VALUES
	('p_return_id' , 'p_issued_id' , CURRENT_DATE, 'p_book_quality');

	-- BOOK ISBN
	SELECT issued_book_isbn,
	issued_book_name
	INTO 
	v_isbn,
	v_book_name
	FROM issued_status
	WHERE issued_id = p_issued_id;

	---UPDATE BOOK STATUS
	UPDATE books
	SET status = 'yes'
	WHERE isbn = v_isbn;

	RAISE NOTICE 'Thank You for Returning Book %' , v_book_name;

END;
$$

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM books
WHERE isbn = '978-0-307-58837-1';

CALL add_return_records('RS138', 'IS135', 'Good');

--- Task 15: Branch Performance Report
--- Create a query that generates a performance report for each branch, 
--- showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.

CREATE TABLE branch_reports 
AS
SELECT b.branch_id,
	b.manager_id,
	COUNT(ist.issued_id) as number_of_book_issued,
	COUNT(rs.return_id) as number_of_book_return,
	SUM(bk.rental_price) as total_revenue
	
	FROM issued_status AS ist
		JOIN employees as e
			ON e.emp_id = ist.issued_emp_id
		JOIN branch as b 
			ON e.branch_id = b.branch_id
		JOIN return_status as rs
			ON rs.issued_id = ist.issued_id
		JOIN books as bk
			ON ist.issued_book_isbn = bk.isbn
			GROUP BY 1,2;

SELECT * FROM branch_reports;

/*
Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing 
members who have issued at least one book in the last 2 months.
*/
CREATE TABLE active_members
AS
SELECT * FROM members
WHERE member_id IN (SELECT 
						DISTINCT issued_member_id
						FROM issued_status
						WHERE issued_date >= CURRENT_DATE - INTERVAL '2 month'
						);
CREATE TABLE year_active_members
AS
SELECT * FROM members
WHERE member_id IN (SELECT 
						DISTINCT issued_member_id
						FROM issued_status
						WHERE issued_date >= CURRENT_DATE - INTERVAL '12 month'
						);

SELECT * FROM active_members;


SELECT * FROM year_active_members;

/*
Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch.
*/

SELECT e.emp_name,
		b.*,
		COUNT(ist.issued_id) as Issued_books
FROM issued_status as ist
JOIN
employees as e 
ON e.emp_id = ist.issued_emp_id
JOIN 
branch as b 
ON e.branch_id = b.branch_id
GROUP BY 1,2
ORDER BY issued_books DESC
LIMIT 3;


/*

Task 18: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 

Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 

The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 

The procedure should first check if the book is available (status = 'yes'). 

If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 

If the book is not available (status = 'no'), the procedure should return an error message indicating that 
the book is currently not available.

*/

SELECT * FROM books

SELECT * FROM ISSUED_STATUS


CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(10), p_issued_book_isbn VARCHAR(25), 
p_issued_emp_id VARCHAR(10))
LANGUAGE plpgsql
AS $$

DECLARE           -- All the Variable 
		v_status VARCHAR(15);

BEGIN				-- All the code logic
		-- Check if the book is available
		SELECT status 
			INTO 
				v_status
		FROM books
		WHERE isbn = p_issued_book_isbn;

		IF v_status ='yes' THEN 

		INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
			VALUES
			(p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);


			UPDATE books
			SET status = 'no'
			WHERE isbn = p_issued_book_isbn;

			RAISE NOTICE 'Book record added successfully for book isbn : %', p_issued_book_isbn;

		ELSE
			RAISE NOTICE 'Unfortunataly, Book you have requested is Unavailablr book_isbn: %', p_issued_book_isbn;
			 
		END IF; 			
END;

$$

SELECT * FROM books
WHERE isbn = '978-0-375-41398-8' 


CALL issue_book('IS155','C108', '978-0-553-29698-2', 'E104');

CALL issue_book('IS156','C108', '978-0-375-41398-8', 'E104');








