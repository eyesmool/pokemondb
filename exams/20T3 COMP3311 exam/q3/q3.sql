-- COMP3311 20T3 Final Exam
-- Q3:  performer(s) who play many instruments

-- ... helper views (if any) go here ...

-- create or replace view q3(performer,ninstruments)
-- as
-- ...put your SQL here...
-- ;

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







