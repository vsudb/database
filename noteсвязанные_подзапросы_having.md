# SQL: Агрегирование и коррелированные подзапросы в HAVING

## 1. Сумма оценок по датам экзаменов

**Задача:** посчитать сумму оценок по каждой дате экзамена и оставить только дни, когда сдавали больше 10 уникальных студентов.

### Решение

```sql
SELECT exam_date, SUM(mark) AS total_mark
FROM exam_marks
GROUP BY exam_date
HAVING COUNT(DISTINCT student_id) > 10;
```

**Как работает запрос:**

- `GROUP BY exam_date` — группирует записи по датам.
- `SUM(mark)` — вычисляет сумму оценок за каждый день.
- `HAVING COUNT(DISTINCT student_id) > 10` — оставляет даты, в которые сдавали больше 10 уникальных студентов.

### Альтернативный вариант с коррелированным подзапросом

```sql
SELECT a.exam_date, SUM(a.mark) AS total_mark
FROM exam_marks a
GROUP BY a.exam_date
HAVING 10 < (
    SELECT COUNT(DISTINCT b.student_id)
    FROM exam_marks b
    WHERE b.exam_date = a.exam_date
);
```

**Результат:** одинаковый для обоих запросов.

Второй вариант использует корреляцию по `exam_date`: подзапрос обращается к дате текущей группы.

**Что лучше?** В данном случае предпочтительнее первый вариант — `HAVING COUNT(DISTINCT ...)`. Он проще и не требует отдельного подзапроса. Однако коррелированный вариант не обязательно медленнее: фактическую производительность определяет план выполнения СУБД.

---

## 2. Когда использовать коррелированный подзапрос в HAVING?

Коррелированный подзапрос в `HAVING` нужен, когда **агрегат текущей группы сравнивается со значением, зависящим от этой группы**.

### Пример 1. Сравнение с предыдущим курсом

Найти курсы, средняя стипендия которых выше, чем на предыдущем курсе.

```sql
SELECT a.kurs, AVG(a.stipend) AS avg_stipend
FROM student a
GROUP BY a.kurs
HAVING AVG(a.stipend) > (
    SELECT AVG(b.stipend)
    FROM student b
    WHERE b.kurs = a.kurs - 1
);
```

**Почему коррелированный?** Подзапрос использует `a.kurs` из внешнего запроса.

### Пример 2. Сравнение с общим средним

Найти курсы, средняя стипендия которых выше средней стипендии студентов третьего курса.

```sql
SELECT kurs, AVG(stipend) AS avg_stipend
FROM student
GROUP BY kurs
HAVING AVG(stipend) > (
    SELECT AVG(stipend)
    FROM student
    WHERE kurs = 3
);
```

Подзапрос **некоррелированный**: он не зависит от текущей группы.

## 3. Сравнение средних оценок между университетами

### Задача 1. Выше среднего по остальным университетам вместе

Найти университеты, где средняя оценка по предмету выше средней оценки по этому же предмету среди студентов **всех остальных университетов вместе**.

```sql
SELECT sub.subj_name, s.univ_id,
       AVG(em.mark) AS avg_mark
FROM exam_marks em
JOIN student s ON s.student_id = em.student_id
JOIN subject sub ON sub.subj_id = em.subj_id
GROUP BY sub.subj_id, sub.subj_name, s.univ_id
HAVING AVG(em.mark) > (
    SELECT AVG(em2.mark)
    FROM exam_marks em2
    JOIN student s2 ON s2.student_id = em2.student_id
    WHERE em2.subj_id = sub.subj_id
      AND s2.univ_id <> s.univ_id
);
```

**Логика:** средняя оценка своего университета сравнивается с общей средней оценкой студентов остальных университетов.

> Это сравнение с объединённой группой, а не с каждым университетом отдельно.

### Задача 2. Выше среднего каждого другого университета

Найти университеты, где средняя оценка по предмету выше средней оценки **в каждом из остальных университетов** по этому предмету.

```sql
SELECT sub.subj_name, s.univ_id,
       AVG(em.mark) AS avg_mark
FROM exam_marks em
JOIN student s ON s.student_id = em.student_id
JOIN subject sub ON sub.subj_id = em.subj_id
GROUP BY sub.subj_id, sub.subj_name, s.univ_id
HAVING AVG(em.mark) > (
    SELECT MAX(others.univ_avg)
    FROM (
        SELECT s2.univ_id,
               AVG(em2.mark) AS univ_avg
        FROM exam_marks em2
        JOIN student s2 ON s2.student_id = em2.student_id
        WHERE em2.subj_id = sub.subj_id
          AND s2.univ_id <> s.univ_id
        GROUP BY s2.univ_id
    ) AS others
);
```

**Логика:** средняя оценка своего университета должна быть выше максимальной средней оценки среди остальных университетов.

| Задача | С чем сравниваем |
|---|---|
| 1 | С общей средней оценкой студентов остальных университетов |
| 2 | С максимальной средней оценкой отдельного университета |

**Важно:** чтобы быть выше хотя бы одного другого университета, нужно сравнивать со средними отдельных университетов и проверять существование хотя бы одного меньшего значения.

## 4. Проверка существования данных

Найти предметы, по которым есть хотя бы одна оценка `5`.

```sql
SELECT sub.subj_id, sub.subj_name,
       AVG(em.mark) AS avg_mark
FROM subject sub
JOIN exam_marks em ON em.subj_id = sub.subj_id
GROUP BY sub.subj_id, sub.subj_name
HAVING EXISTS (
    SELECT 1
    FROM exam_marks em2
    WHERE em2.subj_id = sub.subj_id
      AND em2.mark = 5
);
```

`HAVING EXISTS` проверяет условие для группы после группировки.

Если требуется лишь отобрать предметы, по которым есть хотя бы одна пятёрка, можно использовать `WHERE EXISTS`:

```sql
SELECT sub.subj_id, sub.subj_name,
       AVG(em.mark) AS avg_mark
FROM subject sub
JOIN exam_marks em ON em.subj_id = sub.subj_id
WHERE EXISTS (
    SELECT 1
    FROM exam_marks em2
    WHERE em2.subj_id = sub.subj_id
      AND em2.mark = 5
)
GROUP BY sub.subj_id, sub.subj_name;
```

**Разница:** в этих двух запросах среднее рассчитывается по одним и тем же оценкам, если условие `EXISTS` проверяет только наличие пятёрки по предмету. Но в общем случае `WHERE` фильтрует строки до группировки, а `HAVING` — группы после группировки.

## 5. Когда лучше выбрать другой способ?

| Ситуация | Предпочтительный вариант |
|---|---|
| Сравнение с константой | Обычный `HAVING` |
| Сравнение с общим средним | Некоррелированный подзапрос |
| Сравнение с предыдущей группой | `LAG()`, если доступна оконная функция |
| Фильтрация строк до группировки | `WHERE` |
| Фильтрация групп после группировки | `HAVING` |
| Проверка существования до группировки | `WHERE EXISTS`, если семантика подходит |
| Подсчёт строк в каждой группе | `HAVING COUNT(...)` |

## Главное правило

**Используй коррелированный подзапрос в `HAVING`, когда условие зависит от текущей группы.** Если задачу можно выразить обычным агрегатным условием, не усложняй запрос без необходимости.

Производительность зависит от СУБД, индексов, объёма данных и плана выполнения. При необходимости сравнивай планы через `EXPLAIN ANALYZE` в PostgreSQL.
