create or replace view maxAge(age) as
select 
  (e.held_on - p.d_o_b) / 365 as age
from people p 
join Participants pa on (p.id = pa.person_id)
join events e on (e.id = pa.event_id)
order by age desc;

create or replace view q1(person, age, event) as
select 
  p.name,
  (e.held_on - p.d_o_b) / 365 as age,
  (substr(e.held_on::text,1,4) || ' ' || e.name) as event
from people p 
join Participants pa on (p.id = pa.person_id)
join events e on (e.id = pa.event_id)
where ((e.held_on - p.d_o_b) / 365) = (select max(age) from maxAge);