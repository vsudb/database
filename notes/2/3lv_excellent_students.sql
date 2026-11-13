
-- | Выражение | Когда возвращает TRUE | Эквивалент в SQL |
-- | :--- | :--- | :--- |
-- | `x = ANY (subquery)`  | `x` равно хотя бы одному значению  | `x IN (subquery)` |
-- | `x != ALL (subquery)` | `x` не равно ни одному значению    | `x NOT IN (subquery)` |
-- | `x > ANY (subquery)`  | `x` больше хотя бы одного значения | `x > (SELECT MIN(...) ...)` |
-- | `x < ANY (subquery)`  | `x` меньше хотя бы одного значения | `x < (SELECT MAX(...) ...)` |
-- | `x > ALL (subquery)`  | `x` больше каждого значения        | `x > (SELECT MAX(...) ...)` |
-- | `x < ALL (subquery)`  | `x` меньше каждого значения        | `x < (SELECT MIN(...) ...)` |

-- Three-valued logic (3VL) в SQL —
-- это система логических вычислений,
-- которая используется из-за наличия значений NULL (отсутствующих данных).
-- Результатом логического выражения (EXPRESSION) может быть TRUE, FALSE и UNKNOWN

-- в условии WHERE сохраняются только строки,
-- для которых результат условия равен TRUE.
-- Строки с результатом FALSE и UNKNOWN отбрасываются.

-- ### Примеры в SQL
--
-- | Выражение | SELECT | Результат |
-- |---|---|---|
-- | `TRUE OR NULL` | `SELECT TRUE OR NULL;` | TRUE |
-- | `FALSE OR NULL` | `SELECT FALSE OR NULL;` | UNKNOWN |
-- | `TRUE AND NULL` | `SELECT TRUE AND NULL;` | UNKNOWN |
-- | `FALSE AND NULL` | `SELECT FALSE AND NULL;` | FALSE |
-- | `NOT NULL` | `SELECT NOT NULL;` | UNKNOWN |
-- | `NULL = NULL` | `SELECT NULL = NULL;` | UNKNOWN |
-- | `NULL <> 10` | `SELECT NULL <> 10;` | UNKNOWN |

-- Главное правило для запоминания
-- TRUE OR UNKNOWN = TRUE — достаточно одного TRUE.
-- FALSE OR UNKNOWN = UNKNOWN
-- FALSE AND UNKNOWN = FALSE — достаточно одного FALSE.
-- TRUE AND UNKNOWN = UNKNOWN

SELECT *
FROM student
WHERE student_id IN (1, 5, NULL, 25);

SELECT *
FROM student
WHERE student_id = 1
      OR student_id = 5
      OR student_id = NULL
      OR student_id = 25;

--Внутри оператора NOT IN Нельзя использовать NULL
SELECT *
FROM student
WHERE student_id NOT IN (1, 5, NULL, 25);
-- Эквивалентен цепочке из условий
SELECT *
FROM student
WHERE student_id != 1
      AND student_id != 5
      AND student_id !=  NULL
      AND student_id != 25;


--https://postgrespro.ru/docs/postgrespro/current/functions-subquery?lang=ru-en



SELECT student_id --149
FROM exam_marks
GROUP BY student_id
HAVING AVG(mark) = 5;

--157
SELECT student_id, surname, name, stipend, kurs, city, birthday, univ_id
FROM student s
WHERE  NOT EXISTS(SELECT 1 FROM exam_marks e WHERE e.student_id = s.student_id AND mark <> 5) --NULL != 5 unknown
EXCEPT
--149
SELECT student_id, surname, name, stipend, kurs, city, birthday, univ_id
FROM student
WHERE student_id IN (SELECT student_id
							FROM exam_marks
							GROUP BY student_id
							HAVING AVG(mark) = 5);

SELECT student_id, surname, name, stipend, kurs, city, birthday, univ_id
FROM student s
WHERE
	NOT EXISTS(SELECT 1 FROM exam_marks e WHERE e.student_id = s.student_id AND mark <> 5)
                                                                              --NULL != 5  UNKNOWN
                                                                              --UNKNOWN AND TRUE = UNKNOWN
                                                                              --NOT EXISTS(пустое множество) = TRUE
    AND
	   EXISTS(SELECT 1 FROM exam_marks e WHERE e.student_id = s.student_id AND mark IS NOT null);



--156
SELECT student_id, surname, name, stipend, kurs, city, birthday, univ_id
FROM student s
WHERE 5 = ALL(SELECT mark FROM exam_marks e WHERE e.student_id = s.student_id);
      --5 = ALL(Пустое множество) = TRUE


--156
SELECT student_id, surname, name, stipend, kurs, city, birthday, univ_id
FROM student s
WHERE 5 = ALL(SELECT mark FROM exam_marks e WHERE e.student_id = s.student_id)
      --5 = ALL(Пустое множество) = TRUE
EXCEPT
--149
SELECT student_id, surname, name, stipend, kurs, city, birthday, univ_id
FROM student
WHERE student_id IN (SELECT student_id
							FROM exam_marks
							GROUP BY student_id
							HAVING AVG(mark) = 5);







--Трехзначная логика 3 Valued-Logic TRUE, FALSE, NULL
SELECT     5 IN (1,2,3,5)      "5 IN (1,2,3,5)",
       5 NOT IN (1,2,3)        "5 NOT IN (1,2,3)",

           5 IN (1,2,NULL,3,5) "5 IN (1,2,NULL,3,5)",
       5 NOT IN (1,2,NULL,3)   "5 NOT IN (1,2,NULL,3)";

SELECT 5  = ANY (ARRAY [1,2,5])  " = ANY (1,2,5)",
	   5 != ANY (ARRAY [1,2,5])  "!= ANY (1,2,5)",
	   5  > ANY (ARRAY [1,2,5])  " > ANY (1,2,5)",

	   5  = ANY (ARRAY [1,NULL,5])  " = ANY (1,NULL,5)", --TRUE OR NULL = TRUE
	   5 != ANY (ARRAY [1,NULL,5])  "!= ANY (1,NULL,5)",
	   5  > ANY (ARRAY [1,NULL,5])  " > ANY (1,NULL,5)",

	   5  = ANY (ARRAY [1,2,NULL])  " = ANY (1,2,NULL)", --FALSE OR NULL = NULL
	   5 != ANY (ARRAY [5, NULL])   "!= ANY (5,NULL)",
	   5  > ANY (ARRAY [5,NULL])    " > ANY (5,NULL)";


SELECT 5  = ALL (ARRAY [5,5,5])   ,  --TRUE
	   5 >= ALL (ARRAY [1,2,5])   ,  --TRUE
       5 != ALL (ARRAY [1,2,5])   ,  --FALSE
	   5  > ALL (ARRAY [1,2,5])   ,  --FALSE
	   5  = ALL (ARRAY [1,NULL,5]),  --FALSE = FALSE AND NULL AND TRUE
	   5 != ALL (ARRAY [1,NULL,5]),  --FALSE
	   5  > ALL (ARRAY [1,NULL,5]),  --FALSE
	   5 >= ALL (ARRAY [1,NULL,5]);  --NULL  = TRUE AND NULL AND TRUE


SELECT 5  = ALL (ARRAY [5,5,5])      ,  --TRUE
	   5  = ALL (ARRAY [5,5,1])      ,  --FALSE
	   5  = ALL (ARRAY [5,NULL,5])   ,  --NULL
	   5  = ALL (ARRAY [1,NULL,5])   ;  --FALSE



-- ПУСТОЕ МНОЖЕСТВО
-- В SQL и реляционной алгебре работа с пустым множеством (\(\emptyset \))
-- при выполнении подзапросов напрямую опирается на законы алгебры логики.
-- Если подзапрос возвращает пустой набор строк (\(\emptyset \)),
-- поведение операторов (EXISTS, IN, ANY, ALL)
-- строго подчиняется правилам работы с
-- логическими значениями FALSE (0), TRUE (1) и неопределенностью UNKNOWN (NULL).

-- Поведение операторов при пустом результате подзапроса (\(\emptyset \))

--EMPTYSET
SELECT * FROM student LIMIT 0;
SELECT * FROM student WHERE 1 = 0;
SELECT * FROM student WHERE false;

--EXISTS(emptyset) NOT EXISTS(emptyset)
SELECT     EXISTS(SELECT * FROM student WHERE false) "EXISTS(emptyset)",     --FALSE
       NOT EXISTS(SELECT * FROM student WHERE false) "NOT EXISTS(emptyset)"; --TRUE

--IN (emptyset) NOT IN(emptyset)
SELECT     5 IN (SELECT 5 FROM student WHERE false) "IN (emptyset)",     --FALSE
       5 NOT IN (SELECT 5 FROM student WHERE false) "NOT IN(emptyset)",  --TRUE

       -- IN()     эквтвалентен  = ANY();
       5  = ANY (SELECT 5 FROM student WHERE false) " = ANY (emptyset)", --FALSE Соответствует ожиданиям разработчика
	   5 != ANY (SELECT 5 FROM student WHERE false) "!= ANY (emptyset)", --FALSE
	   5  > ANY (SELECT 3 FROM student WHERE false) " > ANY (emptyset)"; --FALSE

--!!! ОПАСНОСТЬ TRAP PitFall 5 = ALL (EMPTY_SET) TRUE Не соответствует ожиданиям разработчика
SELECT  5  = ALL (SELECT 5 FROM student WHERE false) " = ALL (emptyset)", --TRUE !!! ОПАСНОСТЬ TRAP PitFall
        5  > ALL (SELECT 3 FROM student WHERE false) " > ALL (emptyset)", --TRUE !!! ОПАСНОСТЬ TRAP PitFall
        -- NOT IN() эквтвалентен != ALL();
        5 != ALL (SELECT 5 FROM student WHERE false) "!= ALL (emptyset)"; --TRUE Соответствует ожиданиям разработчика

--В математической логике и теории множеств существует понятие пустой истинности (vacuous truth).
-- Утверждение вида "все элементы пустого множества обладают свойством X" считается истинным (TRUE),
-- потому что в пустом множестве нет ни одного контрпримера, который опровергал бы это утверждение.
-- В EMPTY_SET нет не одного X != 5

--Скалярный подзапрос и EMPTY_SET
SELECT  5  =  (SELECT 5 FROM student WHERE false) " =  (emptyset)",
        5  != (SELECT 5 FROM student WHERE false) " !=  (emptyset)",
        5  >  (SELECT 5 FROM student WHERE false) " >  (emptyset)",
        5  <  (SELECT 5 FROM student WHERE false) " >  (emptyset)"; --NULL

SELECT  5  =  (SELECT COUNT(*) FROM student WHERE TRUE OR NULL),
        5  =  (SELECT 5 FROM student WHERE TRUE AND NULL);

--Можно выделить 3 ловушки

--1. Ловушка с NOT IN (NULL)
SELECT *
FROM student
WHERE student_id NOT IN (1, NULL, 5);
-- NULL AND TRUE = NULL
-- NULL AND FALSE = FALSE

--2. Ловушка с ALL и неопределенностью (ALL и NULL)
-- Суть ловушки
-- Оператор ALL проверяет условие для каждого элемента множества.
-- Если в проверяемом наборе данных есть NULL,
-- результат для операторов равенства/сравнения часто неожиданно становится UNKNOWN
-- (что равносильно FALSE в WHERE), либо дает ложноположительный результат.
SELECT 5  = ALL (ARRAY [5,5,5])      ,  --TRUE
	   5  = ALL (ARRAY [5,5,1])      ,  --FALSE
	   5  = ALL (ARRAY [5,NULL,5])   ,  --NULL
	   5  = ALL (ARRAY [1,NULL,5])   ;  --FALSE

--3. Ловушка с ALL и Пустым множеством (EMPTY_SET) — Vacuous Truth
-- Суть ловушки
-- Это самая контринтуитивная ловушка для разработчиков.
-- Когда подзапрос для ALL возвращает пустое множество (0 строк),
-- операторы вроде = ALL или > ALL возвращают TRUE (а не FALSE или UNKNOWN, как интуитивно ожидают многие).

SELECT  5  = ALL (SELECT 5 FROM student WHERE false) " = ALL (emptyset)", --TRUE !!! ОПАСНОСТЬ TRAP PitFall
        5  > ALL (SELECT 3 FROM student WHERE false) " > ALL (emptyset)", --TRUE !!! ОПАСНОСТЬ TRAP PitFall
        -- NOT IN() эквтвалентен != ALL();
        5 != ALL (SELECT 5 FROM student WHERE false) "!= ALL (emptyset)"; --TRUE Соответствует ожиданиям разработчика

--BEST PRACTICE

--1.Никогда не используйте NOT IN с подзапросами:
-- Альтернатива: Всегда используйте NOT EXISTS или LEFT JOIN ... WHERE ... IS NULL.
-- Они корректно обрабатывают NULL на уровне строк и не ломаются.
SELECT *
FROM student s
WHERE NOT EXISTS (
    SELECT 1
    FROM exam_marks e
    WHERE e.student_id = s.student_id AND mark <> 5
);
-- 2.Заменяйте IN на EXISTS или адекватные JOIN:
-- Повышает производительность и читаемость.
-- EXISTS концептуально более безопасен в сложных схемах базы данных и
-- часто эффективнее обрабатывается оптимизатором СУБД (реализуется через операцию Semi-Join).

-- 3. Контролируйте IS NULL при явном перечислении списков:
-- 4. Избегайте оператора ALL (или используйте с осторожностью)








