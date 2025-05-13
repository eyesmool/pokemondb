-- COMP3311 22T3 Final Exam Q3
-- List Gender/Age for all horses for all races of a specified type

drop type if exists race_horses cascade;
create type race_horses as (race text, horses text);

-- put helper views (if any) here
create or replace function races(race_name text) 
returns table (
  races text
)
as
$$
  select r.name
  from races r
  where r.name LIKE '%' || race_name;
$$
language sql;

create or replace function horsesin(race_name text)
returns table (
  race_name text,
  horses text
)
as
$$
  select 
    r.name as race_name,
    h.gender || h.age as horses
  from races r
  join runners ru on (ru.race = r.id)
  join horses h on (h.id = ru.horse)
  where r.name LIKE '%' || race_name
  order by h.gender, h.age;
$$ language sql;

-- answer: Q3(text) -> setof race_horses

create or replace function Q3(_race text) returns setof race_horses
as
$$
select 
  h.race_name,
  string_agg(h.horses::text,',' order by h.horses asc)
from races(_race) r
join horsesin(_race) h on (r.races = h.race_name)
group by h.race_name
$$
language sql;





