drop view if exists finalCheckpoints;
drop view if exists runnerFinalCheckPt;
drop function if exists finalCheckPt cascade;
drop function if exists q3 cascade;
drop function if exists findcheckptlocation(integer,integer) cascade;

create or replace function 
  isEvent(_eventID integer)  returns boolean
as $$
begin
if exists (
  
  select e.id
  from events e
  where e.id = _eventID
  limit 1
) then
  return true;
end if;
return false;
end;
$$ language plpgsql;

create or replace view finalCheckpoints(event_id, route_id, final_checkpt) as
  select 
    e.id as event_id,
    r.id as route_id,
    max(c.ordering) as final_checkpt
  from 
    events e
    join routes r on (e.route_id = r.id)
    join checkpoints c on (r.id = c.route_id)
  group by event_id, r.id
  order by event_id, final_checkpt;

create or replace function
  finalCheckPt(_eventID integer) returns integer
as $$
declare
  checkpt integer;
begin
  select f.final_checkpt from finalCheckpoints f
  into checkpt
  where _eventID = f.event_id;
  return checkpt;
end;
$$ language plpgsql;



create or replace view runnerFinalCheckPt(event_id, route_id, ordering, name) as
select 
  p.event_id as event_id,
  c.route_id as route_id,
  max(c.ordering) as ordering,
  pe.name as person_name
from participants p 
join reaches r on (p.id = r.partic_id)
join checkpoints c on (r.chkpt_id = c.id)
join people pe on (p.person_id = pe.id)
group by event_id, route_id, person_name
order by event_id, name, ordering;

create or replace function
  runnerFinalCheckPt(_eventId integer)
  returns table (
    event_id integer,
    route_id integer,
    ordering integer,
    person_name text
  )
as $$
begin
  return query
    select
    p.event_id as event_id,
    c.route_id as route_id,
    max(c.ordering) as ordering,
    pe.name as person_name
  from participants p
  join reaches r on (p.id = r.partic_id)
  join checkpoints c on (r.chkpt_id = c.id)
  join people pe on (p.person_id = pe.id)
  where p.event_id = _eventId
  group by p.event_id, c.route_id, pe.name
  order by event_id, name, ordering;
end;
$$ language plpgsql;

create or replace function 
  findCheckPtLocation(_route_id integer, _ordering integer) returns text
as $$
declare
  place text;
begin
  select 
    c.location
  from 
    checkpoints c 
    join routes r on (r.id = c.route_id)
  into place
  where _route_id = r.id and _ordering = c.ordering;
  return place;
end
$$ language plpgsql;

create or replace function 
  q3(_eventID integer) returns setof text
as $$
declare
  tup record;
  skip_msg text;
  count integer := 0;
begin
  if not isEvent(_eventID) then
    skip_msg := 'No such event';
    return next skip_msg;
    return;
    
  end if;
  for tup in select event_id, route_id, ordering, person_name
    from runnerFinalCheckPt(_eventID)
  loop
    if tup.ordering <> finalCheckPt(_eventID) then
      skip_msg := tup.person_name || ' gave up at ' || findCheckPtLocation(tup.route_id, tup.ordering);
      count := count + 1;
      return next skip_msg;
    end if;
  end loop;
  if (count = 0) then
      skip_msg := 'Nobody gave up';
      return next skip_msg;
      return;
  end if;
end;
$$ language plpgsql;

