-- COMP3311 22T3 Final Exam Q5
-- Helper views and functions to support q5
-- You must submit this, even if you don't change it

drop type if exists race_course_date_info cascade;
create type race_course_date_info as (
  race_course text, 
  race_date date, 
  meeting_id integer,
  race_name text,
  prize integer,
  race_length integer,
  position integer,
  horse_name text,
  jockey_name text,
  winnings integer
);
create or replace function raceCourseDate(_raceCourse text, _date date)
  returns setof race_course_date_info
as $$
declare
  tup race_course_date_info;
begin
  for tup in
    select
      rc.name,
      m.run_on,
      m.id,
      r.name,
      r.prize,
      r.length,
      ru.finished as finished_pos,
      h.name, 
      j.name
    from racecourses rc
    join meetings m on (m.run_at = rc.id)
    join races r on (r.part_of = m.id)
    join runners ru on (ru.race = r.id)
    join horses h on (ru.horse = h.id)
    join jockeys j on (ru.jockey = j.id)
    where rc.name LIKE _raceCourse and _date = m.run_on and ru.finished <= 3
  loop
    if tup.position = 1 then
      tup.winnings = tup.prize * 0.7;
    elsif tup.position = 2 then
      tup.winnings = tup.prize * 0.2;
    else
      tup.winnings = tup.prize * 0.1;
    end if;
    return next tup;
  end loop;
end;
$$ language plpgsql