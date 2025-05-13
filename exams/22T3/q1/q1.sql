-- COMP3311 22T3 Final Exam Q1
-- Horse(s) that have won the most Group 1 races

-- put helper views (if any) here

-- answer: Q1(horse)

create or replace view maxWins as 
select 
  max(q.count)
from q1Helper q;

create or replace view Q1(horse) 
as
select 
  q.name
from q1Helper q
where q.count = (select max from maxWins)
;


create or replace view q1Helper as
select 
  h.name,
  count(ru.finished)
from races r 
join runners ru on (r.id = ru.race)
join horses h on (h.id = ru.horse)
where r.level = 1 and ru.finished = 1
group by h.name
order by count(ru.finished) desc;
