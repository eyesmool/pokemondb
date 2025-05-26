-- COMP3311 20T3 Final Exam
-- Q1: longest album(s)

-- ... helper views (if any) go here ...

create or replace view q1("group",album,year)
as
select 
  q.gname,
  q.title,
  q.year
from
  q1Helper q
where q.sum = (select max(sum) from q1Helper);
;

create or replace view q1Helper(gname, title, year, sum) as
select 
  g.name,
  a.title,
  a.year,
  sum(s.length)
from
  songs s
  join albums a on (s.on_album = a.id)
  join groups g on (a.made_by = g.id)
group by g.name, a.title, a.year
order by sum desc
;




