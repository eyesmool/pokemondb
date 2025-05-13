drop view if exists finalOrdering cascade;
drop view if exists eventTimes cascade;
drop view if exists quickestFinishTimes;

create or replace view finalOrdering(route_id, ordering) as
select 
  c.route_id,
  max(c.ordering)
from checkpoints c
group by c.route_id;

create or replace view eventTimes(event_id, person, time, checkpoint) as
select 
  e.id as event_id,
  p.name,
  max(r.at_time) as time,
  max(c.ordering) as checkpoint
from 
  participants pa 
  join events e on (pa.event_id = e.id)
  join reaches r on (pa.id = r.partic_id)
  join checkpoints c on (r.chkpt_id = c.id)
  join people p on (p.id = pa.person_id)
group by e.id, p.name
order by event_id;

create or replace view quickestFinishTimes(event_id, time, checkpoint) as
select 
  eT.event_id as event_id,
  min(eT.time) as time,
  eT.checkpoint as checkpoint
from eventTimes eT
join events e on (eT.event_id = e.id)
join finalOrdering f on (f.route_id = e.route_id)
where f.ordering = eT.checkpoint
group by event_id, checkpoint;

create or replace view q2(event, date, person, time) as 
select 
  e.name as event,
  e.held_on as date,
  eT.person as person,
  q.time as time
from quickestFinishTimes q 
join events e on (q.event_id = e.id)
join eventTimes eT on (q.event_id = eT.event_id)
where eT.checkpoint = q.checkpoint and  eT.time = q.time
order by date, person;
