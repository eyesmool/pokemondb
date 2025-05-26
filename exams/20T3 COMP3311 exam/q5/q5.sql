-- COMP3311 20T3 Final Exam
-- Q5: find genres that groups worked in

-- ... helper views and/or functions go here ...

drop view if exists groupGenreViews cascade;
drop view if exists groupGenreAgg cascade;

create or replace view groupGenreViews
as
select distinct
    g.name,
    g.id,
    a.genre
from
    groups g
    join albums a on (a.made_by = g.id)
order by g.name, a.genre
;

create or replace view groupGenreAgg
as
select 
    ggv.name,
    ggv.id,
    string_agg(ggv.genre,',') as genres
from groupGenreViews ggv
group by ggv.name, ggv.id
order by ggv.name
;

create or replace function 
    groupGenreAgg(gid integer) returns text
as $$
declare 
    res text := '';
begin
    select
        gga.genres
    into res
    from
        groupGenreAgg gga
    where gga.id = gid;
    return res;
end;
$$ language plpgsql;



drop function if exists q5();
drop type if exists GroupGenres;

create type GroupGenres as ("group" text, genres text);

create or replace function
    q5() returns setof GroupGenres
as $$
declare
    tup record;
    info GroupGenres;
begin
    for tup in
        select
            g.name,
            g.id
        from
            groups g
        order by g.name asc
    loop
        info.group = tup.name;
        info.genres = groupGenreAgg(tup.id);
        return next info;
    end loop;
end;
$$ language plpgsql
;

