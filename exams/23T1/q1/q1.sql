-- COMP3311 23T1 Final Exam
-- Q1: suburbs with the most customers

create or replace view q1(suburb, ncust)
as
select
  c.lives_in as suburb,
  count(c.id) as ncust
from customers c
group by c.lives_in
having count(c.id) = (
  select max(count(c2.id))
  from customers c2
  group by c2.lives_in
)
order by ncust desc;
