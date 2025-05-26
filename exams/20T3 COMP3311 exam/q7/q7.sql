-- COMP3311 20T3 Final Exam Q7
-- Put any helper views or PLpgSQL functions here
-- You can leave it empty, but you must submit it
drop type if exists albumDeets cascade;
create type albumDeets as (
  albumTitle text,
  albumYear integer,
  albumGenre text
);
create or replace function findAlbum(aid integer) returns albumDeets
as $$
declare
  info albumDeets;
begin
  select a.title, a.year, a.genre
  into info
  from albums a
  where a.id = aid;
  return info;
end
$$ language plpgsql
;

drop function if exists performerInstruments cascade;
drop type if exists instrumentInfo cascade;

create type instrumentInfo as (instruments text, performer_id text);
create or replace function 
  performerInstruments(pid integer, song_id integer) returns text
as $$
declare 
  res text;
begin
  select distinct
    string_agg(po.instrument,',' order by po.instrument asc) as inst_str,
    po.performer
  into res
  from playson po
  where po.performer = pid and po.song = song_id
  group by po.performer;
  return res;
end
$$ language plpgsql
;



drop type if exists albumInfo cascade;

create type albumInfo as (
  album_id integer,
  album_title text,
  song_id integer,
  song_trackNo integer,
  song_title text,
  performer_id integer,
  performer_name text,
  instrument text
);

drop function if exists album(integer) cascade;
create or replace function album(aid integer) returns setof albumInfo
as $$
declare
  tup record;
  info albumInfo;
begin
  for tup in 
    select distinct
      a.id,
      a.title,
      s.id,
      s.trackNo,
      s.title,
      p.id,
      p.name,
      performerInstruments(p.id, s.id)
    from
      albums a
    left join songs s on (s.on_album = a.id)
    left join playson po on (po.song = s.id)
    left join performers p on (p.id = po.performer)
    where a.id = aid
    order by s.trackNo, p.name
  loop
    return next tup;
  end loop;
end;
$$ language plpgsql;

