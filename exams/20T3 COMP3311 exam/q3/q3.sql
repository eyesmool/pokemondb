-- COMP3311 20T3 Final Exam
-- Q3:  performer(s) who play many instruments

-- ... helper views (if any) go here ...

drop view if exists distinctInstruments cascade;
drop view if exists nDistinctInstruments cascade;
drop view if exists performerInstruments cascade;



create or replace view distinctInstruments(ninstruments) 
as
select 
  distinct(case 
    when p.instrument LIKE '%guitar%' then 'guitar'
    else p.instrument
  end)
from
  playson p
where instrument not LIKE 'vocals'
group by p.instrument
;

create or replace view nDistinctInstruments(n)
as
select
  count(*)
from
  distinctInstruments d
;

create or replace view performerInstruments 
as
select distinct
  p.id,
  p.name,
  (case
    when po.instrument LIKE '%guitar%' then 'guitar'
    else po.instrument
  end)
from
  performers p
  join playson po on (po.performer = p.id)
where po.instrument not LIKE 'vocals'
;

create or replace view q3Helper 
as
select distinct
  p.id,
  p.name,
  count(p.instrument)
from 
  performerInstruments p
group by p.id, p.name
having count(p.instrument) > (select n from nDistinctInstruments) / 2
order by p.id;

create or replace view q3(performer,ninstruments)
as
select q.name, q.count
from q3Helper q
;





