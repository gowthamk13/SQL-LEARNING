-- Foundational Queries

-- 1. List all student names alphabetically
SELECT name FROM students ORDER BY name ASC;

-- 2. Count students per enrollment date
SELECT enrollment_date, COUNT(*) FROM students GROUP BY enrollment_date;

-- 3. Find students with no email address (should be none if inserts are as designed)
SELECT * FROM students WHERE email IS NULL;

-- 4. Show course titles and their descriptions, if any
SELECT title, description FROM courses;

-- 5. List enrollments occurring on weekends
SELECT * FROM enrollments WHERE strftime('%w', enrolled_on) IN ('0','6');

-- 6. Find which students have the shortest names
SELECT * FROM students WHERE LENGTH(name) = (
  SELECT MIN(LENGTH(name)) FROM students
);

-- 7. Show courses with descriptions containing "SQL"
SELECT * FROM courses WHERE description LIKE '%SQL%';

-- 8. List students not named 'Alice'
SELECT * FROM students WHERE name <> 'Alice';

-- 9. Find which students share an enrollment date
SELECT enrollment_date, GROUP_CONCAT(name)
FROM students
GROUP BY enrollment_date
HAVING COUNT(*) > 1;

-- 10. Select enrollments for students whose name contains 'ar'
SELECT * FROM enrollments
WHERE student_id IN (SELECT id FROM students WHERE name LIKE '%ar%');

-- 11. Get a list of all course IDs in which at least one student is enrolled
SELECT DISTINCT course_id FROM enrollments;

-- 12. Show course titles with their average enrollment date
SELECT c.title, AVG(julianday(e.enrolled_on)) AS avg_enrollment
FROM courses c
LEFT JOIN enrollments e ON c.id = e.course_id
GROUP BY c.title;

-- 13. Find students with the most recent enrollment
SELECT s.name, e.enrolled_on
FROM students s
JOIN enrollments e ON s.id = e.student_id
WHERE e.enrolled_on = (
    SELECT MAX(enrolled_on) FROM enrollments
);

-- 14. Count how many students are enrolled in each course, sorted descending
SELECT c.title, COUNT(e.student_id) AS num_students
FROM courses c
LEFT JOIN enrollments e ON c.id = e.course_id
GROUP BY c.id
ORDER BY num_students DESC;

-- 15. List courses and number of unique student enrollments on September 5, 2023
SELECT c.title, COUNT(DISTINCT e.student_id) AS student_count
FROM courses c
JOIN enrollments e ON c.id = e.course_id
WHERE e.enrolled_on = '2023-09-05'
GROUP BY c.title;

-- 16. Show all students who enrolled in both courses
SELECT s.name
FROM students s
JOIN enrollments e1 ON s.id = e1.student_id AND e1.course_id = 101
JOIN enrollments e2 ON s.id = e2.student_id AND e2.course_id = 102;

-- 17. Get the percentage of students with emails ending in ".com"
SELECT ROUND(
    (SELECT COUNT(*) FROM students WHERE email LIKE '%.com') * 100.0 / COUNT(*), 2
) AS percent_com
FROM students;

-- 18. Find student names that appear more than once
SELECT name, COUNT(*) AS count
FROM students
GROUP BY name
HAVING count > 1;

-- 19. List names of students never enrolled after September 5, 2023
SELECT name
FROM students
WHERE id NOT IN (
    SELECT student_id FROM enrollments WHERE enrolled_on > '2023-09-05'
);

-- 20. Find the average number of enrollments per course
SELECT AVG(cnt) FROM (
    SELECT COUNT(*) AS cnt FROM enrollments GROUP BY course_id
);

-- 21. Show total enrollments for each student, plus their email
SELECT s.name, s.email, COUNT(e.course_id) AS total_enrollments
FROM students s
LEFT JOIN enrollments e ON s.id = e.student_id
GROUP BY s.id;

-- 22. Show students and the day of the week they enrolled
SELECT name, enrollment_date, strftime('%w', enrollment_date) AS weekday
FROM students;

-- 23. Which students enrolled on the same day as 'Bob'?
SELECT s2.name
FROM students s1
JOIN students s2 ON s1.enrollment_date = s2.enrollment_date
WHERE s1.name = 'Bob' AND s2.name <> 'Bob';

-- 24. Get the courses with the highest total number of enrollments
SELECT c.title, COUNT(e.student_id) AS total
FROM courses c
LEFT JOIN enrollments e ON c.id = e.course_id
GROUP BY c.id
ORDER BY total DESC
LIMIT 1;

-- 25. Show all students, with a column indicating whether they are enrolled in 'Intro to SQL'
SELECT s.name,
CASE
    WHEN EXISTS (
        SELECT 1 FROM enrollments e
        JOIN courses c ON e.course_id = c.id
        WHERE e.student_id = s.id AND c.title = 'Intro to SQL'
    ) THEN 'Yes'
    ELSE 'No'
END AS enrolled_intro_sql
FROM students s;

-- Special / Advanced Queries

-- 26. Use a window (analytic) function to rank students by number of courses enrolled
SELECT s.name, COUNT(e.course_id) AS enrollments,
       RANK() OVER (ORDER BY COUNT(e.course_id) DESC) AS enrollment_rank
FROM students s
LEFT JOIN enrollments e ON s.id = e.student_id
GROUP BY s.id;

-- 27. Common Table Expression (CTE) for course popularity
WITH PopularCourses AS (
    SELECT course_id, COUNT(student_id) AS popularity
    FROM enrollments
    GROUP BY course_id
)
SELECT c.title, pc.popularity
FROM courses c
JOIN PopularCourses pc ON c.id = pc.course_id
ORDER BY pc.popularity DESC;

-- 28. Recursive CTE to produce a series of numbers (1 to 5)
WITH RECURSIVE numbers(n) AS (
  SELECT 1
  UNION ALL
  SELECT n+1 FROM numbers WHERE n < 5
)
SELECT * FROM numbers;

-- 29. Simulate a random sample of students (requires SQLite), select 2 random students
SELECT * FROM students ORDER BY RANDOM() LIMIT 2;

-- 30. Get the student who most recently enrolled per course (window function)
SELECT c.title, s.name, e.enrolled_on
FROM courses c
JOIN enrollments e ON c.id = e.course_id
JOIN students s ON e.student_id = s.id
WHERE e.enrolled_on = (
    SELECT MAX(e2.enrolled_on)
    FROM enrollments e2
    WHERE e2.course_id = c.id
);

-- 31. Show courses with total students, plus a "popularity" label (CASE)
SELECT c.title, COUNT(e.student_id) AS total_students,
CASE
  WHEN COUNT(e.student_id) >= 3 THEN 'Hot'
  WHEN COUNT(e.student_id) = 2 THEN 'Warm'
  ELSE 'Cool'
END AS popularity
FROM courses c
LEFT JOIN enrollments e ON c.id = e.course_id
GROUP BY c.id;

-- 32. Use a string function to extract domains from student emails
SELECT email, SUBSTR(email, INSTR(email, '@')+1) AS domain FROM students;

-- 33. Aggregate students into a JSON array (SQLite 3.38+)
SELECT c.title, json_group_array(s.name)
FROM courses c
LEFT JOIN enrollments e ON c.id = e.course_id
LEFT JOIN students s ON e.student_id = s.id
GROUP BY c.id;

-- 34. Find median enrollment date per course (advanced: use subquery)
SELECT c.title, 
       (SELECT enrolled_on
        FROM enrollments e2
        WHERE e2.course_id = c.id
        ORDER BY enrolled_on
        LIMIT 1 OFFSET (
          SELECT COUNT(*)/2 FROM enrollments WHERE course_id = c.id
        )) AS median_enrollment_date
FROM courses c;

-- 35. Use error handling: return students, but if none, state so (using COALESCE/IFNULL)
SELECT IFNULL((SELECT GROUP_CONCAT(name) FROM students), 'No students in database') AS all_students;
