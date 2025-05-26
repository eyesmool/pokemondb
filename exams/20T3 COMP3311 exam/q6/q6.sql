-- COMP3311 20T3 Final Exam Q6
-- Put any helper views or PLpgSQL functions here
-- You can leave it empty, but you must submit it

create or replace function groupName(gid integer) returns text
as $$
declare
  res text;
begin
  select g.name
  into res
  from groups g
  where g.id = gid;
  return res;
end;
$$ language plpgsql
;


drop type if exists discoinfo cascade;
create type discoinfo as (
  group_id integer,
  group_name text,
  album_id integer,
  album_title text,
  album_year integer,
  album_genre text,
  song_id integer,
  song_trackNo integer,
  song_title text,
  song_length integer
);
create or replace function discography(gid integer) returns setof discoinfo
as $$
declare
  tup record;
  info discoinfo;
begin
  for tup in
    select
      g.id,
      g.name,
      a.id,
      a.title,
      a.year,
      a.genre,
      s.id,
      s.trackNo,
      s.title,
      s.length
    from groups g
    join albums a on (a.made_by = g.id)
    join songs s on (s.on_album = a.id)
    where g.id = gid
    order by a.year, a.title, s.trackNo
  loop
    return next tup;
  end loop;
end;
$$ language plpgsql;