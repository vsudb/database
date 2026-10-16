# Вложенные подзапросы (Subqueries) в SQL

## 📌 Определение

**Вложенные подзапросы (subqueries)** — это запросы, которые используются внутри других SQL-запросов.
<br> Они позволяют выполнять сложные операции с данными, используя результаты одного запроса в другом.

---

##  Классификация подзапросов

### 1. По месту использования

| Место | Назначение |
|-------|-----------|
| **SELECT** | Возвращают значение для каждой строки |
| **FROM** | Действуют как временная таблица |
| **WHERE / HAVING** | Используются для фильтрации |
| **INSERT / UPDATE / DELETE** | Предоставляют данные для модификации |

### 2. По способу взаимодействия

- **Несвязанные / Некоррелированные** — выполняются независимо от внешнего запроса.
- **Связанные / Коррелированные** — ссылаются на поля внешнего запроса (чаще всего в `WHERE`).

### 3. По количеству возвращаемых значений
---
| Тип подзапроса | Что возвращает | Допустимые операторы и места использования | Пример SQL |
| :--- | :--- | :--- | :--- |
| **Скалярный** | Одно значение <br> (1 строка, 1 колонка) | `=`, `<`, `>`, `!=`, `WHERE`, `SELECT`, `HAVING` | `SELECT AVG(stipend) FROM student` |
| **С множеством значений** | Список значений <br> (N строк, 1 колонка) | `IN`, `ANY`, `ALL`, `EXISTS`, `WHERE` | `SELECT univ_id` <br> `FROM university` <br> `WHERE rating > 200` |
| **Табличный** | Полноценную таблицу <br> (N строк, M колонок) | `FROM`, `JOIN` | `SELECT univ_id, COUNT(student_id)` <br> `FROM student` <br> `GROUP BY univ_id` |

---

## 📏 Глубина вложенности

- Теоретические лимиты высоки (**32–255 уровней**).
- **Практический лимит — 3–5 уровней** для читаемости.
- Любой запрос с глубиной **> 5** можно и нужно переписать.
- **CTE и JOIN** — лучшие друзья против глубокой вложенности.

>  *Если запрос выглядит как матрешка — пора его переписать!*

---

## 💡 Примеры подзапросов

## 🔹 Скалярный подзапрос в WHERE
**Задача:** Найти студентов, получающих стипендию выше средней среди всех студентов.

```sql
SELECT surname, name, stipend
FROM student
WHERE stipend > (
    SELECT AVG(stipend) FROM student
);
```

---

### Задача 1.1: Прочитать план выполнения
Даны два запроса. С помощью `EXPLAIN ANALYZE` определите, какой из них эффективнее и почему.

#### Запрос A (Подзапрос с оператором IN)
```sql
SELECT s.surname, s.name
FROM student s
WHERE s.univ_id IN (SELECT univ_id FROM university WHERE rating > 200);
```

#### Запрос B (Явное соединение JOIN)
```sql
SELECT s.surname, s.name
FROM student s
JOIN university u ON u.univ_id = s.univ_id
WHERE u.rating > 200;
```

#### Что нужно сделать:
Выполнить анализ планов выполнения для обоих вариантов:
```sql
EXPLAIN ANALYZE
SELECT s.surname, s.name
FROM student s
WHERE s.univ_id IN (SELECT univ_id FROM university WHERE rating > 200);

EXPLAIN ANALYZE
SELECT s.surname, s.name
FROM student s
JOIN university u ON u.univ_id = s.univ_id
WHERE u.rating > 200;
```

#### Ожидаемый вывод и анализ:
* **Интерпретация Запроса A:** `IN` с подзапросом в современных СУБД часто оптимизируется и превращается в `SEMI JOIN` или `HASH JOIN`. Это крайне эффективно, если подзапрос возвращает небольшое количество строк.
* **Интерпретация Запроса B:** Явный `JOIN` обычно дает стабильный и предсказуемый план с использованием `HASH JOIN` или `NESTED LOOP`.
* **Резюме:** Если подзапрос возвращает очень много строк, классический `JOIN` часто оказывается предпочтительнее и стабильнее по производительности.

---

## 🔹 Связанный скалярный подзапрос в SELECT
**Задача:** Вывести фамилию, имя студента и количество студентов, обучающихся в его университете.

```sql
SELECT surname, name,
       (SELECT COUNT(*) FROM student s2
        WHERE s1.univ_id = s2.univ_id) AS cnt_students
FROM student s1;
```

#### Альтернатива через JOIN:
```sql
SELECT surname, name, s2.cnt
FROM student s1
INNER JOIN (
    SELECT univ_id, COUNT(student_id) AS cnt
    FROM student
    GROUP BY univ_id
) s2 ON s1.univ_id = s2.univ_id;
```

---

## 🔹 Связанный скалярный подзапрос в WHERE
**Задача:** Найти студентов, получающих стипендию выше средней в их университете.

```sql
SELECT surname, name, stipend
FROM student s1
WHERE stipend > (
    SELECT AVG(stipend) FROM student s2
    WHERE s1.univ_id = s2.univ_id
);
```

#### Альтернатива через JOIN:
```sql
SELECT surname, name, s1.stipend, s2.avg_stipend
FROM student s1
INNER JOIN (
    SELECT univ_id, AVG(stipend) AS avg_stipend
    FROM student
    GROUP BY univ_id
) s2 ON s1.univ_id = s2.univ_id AND s1.stipend > s2.avg_stipend;
```

---

## 🔹 Практическое задание
**Задача:** Найти студентов, получающих стипендию выше средней стипендии в их университете, и показать размер этого превышения.

#### Решение через связанный подзапрос (Correlated Subquery):
```sql
SELECT 
    surname, 
    name, 
    stipend,
    stipend - (
        SELECT AVG(stipend) 
        FROM student s2 
        WHERE s1.univ_id = s2.univ_id
    ) AS stipend_excess
FROM student s1
WHERE stipend > (
    SELECT AVG(stipend) 
    FROM student s2 
    WHERE s1.univ_id = s2.univ_id
);
```

#### Решение через оконные функции (Window Functions) — наиболее эффективный способ:
```sql
SELECT surname, name, stipend, stipend_excess
FROM (
    SELECT 
        surname, 
        name, 
        stipend,
        stipend - AVG(stipend) OVER(PARTITION BY univ_id) AS stipend_excess
    FROM student
) sub
WHERE stipend_excess > 0;
```

---
## Примеры работы агрегирующих и оконных функций в SQL
В этом документе на наглядных примерах показана разница между агрегацией через `GROUP BY` 
<br> и вычислениями с помощью оконных функций `OVER(PARTITION BY)`.

| id | name | univ_id | stipend |
| :--- | :--- | :--- | :--- |
| 1 | Иван | 1 | 4000 |
| 2 | Мария | 1 | 6000 |
| 3 | Петр | 2 | 3000 |
| 4 | Анна | 2 | 3000 |

## 1. Агрегирующая функция (`GROUP BY`)

 Строки «схлопываются» 
```sql
SELECT univ_id, AVG(stipend)
FROM student 
GROUP BY univ_id;
```

### Результат выполнения:
| univ_id | avg_stipend | Комментарий |
| :--- | :--- | :--- |
| 1 | **5000** | Среднее для университета 1: `(4000 + 6000) / 2` |
| 2 | **3000** | Среднее для университета 2: `(3000 + 3000) / 2` |

## 2. Оконная функция (`OVER`)

```sql
SELECT name, univ_id, stipend, 
       AVG(stipend) OVER(PARTITION BY univ_id) AS avg_stipend
FROM student;
```

### Результат выполнения:
| name | univ_id | stipend | avg_stipend |
| :--- | :--- | :--- | :--- |
| Иван | 1 | 4000 | **5000** |
| Мария | 1 | 6000 | **5000** |
| Петр | 2 | 3000 | **3000** |
| Анна | 2 | 3000 | **3000** |

---

## ⚙️ Операторы с подзапросами

| Оператор | Назначение |
|----------|-----------|
| `EXISTS` | Проверка существования связанных строк |
| `NOT EXISTS` | Проверка отсутствия связанных строк |
| `IN` | Проверка принадлежности к набору |
| `NOT IN` | Исключение значений из набора |
| `ANY` | Сравнение с хотя бы одним значением |
| `ALL` | Сравнение со всеми значениями |

---

### 🔸 IN / NOT IN

**Пример:** Найти клиентов, которые делали заказы.

```sql
SELECT customer_name
FROM customers
WHERE customer_id IN (
    SELECT DISTINCT customer_id FROM orders
);
```

---

### 🔸 EXISTS / NOT EXISTS

**Пример 1:** Преподаватели, которые ведут хотя бы один предмет.

```sql
SELECT l.lecturer_id, l.surname, l.name
FROM lecturer l
WHERE EXISTS (
    SELECT 1 FROM subj_lect sl
    WHERE sl.lecturer_id = l.lecturer_id
);
```

**Пример 2:** Студенты, которые не сдали ни одного экзамена.

```sql
SELECT s.student_id, s.surname, s.name
FROM student s
WHERE NOT EXISTS (
    SELECT 1 FROM exam_marks em
    WHERE em.student_id = s.student_id
);
```

---

### 🔸 ALL / ANY / SOME

**Пример:** Найти товары дороже ВСЕХ товаров в категории 2.

```sql
SELECT product_name, price
FROM products
WHERE price > ALL (
    SELECT price FROM products
    WHERE category_id = 2
);
```

---

## ⚠️ Проблемы с NOT IN

### 1. Обработка NULL
`NOT IN` неожиданно возвращает `NULL` (а не `TRUE`/`FALSE`), если в подзапросе есть `NULL`. Это приводит к исключению строк из результата.

```sql
SELECT *
FROM table1
WHERE id NOT IN (SELECT id FROM table2 WHERE ...);
-- Если подзапрос вернёт хотя бы один NULL, весь NOT IN вернёт NULL
```

### 2. Производительность
- `NOT IN` часто менее эффективен, чем альтернативы.
- Подзапрос выполняется для каждой строки внешней таблицы.

### ✅ Когда можно безопасно использовать NOT IN
- Подзапрос **не вернёт NULL**.
- Столбец имеет ограничение **NOT NULL**.
- Для **небольших таблиц** с простыми условиями.

### 🔁 Надёжные альтернативы
- `NOT EXISTS`
- `LEFT JOIN + IS NULL`

---

## 🚀 Оптимизация подзапросов

1. **Коррелированные подзапросы** выполняются для каждой строки внешнего запроса — это может быть **медленно**.
2. Часто подзапросы можно заменить на **JOIN** с лучшей производительностью.
3. В некоторых СУБД подзапросы в `SELECT` **плохо оптимизируются**.

---

## 🧪 Пример оптимизации

**Исходный запрос (подзапрос):**

```sql
SELECT COUNT(DISTINCT STUDENT_ID)
FROM EXAM_MARKS S
WHERE NOT EXISTS (
    SELECT * FROM EXAM_MARKS
    WHERE STUDENT_ID = S.STUDENT_ID AND MARK < 5
);
```

**Оптимизированный вариант (JOIN + GROUP BY):**

```sql
SELECT COUNT(*)
FROM (
    SELECT STUDENT_ID, MIN(MARK)
    FROM EXAM_MARKS
    GROUP BY STUDENT_ID
    HAVING MIN(MARK) = 5
);
```

---

## 📝 Итоговые рекомендации

- Используйте **CTE** и **JOIN** вместо глубокой вложенности.
- Предпочитайте **NOT EXISTS** вместо **NOT IN**.
- Для скалярных подзапросов в `SELECT` проверяйте производительность.
- Старайтесь, чтобы глубина вложенности **не превышала 3–5 уровней**.
