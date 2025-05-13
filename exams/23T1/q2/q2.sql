-- COMP3311 23T1 Final Exam
-- Q2: ids of people with same name

-- replace this line with any helper views --

create or replace view q2(name,ids)
as
-- replace this line with your SQL code --
select 
  q.name,
  q.ids
from q2Helper q
;

create or replace view q2Helper(name, ids, count)
as
select 
  c.given || ' ' || c.family as name,
  string_agg(c.id::text, ',' order by c.id) as ids,
  count(c.id) as count
from customers c
group by name
having count(c.id) > 1
;

