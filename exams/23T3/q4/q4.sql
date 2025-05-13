create or replace function
  personExists(_name text) returns boolean
as $$
begin
  if exists (
    select *
    from people p
    where p.name = _name
    limit 1
  ) then return true;
  end if;
  return false;
end;
$$ language plpgsql;

create or replace function 
  personNameToID(_name text) returns integer
as $$
declare
  _id integer;
begin
    select p.id
    into _id
    from people p 
    where p.name LIKE _name;
    return _id;
end;
$$ language plpgsql;


create or replace function
  finishInfo(_name text)
  returns table (
        event_id integer,
        time_ran integer,
        ordering integer
  )
as $$
begin
  return query
  select 
    pa.event_id as event_id,
    max(r.at_time) as time_ran,
    max(c.ordering) as ordering
  from people p
  join participants pa on (pa.person_id = p.id)
  join reaches r on (pa.id = r.partic_id)
  join checkpoints c on (r.chkpt_id = c.id)
  where p.id = personNameToID(_name) and c.ordering = finalCheckPt(pa.event_id)
  group by pa.event_id;
end;
$$ language plpgsql




