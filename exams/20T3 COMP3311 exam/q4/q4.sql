-- COMP3311 20T3 Final Exam
-- Q4: list of long and short songs by each group

-- ... helper views and/or functions (if any) go here ...


create or replace function 
	numShortSongs(gid integer) returns integer
as $$
declare
	res integer := 0;
begin
	select count(s.length)
	into res
	from groups g
	join albums a on (a.made_by = g.id)
	join songs s on (s.on_album = a.id)
	where s.length < 180 and g.id = gid;
	return res;
end;
$$ language plpgsql
;

create or replace function 
	numLongSongs(gid integer) returns integer
as $$
declare
	res integer := 0;
begin
	select count(s.length)
	into res
	from groups g
	join albums a on (a.made_by = g.id)
	join songs s on (s.on_album = a.id)
	where s.length > 360 and g.id = gid;
	return res;
end;
$$ language plpgsql
;

drop function if exists q4();
drop type if exists SongCounts;
create type SongCounts as ( "group" text, nshort integer, nlong integer );

create or replace function
	q4() returns setof SongCounts
as $$
declare
	tup record;
begin
	for tup in
		select 
			g.name,
			numShortSongs(g.id),
			numLongSongs(g.id)
		from groups g
		order by g.name
		loop
			return next tup;
		end loop;
end
$$ language plpgsql
;


