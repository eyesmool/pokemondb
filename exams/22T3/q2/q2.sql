drop view if exists nmares cascade;
drop view if exists nmares cascade;
-- COMP3311 22T3 Final Exam Q2
-- List of races with only Mares

-- put helper views (if any) here

create or replace view nmares as
select 
  r.name as race_name,
  r.id as race_id,
  rc.name as course,
  m.run_on as run_date,
  count(h.gender) as nmares
from races r
join runners ru on (ru.race = r.id)
join horses h on (ru.horse = h.id)
join meetings m on (r.part_of = m.id)
join racecourses rc on (rc.id = m.run_at)
where h.gender = 'M'
group by r.name, r.id, rc.name, m.run_on;

create or replace view nrunners as
select 
  r.id as race_id,
  count(ru.id) as nrunners
from races r
join runners ru on (ru.race = r.id)
join horses h on (ru.horse = h.id)
join meetings m on (r.part_of = m.id)
join racecourses rc on (rc.id = m.run_at)
group by r.id;

-- answer: Q2(name,course,date)
create or replace view Q2(name,course,date)
as
select 
  nm.race_name,
  nm.course,
  nm.run_date
from nmares nm
join nrunners nr on (nr.race_id = nm.race_id)
where nr.nrunners = nm.nmares
order by nm.race_name, nm.run_date
;


